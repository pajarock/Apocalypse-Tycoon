--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestBaseState = Remotes:WaitForChild("RequestBaseState")
local BaseStateChanged = Remotes:WaitForChild("BaseStateChanged")

-- Crear UI
local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
sg.Name = "BaseHUD"
sg.ResetOnSpawn = false

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 320, 0, 60)
frame.Position = UDim2.new(1, -340, 1, -120) -- ✅ FIX: Subido de -80 a -120
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
frame.BackgroundTransparency = 0.05
frame.BorderSizePixel = 0
frame.Rotation = -1.5 -- Rotación sutil estilo urbano
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

-- Sombra pronunciada
local shadow = Instance.new("Frame", sg)
shadow.Name = "HPShadow"
shadow.Size = UDim2.new(0, 326, 0, 66)
shadow.Position = UDim2.new(1, -343, 1, -117) -- ✅ FIX: Ajustado para seguir al frame
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.Rotation = -1.5
shadow.ZIndex = 0
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 10)
frame.ZIndex = 1

-- Borde grueso vibrante con gradiente
local stroke = Instance.new("UIStroke", frame)
stroke.Thickness = 4
stroke.Color = Color3.fromRGB(0, 255, 100)
stroke.Transparency = 0
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local strokeGradient = Instance.new("UIGradient", stroke)
strokeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 255))
})
strokeGradient.Rotation = 45

local bar = Instance.new("Frame", frame)
bar.Name = "Bar"
bar.Size = UDim2.new(1, -12, 0, 20)
bar.Position = UDim2.fromOffset(6, 32)
bar.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
bar.BorderSizePixel = 0
bar.ZIndex = 2
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)

-- Gradiente en la barra
local barGradient = Instance.new("UIGradient", bar)
barGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 80))
})
barGradient.Rotation = 90

-- Label "BASE HP" pequeño arriba
local hpTitle = Instance.new("TextLabel", frame)
hpTitle.Size = UDim2.new(0.5, 0, 0, 18)
hpTitle.Position = UDim2.fromOffset(8, 4)
hpTitle.BackgroundTransparency = 1
hpTitle.Font = Enum.Font.GothamBold
hpTitle.TextSize = 14
hpTitle.TextColor3 = Color3.fromRGB(180, 180, 180)
hpTitle.TextXAlignment = Enum.TextXAlignment.Left
hpTitle.Text = "BASE HP"
hpTitle.TextStrokeTransparency = 0.7
hpTitle.ZIndex = 3

