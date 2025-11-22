--!strict
-- SoundManager.client.lua - Sistema centralizado de sonidos

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

local SoundManager = {}

-- Cache de sonidos
local soundCache: {[string]: Sound} = {}

-- ?? FunciÃ³n para reproducir sonidos de forma robusta
function SoundManager.Play(soundId: string, volume: number?)
	local vol = volume or 0.5

	-- Crear sonido
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = vol
	sound.Parent = SoundService  -- Mejor que workspace

	-- Reproducir
	local success = pcall(function()
		sound:Play()
	end)

	if not success then
		warn("[Sound] Error reproduciendo:", soundId)
		sound:Destroy()
		return
	end

	-- Auto-destruir cuando termine
	sound.Ended:Connect(function()
		sound:Destroy()
	end)

	-- Fallback: destruir despuÃ©s de 3 segundos
	task.delay(3, function()
		if sound and sound.Parent then
			sound:Destroy()
		end
	end)
end

-- ?? Atajos para sonidos comunes
function SoundManager.Purchase()
	SoundManager.Play("rbxassetid://5217846733", 0.6)
end

function SoundManager.PurchaseFailed()
	SoundManager.Play("rbxassetid://130949175", 0.4)
end

function SoundManager.MaxReached()
	SoundManager.Play("rbxassetid://1839739790", 0.5)
end

return SoundManager

