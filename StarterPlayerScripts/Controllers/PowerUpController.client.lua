--!strict
--[[
	POWER-UP CONTROLLER (CLIENT) - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Maneja todos los efectos visuales y de sonido de los power-ups en el cliente.

	FEATURES:
	✅ VFX específicos para cada power-up
	✅ Sound effects
	✅ Screen effects (tints, desaturación)
	✅ Particles siguiendo al player
	✅ Auras y glows

	EVENTOS:
	- PowerUpCollected → Activar VFX
	- PowerUpExpired → Desactivar VFX
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

-- Remotes
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpCollected = RemotesFolder:WaitForChild("PowerUpCollected") :: RemoteEvent
local PowerUpExpired = RemotesFolder:WaitForChild("PowerUpExpired") :: RemoteEvent

local PowerUpController = {}

-- Efectos activos
PowerUpController.ActiveEffects = {}

-- Instances de VFX que necesitan cleanup
PowerUpController.VFXInstances = {}

--═══════════════════════════════════════════════════════════════════════
-- VFX HELPERS
--═══════════════════════════════════════════════════════════════════════

local function createAura(color: Color3, size: number, transparency: number): Part
	local aura = Instance.new("Part")
	aura.Name = "PowerUpAura"
	aura.Size = Vector3.new(size, size, size)
	aura.Shape = Enum.PartType.Ball
	aura.Color = color
	aura.Material = Enum.Material.Neon
	aura.Transparency = transparency
	aura.CanCollide = false
	aura.Anchored = false
	aura.CastShadow = false

	-- Weld al player
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = humanoidRootPart
	weld.Part1 = aura
	weld.Parent = aura

	aura.Parent = character

	return aura
end

local function createParticleEmitter(color: Color3, rate: number): ParticleEmitter
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color)
	particles.Size = NumberSequence.new(0.5)
	particles.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1),
	})
	particles.Lifetime = NumberRange.new(1, 2)
	particles.Rate = rate
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = humanoidRootPart

	return particles
end

local function playSound(soundId: string, volume: number?)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.5
	sound.Parent = humanoidRootPart
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	return sound
end

local function createScreenEffect(color: Color3, transparency: number): ColorCorrectionEffect
	local colorCorrection = Instance.new("ColorCorrectionEffect")
	colorCorrection.TintColor = color
	colorCorrection.Brightness = 0
	colorCorrection.Contrast = 0
	colorCorrection.Saturation = 0
	colorCorrection.Parent = Lighting

	-- Fade in
	TweenService:Create(colorCorrection, TweenInfo.new(0.3), {
		Saturation = -0.3
	}):Play()

	return colorCorrection
end

--═══════════════════════════════════════════════════════════════════════
-- VFX POR TIPO DE POWER-UP
--═══════════════════════════════════════════════════════════════════════

local VFXHandlers = {}

-- 🛡️ Shield Bubble
VFXHandlers.ShieldBubble = {
	Activate = function()
		-- Burbuja azul alrededor del player
		local bubble = createAura(Color3.fromRGB(0, 170, 255), 8, 0.7)

		-- Particles azules
		local particles = createParticleEmitter(Color3.fromRGB(0, 200, 255), 20)

		-- Sound
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6026984224" -- Shield activate
		sound.Volume = 0.3
		sound.Looped = true
		sound.Parent = humanoidRootPart
		sound:Play()

		-- Pulse animation
		local pulseTween = TweenService:Create(bubble, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Size = Vector3.new(9, 9, 9)
		})
		pulseTween:Play()

		return {bubble, particles, sound, pulseTween}
	end,

	Deactivate = function(instances)
		for _, instance in ipairs(instances) do
			if instance:IsA("Tween") then
				instance:Cancel()
			else
				instance:Destroy()
			end
		end
	end
}

-- ⏱️ Slow Motion
VFXHandlers.SlowMotion = {
	Activate = function()
		-- Screen effect morado
		local colorCorrection = createScreenEffect(Color3.fromRGB(150, 50, 200), 0.8)
		colorCorrection.Saturation = -0.5 -- Desaturar

		-- Particles moradas
		local particles = createParticleEmitter(Color3.fromRGB(150, 50, 200), 15)

		-- Sound reverb effect (simulado)
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6026984224"
		sound.Volume = 0.2
		sound.Pitch = 0.7 -- Pitch bajo para efecto slow
		sound.Looped = true
		sound.Parent = humanoidRootPart
		sound:Play()

		return {colorCorrection, particles, sound}
	end,

	Deactivate = function(instances)
		-- Fade out screen effect
		local colorCorrection = instances[1]
		if colorCorrection then
			local tween = TweenService:Create(colorCorrection, TweenInfo.new(0.5), {Saturation = 0})
			tween:Play()
			tween.Completed:Wait()
		end

		for _, instance in ipairs(instances) do
			instance:Destroy()
		end
	end
}

-- 💰 Coin Rain
VFXHandlers.CoinRain = {
	Activate = function()
		-- Particles doradas cayendo
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		particles.Size = NumberSequence.new(0.3)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.3),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Lifetime = NumberRange.new(2, 3)
		particles.Rate = 30
		particles.Speed = NumberRange.new(5, 10)
		particles.Acceleration = Vector3.new(0, -10, 0)
		particles.SpreadAngle = Vector2.new(30, 30)
		particles.Parent = humanoidRootPart

		-- Sound de monedas
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://3470832048" -- Coin sound
		sound.Volume = 0.3
		sound.Looped = true
		sound.Parent = humanoidRootPart
		sound:Play()

		-- Glow dorado sutil
		local aura = createAura(Color3.fromRGB(255, 215, 0), 6, 0.8)

		return {particles, sound, aura}
	end,

	Deactivate = function(instances)
		for _, instance in ipairs(instances) do
			instance:Destroy()
		end
	end
}