-- Label de números en LuckiestGuy (GRANDE)
local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(0.5, 0, 0, 24)
label.Position = UDim2.new(1, -8, 0, 2)
label.AnchorPoint = Vector2.new(1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.LuckiestGuy -- ESTILO GRAFITI
label.TextSize = 26
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextXAlignment = Enum.TextXAlignment.Right
label.Text = "100/100"
label.TextStrokeTransparency = 0.3
label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
label.ZIndex = 3
label.Rotation = -2 -- Inclinación grafiti

local repairBtn = Instance.new("TextButton", sg)
repairBtn.Size = UDim2.new(0, 100, 0, 50)
repairBtn.Position = UDim2.new(1, -360, 1, -185) -- ✅ FIX: Subido de -145 a -185
repairBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
repairBtn.TextColor3 = Color3.new(1, 1, 1)
repairBtn.Font = Enum.Font.LuckiestGuy -- ESTILO GRAFITI
repairBtn.TextSize = 20
repairBtn.TextStrokeTransparency = 0.3
repairBtn.TextStrokeColor3 = Color3.fromRGB(0, 50, 0)
repairBtn.BorderSizePixel = 0
repairBtn.Rotation = -1.5
repairBtn.ZIndex = 1

Instance.new("UICorner", repairBtn).CornerRadius = UDim.new(0, 10)

-- Borde del botón
local repairStroke = Instance.new("UIStroke", repairBtn)
repairStroke.Thickness = 3
repairStroke.Color = Color3.fromRGB(0, 255, 100)
repairStroke.Transparency = 0

-- Sombra del botón
local repairShadow = Instance.new("Frame", sg)
repairShadow.Size = UDim2.new(0, 106, 0, 56)
repairShadow.Position = UDim2.new(1, -363, 1, -182) -- ✅ FIX: Ajustado para seguir al botón
repairShadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
repairShadow.BackgroundTransparency = 0.6
repairShadow.BorderSizePixel = 0
repairShadow.Rotation = -1.5
repairShadow.ZIndex = 0
Instance.new("UICorner", repairShadow).CornerRadius = UDim.new(0, 10)

-- Padding interno
local repairPadding = Instance.new("UIPadding", repairBtn)
repairPadding.PaddingLeft = UDim.new(0, 6)
repairPadding.PaddingRight = UDim.new(0, 6)
repairPadding.PaddingTop = UDim.new(0, 4)
repairPadding.PaddingBottom = UDim.new(0, 4)

-- ✅ Contador de waves sobrevividas ELIMINADO (ahora solo en WaveCounterUI)

local function updateRepairButton()
	local state = RequestBaseState:InvokeServer()
	if not state then return end

	local hp = state.BaseHP
	local max = state.MaxHP
	local missing = max - hp
	local repairAmount = math.min(10, missing)

	-- Calcular costo escalado (igual que en server)
	local plr = game.Players.LocalPlayer
	local leaderstats = plr:FindFirstChild("leaderstats")
	local ips = leaderstats and leaderstats:FindFirstChild("IncomePerSec")
	local incomePerSec = ips and ips.Value or 0

	local baseCost = 50  -- Debe coincidir con Config
	local scaledCost = baseCost * (1 + (incomePerSec / 10))
	local cost = repairAmount * math.floor(scaledCost)

	if missing <= 0 then
		repairBtn.Text = "✓ FULL!"
		repairBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		repairStroke.Color = Color3.fromRGB(150, 150, 150)
	else
		repairBtn.Text = string.format("REPAIR\n$%d", cost)
		repairBtn.BackgroundColor3 = Color3.fromRGB(40, 180, 80)
		repairStroke.Color = Color3.fromRGB(0, 255, 100)
	end
end

repairBtn.MouseButton1Click:Connect(function()
	ReplicatedStorage.Remotes.RequestRepair:FireServer(10)
	task.wait(0.1)
	updateRepairButton()
	update()
end)

-- Tecla R
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.R then
		ReplicatedStorage.Remotes.RequestRepair:FireServer(10)
		task.wait(0.1)
		updateRepairButton()
		update()
	end
end)

-- Llamar updateRepairButton en el loop

-- Tecla R
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.R then
		ReplicatedStorage.Remotes.RequestRepair:FireServer(10)
	end
end)

local function update()
	local state = RequestBaseState:InvokeServer()
	if not state then return end

	local hp = state.BaseHP
	local max = state.MaxHP
	local pct = hp/max

	bar:TweenSize(UDim2.new(pct, -10, 1, -10), "Out", "Quad", 0.3, true)

	-- Colores vibrantes según HP
	local color1, color2, strokeColor
	if pct > 0.7 then
		color1 = Color3.fromRGB(0, 255, 100)
		color2 = Color3.fromRGB(0, 200, 80)
		strokeColor = Color3.fromRGB(0, 255, 100)
	elseif pct > 0.3 then
		color1 = Color3.fromRGB(255, 200, 0)
		color2 = Color3.fromRGB(255, 150, 0)
		strokeColor = Color3.fromRGB(255, 200, 0)
	else
		color1 = Color3.fromRGB(255, 50, 50)
		color2 = Color3.fromRGB(200, 0, 0)
		strokeColor = Color3.fromRGB(255, 50, 50)
	end

	bar.BackgroundColor3 = color1
	barGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color1),
		ColorSequenceKeypoint.new(1, color2)
	})

	-- Animar cambio de color del borde
	TweenService:Create(stroke, TweenInfo.new(0.3), {
		Color = strokeColor
	}):Play()

	strokeGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, strokeColor),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(
			math.clamp(strokeColor.R * 255 * 0.8, 0, 255),
			math.clamp(strokeColor.G * 255 * 0.8, 0, 255),
			math.clamp(strokeColor.B * 255 + 50, 0, 255)
		))
	})

	label.Text = string.format("%d/%d", hp, max)
end

BaseStateChanged.OnClientEvent:Connect(update)

task.spawn(function()
	while true do
		update()
		task.wait(2)
	end
end)

update()