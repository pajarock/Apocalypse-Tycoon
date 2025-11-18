--!strict
--[[
	CASH & INCOME WIDGET - Apocalypse Tycoon
	════════════════════════════════════════════════════════════════════════

	Widget unificado al centro-superior que muestra:
	💰 Cash actual | ⚡ Income per second

	ESTILO: Grafiti urbano vibrante (matching con BaseHUD y Shop)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Crear ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "CashIncomeWidget"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 10 -- ✅ FIX: Evitar superposición con otros widgets
sg.Parent = player:WaitForChild("PlayerGui")

-- Frame principal (centro-superior)
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(320, 60)
frame.Position = UDim2.new(0.5, -160, 0, 20) -- Centrado horizontalmente
frame.AnchorPoint = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Rotation = -1.5 -- Rotación sutil estilo urbano
frame.Parent = sg

local cornerFrame = Instance.new("UICorner")
cornerFrame.CornerRadius = UDim.new(0, 12)
cornerFrame.Parent = frame

-- Sombra pronunciada
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.Size = UDim2.fromOffset(326, 66)
shadow.Position = UDim2.new(0.5, -163, 0, 23)
shadow.AnchorPoint = Vector2.new(0.5, 0)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.Rotation = -1.5
shadow.ZIndex = 0
shadow.Parent = sg
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)
frame.ZIndex = 1

-- Borde grueso vibrante con gradiente
local stroke = Instance.new("UIStroke")
stroke.Thickness = 4
stroke.Color = Color3.fromRGB(255, 170, 50)
stroke.Transparency = 0
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = frame

local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 170, 50)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
})
strokeGradient.Rotation = 45
strokeGradient.Parent = stroke

-- Label de CASH (izquierda)
local cashLabel = Instance.new("TextLabel")
cashLabel.Name = "CashLabel"
cashLabel.Size = UDim2.new(0.5, -10, 1, -10)
cashLabel.Position = UDim2.fromOffset(5, 5)
cashLabel.BackgroundTransparency = 1
cashLabel.Font = Enum.Font.LuckiestGuy -- ESTILO GRAFITI
cashLabel.TextSize = 28
cashLabel.TextColor3 = Color3.fromRGB(100, 255, 140) -- Verde neón
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Text = "💰 $0"
cashLabel.TextStrokeTransparency = 0.3
cashLabel.TextStrokeColor3 = Color3.fromRGB(0, 50, 0)
cashLabel.ZIndex = 2
cashLabel.Rotation = -1 -- Inclinación grafiti
cashLabel.Parent = frame

-- Label de INCOME (derecha)
local incomeLabel = Instance.new("TextLabel")
incomeLabel.Name = "IncomeLabel"
incomeLabel.Size = UDim2.new(0.5, -10, 1, -10)
incomeLabel.Position = UDim2.new(0.5, 5, 0, 5)
incomeLabel.BackgroundTransparency = 1
incomeLabel.Font = Enum.Font.LuckiestGuy -- ESTILO GRAFITI
incomeLabel.TextSize = 28
incomeLabel.TextColor3 = Color3.fromRGB(255, 200, 80) -- Naranja/dorado
incomeLabel.TextXAlignment = Enum.TextXAlignment.Right
incomeLabel.Text = "⚡ 0/s"
incomeLabel.TextStrokeTransparency = 0.3
incomeLabel.TextStrokeColor3 = Color3.fromRGB(50, 25, 0)
incomeLabel.ZIndex = 2
incomeLabel.Rotation = -1 -- Inclinación grafiti
incomeLabel.Parent = frame

-- Divisor central (opcional, estilo urbano)
local divider = Instance.new("Frame")
divider.Name = "Divider"
divider.Size = UDim2.fromOffset(2, 40)
divider.Position = UDim2.new(0.5, -1, 0.5, -20)
divider.BackgroundColor3 = Color3.fromRGB(255, 170, 50)
divider.BackgroundTransparency = 0.3
divider.BorderSizePixel = 0
divider.Rotation = -1.5
divider.ZIndex = 1
divider.Parent = frame

-- Función para formatear dinero
local function formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

-- Animación de pulso cuando cambia el dinero
local lastCash = 0
local lastIncome = 0

local function pulseAnimation(label: TextLabel)
	local originalSize = label.TextSize

	TweenService:Create(
		label,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextSize = originalSize + 4}
	):Play()

	task.delay(0.15, function()
		TweenService:Create(
			label,
			TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{TextSize = originalSize}
		):Play()
	end)
end

-- Actualizar valores
local function update()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end

	local cashValue = leaderstats:FindFirstChild("Cash")
	local incomeValue = leaderstats:FindFirstChild("IncomePerSec")

	if cashValue then
		local newCash = cashValue.Value
		cashLabel.Text = string.format("💰 %s", formatMoney(newCash))

		-- Pulso si cambió el dinero
		if newCash ~= lastCash then
			pulseAnimation(cashLabel)
			lastCash = newCash
		end
	end

	if incomeValue then
		local newIncome = incomeValue.Value
		incomeLabel.Text = string.format("⚡ %d/s", newIncome)

		-- Pulso si cambió el income
		if newIncome ~= lastIncome then
			pulseAnimation(incomeLabel)
			lastIncome = newIncome
		end
	end
end

-- Animación de entrada
task.wait(0.3)
frame.Position = UDim2.new(0.5, -160, 0, -80) -- Fuera de pantalla arriba
frame:TweenPosition(
	UDim2.new(0.5, -160, 0, 20),
	Enum.EasingDirection.Out,
	Enum.EasingStyle.Bounce,
	0.8,
	true
)

-- Loop de actualización (cada 0.5 segundos para más responsividad)
task.spawn(function()
	while true do
		update()
		task.wait(0.5)
	end
end)

update()

print("[CashIncomeWidget] ✓ Widget unificado inicializado con estilo grafiti")
