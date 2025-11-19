--!strict
-- Effects.client.lua  (StarterPlayerScripts)

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local CashTick = Remotes:WaitForChild("CashTick") :: RemoteEvent

-- Utilidad: crea un popup flotante arriba de la base del jugador
local function makeCashPopup(amount: number)
	local plr = game.Players.LocalPlayer
	local baseFolder = workspace:FindFirstChild("Bases")
	if not baseFolder then return end
	local plate = baseFolder:FindFirstChild(plr.Name.."_Base")
	if not (plate and plate:IsA("BasePart")) then return end

	-- Billboard + texto
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 5, 0)
	bb.AlwaysOnTop = true
	bb.MaxDistance = 200
	bb.Adornee = plate
	bb.Parent = plate

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextStrokeTransparency = 0.2
	label.Text = string.format("+$%s", tostring(amount))
	label.TextColor3 = Color3.fromRGB(60, 255, 120)
	label.Parent = bb

	-- anim: subir, desvanecer
	local startOff = bb.StudsOffset
	local goal = { StudsOffset = startOff + Vector3.new(0, 2.5, 0) }
	local t1 = TweenService:Create(bb, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
	t1:Play()

	task.delay(0.4, function()
		local t2 = TweenService:Create(label, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 })
		t2:Play()
	end)

	game:GetService("Debris"):AddItem(bb, 1.0)
end

CashTick.OnClientEvent:Connect(function(gain: number)
	if typeof(gain) == "number" and gain > 0 then
		makeCashPopup(gain)
	end
end)
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