-- 🔧 Auto-Repair
VFXHandlers.AutoRepair = {
	Activate = function()
		-- Particles verdes curativas
		local particles = createParticleEmitter(Color3.fromRGB(0, 255, 100), 25)

		-- Sound de reparación
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6026984224"
		sound.Volume = 0.2
		sound.Pitch = 1.2
		sound.Looped = true
		sound.Parent = humanoidRootPart
		sound:Play()

		-- Aura verde
		local aura = createAura(Color3.fromRGB(0, 255, 100), 7, 0.85)

		return {particles, sound, aura}
	end,

	Deactivate = function(instances)
		for _, instance in ipairs(instances) do
			instance:Destroy()
		end
	end
}

-- 💥 Damage Boost
VFXHandlers.DamageBoost = {
	Activate = function()
		-- Aura roja intensa
		local aura = createAura(Color3.fromRGB(255, 50, 50), 7, 0.6)

		-- Particles de fuego
		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxasset://textures/particles/fire_main.dds"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
		particles.Size = NumberSequence.new(1)
		particles.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.4),
			NumberSequenceKeypoint.new(1, 1),
		})
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Rate = 40
		particles.Speed = NumberRange.new(3, 6)
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Parent = humanoidRootPart

		-- Trail de fuego al moverse
		local attachment0 = Instance.new("Attachment", humanoidRootPart)
		local attachment1 = Instance.new("Attachment", humanoidRootPart)
		attachment1.Position = Vector3.new(0, -2, 0)

		local trail = Instance.new("Trail")
		trail.Attachment0 = attachment0
		trail.Attachment1 = attachment1
		trail.Color = ColorSequence.new(Color3.fromRGB(255, 100, 0))
		trail.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.5),
			NumberSequenceKeypoint.new(1, 1),
		})
		trail.Lifetime = 0.5
		trail.Parent = humanoidRootPart

		-- Sound épico
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://9125402735" -- Fire whoosh
		sound.Volume = 0.4
		sound.Looped = true
		sound.Parent = humanoidRootPart
		sound:Play()

		-- Screen tint rojo sutil
		local colorCorrection = Instance.new("ColorCorrectionEffect")
		colorCorrection.TintColor = Color3.fromRGB(255, 200, 200)
		colorCorrection.Parent = Lighting

		return {aura, particles, trail, sound, colorCorrection, attachment0, attachment1}
	end,

	Deactivate = function(instances)
		for _, instance in ipairs(instances) do
			instance:Destroy()
		end
	end
}

--═══════════════════════════════════════════════════════════════════════
-- EVENT HANDLERS
--═══════════════════════════════════════════════════════════════════════

function PowerUpController:OnPowerUpCollected(powerUpType: string, duration: number)
	print(("[PowerUpController] Colectado: %s por %ds"):format(powerUpType, duration))

	-- Si ya existe, limpiar primero (stack)
	if self.ActiveEffects[powerUpType] then
		self:OnPowerUpExpired(powerUpType)
	end

	-- Activar VFX
	local handler = VFXHandlers[powerUpType]
	if handler and handler.Activate then
		local instances = handler.Activate()
		self.VFXInstances[powerUpType] = {
			instances = instances,
			handler = handler
		}
	end

	-- Registrar efecto activo
	self.ActiveEffects[powerUpType] = {
		startTime = tick(),
		duration = duration
	}

	-- Sound de colección
	playSound("rbxassetid://6026984224", 0.5)
end

function PowerUpController:OnPowerUpExpired(powerUpType: string)
	print(("[PowerUpController] Expiró: %s"):format(powerUpType))

	-- Desactivar VFX
	local vfxData = self.VFXInstances[powerUpType]
	if vfxData and vfxData.handler and vfxData.handler.Deactivate then
		vfxData.handler.Deactivate(vfxData.instances)
	end

	self.VFXInstances[powerUpType] = nil
	self.ActiveEffects[powerUpType] = nil

	-- Sound de expiración
	playSound("rbxassetid://6026984224", 0.3)
end

--═══════════════════════════════════════════════════════════════════════
-- CONNECTIONS
--═══════════════════════════════════════════════════════════════════════

PowerUpCollected.OnClientEvent:Connect(function(powerUpType: string, duration: number)
	PowerUpController:OnPowerUpCollected(powerUpType, duration)
end)

PowerUpExpired.OnClientEvent:Connect(function(powerUpType: string)
	PowerUpController:OnPowerUpExpired(powerUpType)
end)

-- Cleanup al morir
character:WaitForChild("Humanoid").Died:Connect(function()
	for powerUpType, _ in pairs(PowerUpController.ActiveEffects) do
		PowerUpController:OnPowerUpExpired(powerUpType)
	end
end)

-- Re-setup al respawnear
player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	-- Limpiar efectos antiguos
	for powerUpType, _ in pairs(PowerUpController.ActiveEffects) do
		PowerUpController:OnPowerUpExpired(powerUpType)
	end
end)

print("[PowerUpController] ✓ Cliente inicializado")

return PowerUpController
