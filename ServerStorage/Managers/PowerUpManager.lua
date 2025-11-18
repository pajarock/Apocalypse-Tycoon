--!strict
--[[
	POWER-UP MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema centralizado de power-ups temporales.

	FEATURES:
	✅ Spawn de power-ups físicos en el mundo
	✅ Sistema de colección por Touch
	✅ Aplicación de buffs temporales
	✅ Stacking de power-ups iguales (extiende duración)
	✅ Sincronización con clientes para VFX
	✅ Auto-despawn después de tiempo límite

	USAGE:
		local PowerUpManager = require(game.ServerStorage.Managers.PowerUpManager)

		-- Spawnear power-up
		PowerUpManager:SpawnPowerUp(Vector3.new(0, 10, 0), "ShieldBubble")

		-- O aleatorio basado en source
		PowerUpManager:SpawnRandomPowerUp(position, "MeteorNormal")
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local PowerUpConfig = require(script.Parent.Parent.Config.PowerUpConfig)

local PowerUpManager = {}

-- Estado de power-ups activos por jugador
-- ActiveEffects[userId] = {PowerUpName = {expireTime = tick() + duration, ...}}
PowerUpManager.ActiveEffects = {}

-- Power-ups físicos spawneados en el mundo
-- SpawnedPowerUps[part] = {type = "ShieldBubble", spawnTime = tick()}
PowerUpManager.SpawnedPowerUps = {}

-- Remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpCollected: RemoteEvent = nil
local PowerUpExpired: RemoteEvent = nil

-- Inicializar remotes (auto-crear si no existen)
local function initRemotes()
	PowerUpCollected = RemotesFolder:FindFirstChild("PowerUpCollected") :: RemoteEvent
	if not PowerUpCollected then
		PowerUpCollected = Instance.new("RemoteEvent")
		PowerUpCollected.Name = "PowerUpCollected"
		PowerUpCollected.Parent = RemotesFolder
		warn("[PowerUpManager] RemoteEvent 'PowerUpCollected' creado automáticamente")
	end

	PowerUpExpired = RemotesFolder:FindFirstChild("PowerUpExpired") :: RemoteEvent
	if not PowerUpExpired then
		PowerUpExpired = Instance.new("RemoteEvent")
		PowerUpExpired.Name = "PowerUpExpired"
		PowerUpExpired.Parent = RemotesFolder
		warn("[PowerUpManager] RemoteEvent 'PowerUpExpired' creado automáticamente")
	end
end

--═══════════════════════════════════════════════════════════════════════
-- SPAWN DE POWER-UPS
--═══════════════════════════════════════════════════════════════════════

-- Crear Part física del power-up
local function createPowerUpPart(powerUpType: string, position: Vector3): Part
	local data = PowerUpConfig.PowerUps[powerUpType]
	if not data then
		warn("[PowerUpManager] Power-up inválido:", powerUpType)
		return nil
	end

	-- Crear part principal
	local part = Instance.new("Part")
	part.Name = "PowerUp_" .. powerUpType
	part.Size = data.PartSize
	part.Position = position + Vector3.new(0, 2, 0) -- Spawn un poco arriba
	part.Color = data.Color
	part.Material = Enum.Material.Neon
	part.Shape = data.PartShape == "Ball" and Enum.PartType.Ball or Enum.PartType.Block
	part.Anchored = true
	part.CanCollide = false
	part.Transparency = 0.2

	-- Attributes
	part:SetAttribute("PowerUpType", powerUpType)
	part:SetAttribute("SpawnTime", tick())

	-- Billboard GUI con icono
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(4, 0, 4, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = data.Icon
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = billboard

	-- Particles
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(data.Color)
	particles.Size = NumberSequence.new(0.5)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = PowerUpConfig.Settings.ParticleRate
	particles.Speed = NumberRange.new(1, 3)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = part

	-- Glow effect
	local pointLight = Instance.new("PointLight")
	pointLight.Color = data.Color
	pointLight.Brightness = 2
	pointLight.Range = 15
	pointLight.Parent = part

	return part
end

-- Animaciones del power-up (rotación + hover)
local function animatePowerUp(part: Part)
	-- Rotación continua
	task.spawn(function()
		local rotationSpeed = PowerUpConfig.Settings.RotationSpeed
		while part and part.Parent do
			part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(rotationSpeed * 0.1), 0)
			task.wait(0.1)
		end
	end)

	-- Hover effect (sube y baja)
	task.spawn(function()
		local startPos = part.Position
		local hoverHeight = PowerUpConfig.Settings.HoverHeight
		local hoverSpeed = PowerUpConfig.Settings.HoverSpeed
		local time = 0

		while part and part.Parent do
			time = time + 0.05
			local offset = math.sin(time * hoverSpeed) * hoverHeight
			part.Position = startPos + Vector3.new(0, offset, 0)
			task.wait(0.05)
		end
	end)
end

-- Spawnear power-up en el mundo
function PowerUpManager:SpawnPowerUp(position: Vector3, powerUpType: string?)
	-- Si no se especifica tipo, elegir uno aleatorio
	if not powerUpType then
		local allTypes = PowerUpConfig:GetAllPowerUpNames()
		powerUpType = allTypes[math.random(1, #allTypes)]
	end

	-- Validar tipo
	if not PowerUpConfig:IsValidPowerUp(powerUpType) then
		warn("[PowerUpManager] Tipo inválido:", powerUpType)
		return
	end

	-- Crear part
	local part = createPowerUpPart(powerUpType, position)
	if not part then return end

	part.Parent = workspace:FindFirstChild("PowerUps") or workspace

	-- Registrar
	self.SpawnedPowerUps[part] = {
		type = powerUpType,
		spawnTime = tick()
	}

	-- Animaciones
	animatePowerUp(part)

	-- Setup touch handler
	part.Touched:Connect(function(hit)
		self:OnPartTouched(part, hit)
	end)

	-- Auto-despawn después de tiempo límite
	task.delay(PowerUpConfig.Settings.DespawnTime, function()
		if part and part.Parent then
			-- Fade out
			local tween = TweenService:Create(part, TweenInfo.new(0.5), {Transparency = 1})
			tween:Play()
			tween.Completed:Wait()

			self.SpawnedPowerUps[part] = nil
			part:Destroy()
		end
	end)

	if PowerUpConfig.Settings.ShowDebugMessages then
		print(("[PowerUpManager] Spawneado %s en %s"):format(powerUpType, tostring(position)))
	end
end

-- Spawnear power-up aleatorio basado en source (meteor, boss, etc)
function PowerUpManager:SpawnRandomPowerUp(position: Vector3, source: string)
	local powerUpType = PowerUpConfig:GetRandomPowerUp(source)

	if powerUpType then
		self:SpawnPowerUp(position, powerUpType)
	end
end

--═══════════════════════════════════════════════════════════════════════
-- COLECCIÓN DE POWER-UPS
--═══════════════════════════════════════════════════════════════════════

function PowerUpManager:OnPartTouched(part: Part, hit: BasePart)
	-- Validar que el part todavía existe
	if not part or not part.Parent then return end

	-- Validar que el hit es de un jugador
	local character = hit.Parent
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Obtener tipo de power-up
	local powerUpType = part:GetAttribute("PowerUpType")
	if not powerUpType then return end

	-- Prevenir múltiples colecciones
	if not self.SpawnedPowerUps[part] then return end

	-- Colectar
	self:CollectPowerUp(player, powerUpType)

	-- Destruir part con efecto
	self.SpawnedPowerUps[part] = nil

	-- VFX de colección
	local particles = part:FindFirstChildOfClass("ParticleEmitter")
	if particles then
		particles.Rate = 100
		task.wait(0.1)
	end

	part:Destroy()
end

--═══════════════════════════════════════════════════════════════════════
-- APLICACIÓN DE EFECTOS
--═══════════════════════════════════════════════════════════════════════

function PowerUpManager:CollectPowerUp(player: Player, powerUpType: string)
	local userId = player.UserId
	local data = PowerUpConfig.PowerUps[powerUpType]

	if not data then
		warn("[PowerUpManager] Power-up inválido:", powerUpType)
		return
	end

	-- Inicializar tabla si no existe
	if not self.ActiveEffects[userId] then
		self.ActiveEffects[userId] = {}
	end

	local duration = data.Duration

	-- Si ya tiene este power-up activo, extender duración
	if self.ActiveEffects[userId][powerUpType] then
		if data.Stackable then
			local currentExpire = self.ActiveEffects[userId][powerUpType].expireTime
			local newExpire = math.max(currentExpire, tick()) + data.StackBonus
			self.ActiveEffects[userId][powerUpType].expireTime = newExpire

			if PowerUpConfig.Settings.ShowDebugMessages then
				print(("[PowerUpManager] %s stackeó %s (+%ds)"):format(player.Name, powerUpType, data.StackBonus))
			end

			-- Notificar cliente del stack
			if PowerUpCollected then
				PowerUpCollected:FireClient(player, powerUpType, data.StackBonus)
			end
			return
		else
			-- No stackable, ignorar
			return
		end
	end

	-- Aplicar nuevo efecto
	local expireTime = tick() + duration
	self.ActiveEffects[userId][powerUpType] = {
		expireTime = expireTime,
		data = data
	}

	-- Aplicar efectos según tipo
	self:ApplyEffects(player, powerUpType, data)

	-- Notificar cliente
	if PowerUpCollected then
		PowerUpCollected:FireClient(player, powerUpType, duration)
	end

	if PowerUpConfig.Settings.ShowDebugMessages then
		print(("[PowerUpManager] %s colectó %s (%ds)"):format(player.Name, powerUpType, duration))
	end

	-- Setup timer para remover efecto
	task.delay(duration, function()
		self:RemoveEffect(player, powerUpType)
	end)
end

function PowerUpManager:ApplyEffects(player: Player, powerUpType: string, data: any)
	local effects = data.Effects

	-- Shield Bubble
	if effects.Shield then
		player:SetAttribute("ShieldActive", true)
	end

	-- Coin Rain
	if effects.CoinMultiplier then
		player:SetAttribute("CoinMultiplier", effects.CoinMultiplier)
	end

	-- Damage Boost
	if effects.DamageMultiplier then
		player:SetAttribute("DamageMultiplier", effects.DamageMultiplier)
	end

	-- Slow Motion (afecta Config global)
	if effects.SlowMotion then
		player:SetAttribute("SlowMotionActive", true)
		-- La velocidad de meteoritos se modificará en EventManager
	end

	-- Auto-Repair (loop de curación)
	if effects.HealPerSecond then
		local userId = player.UserId
		task.spawn(function()
			while self.ActiveEffects[userId] and self.ActiveEffects[userId][powerUpType] do
				-- Llamar a BaseModule para curar
				local BaseModule = require(game.ServerScriptService.BaseModule)
				BaseModule.Heal(userId, effects.HealPerSecond)

				task.wait(1) -- Cada segundo
			end
		end)
	end
end

function PowerUpManager:RemoveEffect(player: Player, powerUpType: string)
	local userId = player.UserId

	if not self.ActiveEffects[userId] then return end
	if not self.ActiveEffects[userId][powerUpType] then return end

	local data = self.ActiveEffects[userId][powerUpType].data
	local effects = data.Effects

	-- Remover atributos
	if effects.Shield then
		player:SetAttribute("ShieldActive", nil)
	end
	if effects.CoinMultiplier then
		player:SetAttribute("CoinMultiplier", nil)
	end
	if effects.DamageMultiplier then
		player:SetAttribute("DamageMultiplier", nil)
	end
	if effects.SlowMotion then
		player:SetAttribute("SlowMotionActive", nil)
	end

	-- Remover de tabla
	self.ActiveEffects[userId][powerUpType] = nil

	-- Notificar cliente
	if PowerUpExpired then
		PowerUpExpired:FireClient(player, powerUpType)
	end

	if PowerUpConfig.Settings.ShowDebugMessages then
		print(("[PowerUpManager] %s perdió efecto de %s"):format(player.Name, powerUpType))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- GETTERS
--═══════════════════════════════════════════════════════════════════════

function PowerUpManager:GetActiveEffects(player: Player): {[string]: any}
	return self.ActiveEffects[player.UserId] or {}
end

function PowerUpManager:HasEffect(player: Player, powerUpType: string): boolean
	local effects = self:GetActiveEffects(player)
	return effects[powerUpType] ~= nil
end

function PowerUpManager:GetRemainingTime(player: Player, powerUpType: string): number
	local effects = self:GetActiveEffects(player)
	if not effects[powerUpType] then return 0 end

	return math.max(0, effects[powerUpType].expireTime - tick())
end

--═══════════════════════════════════════════════════════════════════════
-- CLEANUP
--═══════════════════════════════════════════════════════════════════════

Players.PlayerRemoving:Connect(function(player)
	-- Limpiar efectos activos
	PowerUpManager.ActiveEffects[player.UserId] = nil
end)

--═══════════════════════════════════════════════════════════════════════
-- INIT
--═══════════════════════════════════════════════════════════════════════

initRemotes()

-- Crear carpeta para power-ups si no existe
if not workspace:FindFirstChild("PowerUps") then
	local folder = Instance.new("Folder")
	folder.Name = "PowerUps"
	folder.Parent = workspace
end

print("[PowerUpManager] ✓ Sistema de power-ups cargado")

return PowerUpManager
