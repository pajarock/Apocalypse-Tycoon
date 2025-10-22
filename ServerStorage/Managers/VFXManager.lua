--!strict
--[[
	VFX MANAGER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema centralizado de efectos visuales con object pooling.

	FEATURES:
	✅ Object pooling automático (máx 50 por tipo)
	✅ Auto-cleanup después de duración del efecto
	✅ Data-driven via VFXConfig
	✅ Performance-optimized (reutiliza parts)
	✅ Drop-in module (sin dependencias)

	USAGE:
		local VFXManager = require(game.ServerStorage.Managers.VFXManager)

		-- Spawnear efecto
		VFXManager:PlayEffect("MeteorExplosion", Vector3.new(0, 10, 0))

		-- Con parent custom
		VFXManager:PlayEffect("DamageHit", base.Position, workspace.Effects)

	API:
		:PlayEffect(effectName: string, position: Vector3, parent: Instance?) → Part?
		:GetPoolStats() → {[string]: {Active: number, Pooled: number}}
		:ClearPool(effectName: string?)

	PERFORMANCE:
	- Usa pooling para evitar instancing lag
	- Auto-retorna efectos al pool después de Duration
	- Máximo 50 instancias por tipo de efecto
	- Cleanup automático de efectos viejos
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-- Import config
local VFXConfig = require(script.Parent.Parent.Config.VFXConfig)

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
--═══════════════════════════════════════════════════════════════════════

local MAX_POOLED_PER_TYPE = 50
local POOL_CLEANUP_INTERVAL = 60 -- Cleanup cada 60s
local DEBUG_MODE = false

--═══════════════════════════════════════════════════════════════════════
-- TYPES
--═══════════════════════════════════════════════════════════════════════

type EffectConfig = {
	Duration: number,
	Particles: {any},
	Sound: {SoundId: string, Volume: number, PlaybackSpeed: number}?,
	Light: {Color: Color3, Brightness: number, Range: number}?
}

type PoolStats = {
	Active: number,
	Pooled: number
}

--═══════════════════════════════════════════════════════════════════════
-- MODULE
--═══════════════════════════════════════════════════════════════════════

local VFXManager = {}
VFXManager.__index = VFXManager

-- Pool storage: {[effectName] = {part1, part2, ...}}
local Pool: {[string]: {Part}} = {}

-- Active effects counter
local ActiveEffects: {[string]: number} = {}

-- Effects folder (lazy-created)
local EffectsFolder: Folder? = nil

--═══════════════════════════════════════════════════════════════════════
-- UTILITIES
--═══════════════════════════════════════════════════════════════════════

local function getEffectsFolder(): Folder
	if not EffectsFolder or not EffectsFolder.Parent then
		EffectsFolder = workspace:FindFirstChild("Effects")
		if not EffectsFolder then
			EffectsFolder = Instance.new("Folder")
			EffectsFolder.Name = "Effects"
			EffectsFolder.Parent = workspace
		end
	end
	return EffectsFolder
end

local function createParticleEmitter(config: any): ParticleEmitter
	local emitter = Instance.new("ParticleEmitter")

	-- Apply all properties from config
	if config.Rate then emitter.Rate = config.Rate end
	if config.EmitCount then
		emitter.Rate = 0 -- Burst mode
	end
	if config.Lifetime then emitter.Lifetime = config.Lifetime end
	if config.Speed then emitter.Speed = config.Speed end
	if config.SpreadAngle then emitter.SpreadAngle = config.SpreadAngle end
	if config.Color then emitter.Color = config.Color end
	if config.Size then emitter.Size = config.Size end
	if config.Transparency then emitter.Transparency = config.Transparency end
	if config.Texture then emitter.Texture = config.Texture end
	if config.LightEmission then emitter.LightEmission = config.LightEmission end
	if config.Acceleration then emitter.Acceleration = config.Acceleration end
	if config.EmissionDirection then emitter.EmissionDirection = config.EmissionDirection end
	if config.RotSpeed then emitter.RotSpeed = config.RotSpeed end
	if config.Rotation then emitter.Rotation = config.Rotation end

	-- Disable initially
	emitter.Enabled = false

	return emitter
end

local function createTrail(config: any, part: Part): Trail?
	-- Trails need attachments
	local att0 = Instance.new("Attachment")
	att0.Name = "TrailAttachment0"
	att0.Parent = part

	local att1 = Instance.new("Attachment")
	att1.Name = "TrailAttachment1"
	att1.Position = Vector3.new(0, 2, 0) -- Offset for trail length
	att1.Parent = part

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1

	if config.Lifetime then trail.Lifetime = config.Lifetime end
	if config.MinLength then trail.MinLength = config.MinLength end
	if config.Color then trail.Color = config.Color end
	if config.Transparency then trail.Transparency = config.Transparency end
	if config.WidthScale then trail.WidthScale = config.WidthScale end

	trail.Enabled = false
	trail.Parent = part

	return trail
end

--═══════════════════════════════════════════════════════════════════════
-- EFFECT CREATION
--═══════════════════════════════════════════════════════════════════════

local function createEffectPart(effectName: string, config: EffectConfig): Part
	local part = Instance.new("Part")
	part.Name = "VFX_" .. effectName
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Anchored = true
	part.CastShadow = false

	-- Create particles
	for _, particleConfig in ipairs(config.Particles) do
		if particleConfig.Type == "ParticleEmitter" then
			local emitter = createParticleEmitter(particleConfig)
			emitter.Parent = part

			-- Store emit count for burst mode
			if particleConfig.EmitCount then
				emitter:SetAttribute("EmitCount", particleConfig.EmitCount)
			end
		elseif particleConfig.Type == "Trail" then
			createTrail(particleConfig, part)
		end
	end

	-- Create sound
	if config.Sound then
		local sound = Instance.new("Sound")
		sound.Name = "EffectSound"
		sound.SoundId = config.Sound.SoundId
		sound.Volume = config.Sound.Volume or 0.5
		sound.PlaybackSpeed = config.Sound.PlaybackSpeed or 1.0
		sound.Parent = part
	end

	-- Create light
	if config.Light then
		local light = Instance.new("PointLight")
		light.Name = "EffectLight"
		light.Color = config.Light.Color
		light.Brightness = config.Light.Brightness
		light.Range = config.Light.Range
		light.Enabled = false
		light.Parent = part
	end

	-- Mark as pooled
	part:SetAttribute("IsPooled", true)
	part:SetAttribute("EffectName", effectName)

	return part
end

--═══════════════════════════════════════════════════════════════════════
-- POOLING SYSTEM
--═══════════════════════════════════════════════════════════════════════

local function getFromPool(effectName: string): Part?
	if not Pool[effectName] then
		Pool[effectName] = {}
		return nil
	end

	-- Find available part
	for i = #Pool[effectName], 1, -1 do
		local part = Pool[effectName][i]
		if part and part.Parent == nil then
			table.remove(Pool[effectName], i)
			return part
		end
	end

	return nil
end

local function returnToPool(effectName: string, part: Part)
	if not part or not part.Parent then return end

	-- Cleanup before returning
	part.Parent = nil
	part.CFrame = CFrame.new(0, -1000, 0) -- Move out of view

	-- Stop all effects
	for _, child in ipairs(part:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			child.Enabled = false
		elseif child:IsA("Trail") then
			child.Enabled = false
		elseif child:IsA("Sound") and child.Playing then
			child:Stop()
		elseif child:IsA("PointLight") then
			child.Enabled = false
		end
	end

	-- Add to pool if not full
	if not Pool[effectName] then
		Pool[effectName] = {}
	end

	if #Pool[effectName] < MAX_POOLED_PER_TYPE then
		table.insert(Pool[effectName], part)

		if DEBUG_MODE then
			print(("[VFXManager] Returned '%s' to pool (size: %d)"):format(effectName, #Pool[effectName]))
		end
	else
		-- Pool full, destroy
		part:Destroy()

		if DEBUG_MODE then
			warn(("[VFXManager] Pool full for '%s', destroying part"):format(effectName))
		end
	end

	-- Update counter
	ActiveEffects[effectName] = math.max(0, (ActiveEffects[effectName] or 0) - 1)
end

--═══════════════════════════════════════════════════════════════════════
-- PUBLIC API
--═══════════════════════════════════════════════════════════════════════

--[[
	Spawnea un efecto visual en una posición.

	@param effectName string - Nombre del efecto (debe existir en VFXConfig)
	@param position Vector3 - Posición 3D donde spawnear el efecto
	@param parent Instance? - Parent custom (default: workspace.Effects)
	@return Part? - El part del efecto, o nil si no se pudo crear
]]
function VFXManager:PlayEffect(effectName: string, position: Vector3, parent: Instance?): Part?
	-- Validate effect exists
	local config: EffectConfig? = VFXConfig[effectName]
	if not config then
		warn(("[VFXManager] Effect '%s' no encontrado en VFXConfig"):format(effectName))
		return nil
	end

	-- Get or create effect part
	local effectPart = getFromPool(effectName)
	if not effectPart then
		effectPart = createEffectPart(effectName, config)

		if DEBUG_MODE then
			print(("[VFXManager] Created new '%s' effect (pool miss)"):format(effectName))
		end
	else
		if DEBUG_MODE then
			print(("[VFXManager] Reused '%s' from pool"):format(effectName))
		end
	end

	-- Position and parent
	effectPart.CFrame = CFrame.new(position)
	effectPart.Parent = parent or getEffectsFolder()

	-- Update counter
	ActiveEffects[effectName] = (ActiveEffects[effectName] or 0) + 1

	-- Activate particles
	for _, child in ipairs(effectPart:GetDescendants()) do
		if child:IsA("ParticleEmitter") then
			local emitCount = child:GetAttribute("EmitCount")
			if emitCount then
				-- Burst mode
				child:Emit(emitCount)
			else
				-- Continuous mode
				child.Enabled = true
			end
		elseif child:IsA("Trail") then
			child.Enabled = true
		end
	end

	-- Play sound
	local sound = effectPart:FindFirstChild("EffectSound")
	if sound and sound:IsA("Sound") then
		sound:Play()
	end

	-- Enable light
	local light = effectPart:FindFirstChild("EffectLight")
	if light and light:IsA("PointLight") then
		light.Enabled = true

		-- Fade out light
		task.spawn(function()
			local duration = config.Duration
			local startBrightness = light.Brightness
			local elapsed = 0

			while elapsed < duration and light and light.Parent do
				task.wait(0.05)
				elapsed += 0.05
				local alpha = 1 - (elapsed / duration)
				light.Brightness = startBrightness * alpha
			end

			if light and light.Parent then
				light.Enabled = false
				light.Brightness = startBrightness -- Reset
			end
		end)
	end

	-- Auto-cleanup and return to pool
	task.delay(config.Duration, function()
		returnToPool(effectName, effectPart)
	end)

	return effectPart
end

--[[
	Obtiene estadísticas del pool de efectos.

	@return {[string]: PoolStats} - Stats por cada tipo de efecto
]]
function VFXManager:GetPoolStats(): {[string]: PoolStats}
	local stats: {[string]: PoolStats} = {}

	for effectName, parts in pairs(Pool) do
		stats[effectName] = {
			Active = ActiveEffects[effectName] or 0,
			Pooled = #parts
		}
	end

	return stats
end

--[[
	Limpia el pool de un efecto específico o todos.

	@param effectName string? - Nombre del efecto (nil = limpiar todo)
]]
function VFXManager:ClearPool(effectName: string?)
	if effectName then
		-- Clear specific effect
		if Pool[effectName] then
			for _, part in ipairs(Pool[effectName]) do
				if part then part:Destroy() end
			end
			Pool[effectName] = {}
			ActiveEffects[effectName] = 0
		end

		if DEBUG_MODE then
			print(("[VFXManager] Cleared pool for '%s'"):format(effectName))
		end
	else
		-- Clear all
		for name, parts in pairs(Pool) do
			for _, part in ipairs(parts) do
				if part then part:Destroy() end
			end
		end
		Pool = {}
		ActiveEffects = {}

		if DEBUG_MODE then
			print("[VFXManager] Cleared all pools")
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- AUTO-CLEANUP
--═══════════════════════════════════════════════════════════════════════

-- Periodic cleanup of destroyed parts in pool
task.spawn(function()
	while true do
		task.wait(POOL_CLEANUP_INTERVAL)

		for effectName, parts in pairs(Pool) do
			for i = #parts, 1, -1 do
				local part = parts[i]
				if not part or not part:IsDescendantOf(game) then
					table.remove(parts, i)
				end
			end
		end

		if DEBUG_MODE then
			local total = 0
			for _, parts in pairs(Pool) do
				total += #parts
			end
			print(("[VFXManager] Cleanup done. Total pooled: %d"):format(total))
		end
	end
end)

--═══════════════════════════════════════════════════════════════════════
-- INITIALIZATION
--═══════════════════════════════════════════════════════════════════════

-- Pre-warm pool with common effects (optional)
task.spawn(function()
	task.wait(5) -- Wait for game to load

	-- Pre-create 5 of each common effect
	local commonEffects = {"MeteorExplosion", "DamageHit", "PurchaseSuccess"}

	for _, effectName in ipairs(commonEffects) do
		local config = VFXConfig[effectName]
		if config then
			for i = 1, 5 do
				local part = createEffectPart(effectName, config)
				if not Pool[effectName] then
					Pool[effectName] = {}
				end
				table.insert(Pool[effectName], part)
			end

			if DEBUG_MODE then
				print(("[VFXManager] Pre-warmed '%s' pool (5 instances)"):format(effectName))
			end
		end
	end
end)

print("[VFXManager] ✓ Módulo cargado con object pooling")

return VFXManager
