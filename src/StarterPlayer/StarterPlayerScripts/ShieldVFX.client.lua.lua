--!strict
-- ShieldVFX.client.lua  (StarterPlayerScripts)
-- Muestra un Highlight en la base según ShieldLevel del jugador

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LOCAL = Players.LocalPlayer

local COLORS = {
	[0] = Color3.fromRGB(80, 80, 80),    -- sin escudo (gris)
	[1] = Color3.fromRGB(50, 180, 255),  -- L1 (azul claro)
	[2] = Color3.fromRGB(60, 220, 120),  -- L2 (verde)
	[3] = Color3.fromRGB(255, 200, 50),  -- L3 (dorado)
}

local function getPlate(): BasePart?
	local bases = workspace:FindFirstChild("Bases")
	if not bases then return nil end
	local plate = bases:FindFirstChild(LOCAL.Name.."_Base")
	if plate and plate:IsA("BasePart") then return plate end
	return nil
end

local highlight: Highlight? = nil

local function applyShieldVFX(level: number)
	local plate = getPlate()
	if not plate then return end

	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Adornee = plate
		highlight.Parent = plate
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	end

	local col = COLORS[level] or COLORS[0]
	highlight.FillColor = col
	highlight.OutlineColor = col

	-- pequeño “pulso” al cambiar
	highlight.FillTransparency = 0.9
	TweenService:Create(highlight, TweenInfo.new(0.25), { FillTransparency = 0.7 }):Play()
end

-- Cuando aparezca el character, asegúrate de crear el efecto
local function onCharacter()
	task.delay(0.2, function()
		applyShieldVFX(LOCAL:GetAttribute("ShieldLevel") or 0)
	end)
end

-- Escucha cambios del atributo ShieldLevel
LOCAL:GetAttributeChangedSignal("ShieldLevel"):Connect(function()
	applyShieldVFX(LOCAL:GetAttribute("ShieldLevel") or 0)
end)

if LOCAL.Character then onCharacter() end
LOCAL.CharacterAdded:Connect(onCharacter)
