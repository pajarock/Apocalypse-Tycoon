--!strict
--[[
	-----------------------------------------------------------------------
	DEBUG CONTROLS - Cliente
	-----------------------------------------------------------------------

	CONTROLES DE DEBUG (Solo en Studio):

	WAVES:
	- N: Skip al siguiente wave
	- Shift+N: Saltar +5 waves
	- Y: Reset a Wave 1
	- 1-9: Saltar a wave específico (x10): 10, 20, 30... 90
	- 0: Saltar a wave 100

	BOSS/MINI-BOSS:
	- B: Spawn Boss instantáneo (4 fases completas)
	- V: Spawn Mini-Boss instantáneo (1 fase aleatoria)

	ECONOMÍA:
	- C: Añadir $10,000
	- Shift+C: Añadir $100,000

	SUPERVIVENCIA:
	- J: Toggle Invencibilidad (no recibes daño)

	OTROS:
	- M: Spawn meteorito aleatorio
	- K: Test camera shake
	- L: Test screen flash
	- H: Toggle ayuda visual

	-----------------------------------------------------------------------
--]]

local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Solo funciona en Studio
if not RunService:IsStudio() then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Remotes
local Remotes = RS:WaitForChild("Remotes")
local DebugSpawnMeteor = Remotes:WaitForChild("DebugSpawnMeteor")
local DebugSkipWave = Remotes:WaitForChild("DebugSkipWave")
local DebugJumpToWave = Remotes:WaitForChild("DebugJumpToWave")
local DebugSpawnBoss = Remotes:WaitForChild("DebugSpawnBoss")
local DebugSpawnMiniBoss = Remotes:WaitForChild("DebugSpawnMiniBoss")
local DebugAddCash = Remotes:WaitForChild("DebugAddCash")
local DebugResetWave = Remotes:WaitForChild("DebugResetWave")
local DebugToggleInvincibility = Remotes:WaitForChild("DebugToggleInvincibility")
local DebugInvincibilityChanged = Remotes:WaitForChild("DebugInvincibilityChanged")

print("[DEBUG CONTROLS] ??? Controles de debug cargados")
print("[DEBUG CONTROLS] Presiona H para ver la ayuda")

-------------------------------------------------------------------------
-- UI DE AYUDA
-------------------------------------------------------------------------

local helpVisible = false

local function createHelpUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DebugHelp"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "HelpFrame"
	frame.Size = UDim2.new(0, 400, 0, 500)
	frame.Position = UDim2.new(1, -420, 0, 20)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = frame

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 100, 0)
	stroke.Thickness = 2
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -20, 0, 40)
	title.Position = UDim2.new(0, 10, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "??? DEBUG CONTROLS"
	title.TextColor3 = Color3.fromRGB(255, 200, 100)
	title.TextSize = 20
	title.Font = Enum.Font.GothamBold
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = frame

	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "ScrollFrame"
	scrollFrame.Size = UDim2.new(1, -20, 1, -70)
	scrollFrame.Position = UDim2.new(0, 10, 0, 60)
	scrollFrame.BackgroundTransparency = 1
	scrollFrame.BorderSizePixel = 0
	scrollFrame.ScrollBarThickness = 6
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	scrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scrollFrame.Parent = frame

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 8)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = scrollFrame

	local commands = {
		{section = "WAVES", color = Color3.fromRGB(100, 200, 255)},
		{key = "N", desc = "Skip al siguiente wave"},
		{key = "Shift+N", desc = "Saltar +5 waves"},
		{key = "Y", desc = "Reset a Wave 1"},
		{key = "1-9", desc = "Saltar a wave x10 (10, 20... 90)"},
		{key = "0", desc = "Saltar a wave 100"},

		{section = "BOSS/MINI-BOSS", color = Color3.fromRGB(255, 100, 100)},
		{key = "B", desc = "Spawn Boss (4 fases)"},
		{key = "V", desc = "Spawn Mini-Boss (1 fase)"},

		{section = "ECONOMÍA", color = Color3.fromRGB(100, 255, 100)},
		{key = "C", desc = "Añadir $10,000"},
		{key = "Shift+C", desc = "Añadir $100,000"},

		{section = "SUPERVIVENCIA", color = Color3.fromRGB(255, 215, 0)},
		{key = "J", desc = "Toggle Invencibilidad"},

		{section = "OTROS", color = Color3.fromRGB(255, 200, 100)},
		{key = "M", desc = "Spawn meteorito aleatorio"},
		{key = "K", desc = "Test camera shake"},
		{key = "L", desc = "Test screen flash"},
		{key = "H", desc = "Toggle esta ayuda"},
	}

	for i, cmd in ipairs(commands) do
		if cmd.section then
			-- Sección
			local sectionLabel = Instance.new("TextLabel")
			sectionLabel.Name = "Section" .. i
			sectionLabel.Size = UDim2.new(1, 0, 0, 25)
			sectionLabel.BackgroundTransparency = 1
			sectionLabel.Text = cmd.section
			sectionLabel.TextColor3 = cmd.color
			sectionLabel.TextSize = 16
			sectionLabel.Font = Enum.Font.GothamBold
			sectionLabel.TextXAlignment = Enum.TextXAlignment.Left
			sectionLabel.LayoutOrder = i
			sectionLabel.Parent = scrollFrame
		else
			-- Comando
			local cmdFrame = Instance.new("Frame")
			cmdFrame.Name = "Command" .. i
			cmdFrame.Size = UDim2.new(1, 0, 0, 22)
			cmdFrame.BackgroundTransparency = 1
			cmdFrame.LayoutOrder = i
			cmdFrame.Parent = scrollFrame

			local keyLabel = Instance.new("TextLabel")
			keyLabel.Name = "Key"
			keyLabel.Size = UDim2.new(0, 100, 1, 0)
			keyLabel.BackgroundTransparency = 1
			keyLabel.Text = cmd.key
			keyLabel.TextColor3 = Color3.fromRGB(255, 255, 150)
			keyLabel.TextSize = 14
			keyLabel.Font = Enum.Font.GothamMedium
			keyLabel.TextXAlignment = Enum.TextXAlignment.Left
			keyLabel.Parent = cmdFrame

			local descLabel = Instance.new("TextLabel")
			descLabel.Name = "Desc"
			descLabel.Size = UDim2.new(1, -105, 1, 0)
			descLabel.Position = UDim2.new(0, 105, 0, 0)
			descLabel.BackgroundTransparency = 1
			descLabel.Text = cmd.desc
			descLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
			descLabel.TextSize = 13
			descLabel.Font = Enum.Font.Gotham
			descLabel.TextXAlignment = Enum.TextXAlignment.Left
			descLabel.TextWrapped = true
			descLabel.Parent = cmdFrame
		end
	end

	return screenGui
end

local helpUI = createHelpUI()

local function toggleHelp()
	helpVisible = not helpVisible
	helpUI.Enabled = helpVisible
	if helpVisible then
		print("[DEBUG CONTROLS] ?? Ayuda mostrada")
	else
		print("[DEBUG CONTROLS] ?? Ayuda ocultada")
	end
end

-------------------------------------------------------------------------
-- FEEDBACK VISUAL
-------------------------------------------------------------------------

local function showFeedback(message: string, color: Color3?)
	local feedbackColor = color or Color3.fromRGB(255, 200, 100)

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "DebugFeedback"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 300, 0, 50)
	label.Position = UDim2.new(0.5, -150, 0, 100)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.2
	label.Text = message
	label.TextColor3 = feedbackColor
	label.TextSize = 18
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label

	local stroke = Instance.new("UIStroke")
	stroke.Color = feedbackColor
	stroke.Thickness = 2
	stroke.Parent = label

	-- Animación de fade out
	task.spawn(function()
		task.wait(1.5)
		for i = 0, 1, 0.05 do
			label.BackgroundTransparency = 0.2 + (i * 0.8)
			label.TextTransparency = i
			stroke.Transparency = i
			task.wait(0.03)
		end
		screenGui:Destroy()
	end)
end

-------------------------------------------------------------------------
-- INPUT HANDLING
-------------------------------------------------------------------------

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local shiftPressed = UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.RightShift)

	-- METEORITO (tecla original)
	if input.KeyCode == Enum.KeyCode.M then
		DebugSpawnMeteor:FireServer()
		showFeedback("?? Spawning Meteor", Color3.fromRGB(255, 100, 50))

		-- SKIP WAVE
	elseif input.KeyCode == Enum.KeyCode.N then
		if shiftPressed then
			DebugSkipWave:FireServer(5)
			showFeedback("?? Skipping +5 Waves", Color3.fromRGB(100, 200, 255))
		else
			DebugSkipWave:FireServer(1)
			showFeedback("? Skipping to Next Wave", Color3.fromRGB(100, 200, 255))
		end

		-- RESET WAVE
	elseif input.KeyCode == Enum.KeyCode.Y then
		DebugResetWave:FireServer()
		showFeedback("?? Wave Reset to 1", Color3.fromRGB(255, 200, 100))

		-- SPAWN BOSS
	elseif input.KeyCode == Enum.KeyCode.B then
		DebugSpawnBoss:FireServer()
		showFeedback("?? Spawning BOSS", Color3.fromRGB(255, 50, 50))

		-- SPAWN MINI-BOSS
	elseif input.KeyCode == Enum.KeyCode.V then
		DebugSpawnMiniBoss:FireServer()
		showFeedback("?? Spawning MINI-BOSS", Color3.fromRGB(255, 100, 150))

		-- ADD CASH
	elseif input.KeyCode == Enum.KeyCode.C then
		if shiftPressed then
			DebugAddCash:FireServer(100000)
			showFeedback("?? +$100,000", Color3.fromRGB(100, 255, 100))
		else
			DebugAddCash:FireServer(10000)
			showFeedback("?? +$10,000", Color3.fromRGB(100, 255, 100))
		end

		-- TOGGLE HELP
	elseif input.KeyCode == Enum.KeyCode.H then
		toggleHelp()

		-- SALTAR A WAVE ESPECÍFICO (1-9, 0)
	elseif input.KeyCode == Enum.KeyCode.One then
		DebugJumpToWave:FireServer(10)
		showFeedback("?? Jumping to Wave 10", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Two then
		DebugJumpToWave:FireServer(20)
		showFeedback("?? Jumping to Wave 20", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Three then
		DebugJumpToWave:FireServer(30)
		showFeedback("?? Jumping to Wave 30", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Four then
		DebugJumpToWave:FireServer(40)
		showFeedback("?? Jumping to Wave 40", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Five then
		DebugJumpToWave:FireServer(50)
		showFeedback("?? Jumping to Wave 50", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Six then
		DebugJumpToWave:FireServer(60)
		showFeedback("?? Jumping to Wave 60", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Seven then
		DebugJumpToWave:FireServer(70)
		showFeedback("?? Jumping to Wave 70", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Eight then
		DebugJumpToWave:FireServer(80)
		showFeedback("?? Jumping to Wave 80", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Nine then
		DebugJumpToWave:FireServer(90)
		showFeedback("?? Jumping to Wave 90", Color3.fromRGB(100, 200, 255))

	elseif input.KeyCode == Enum.KeyCode.Zero then
		DebugJumpToWave:FireServer(100)
		showFeedback("?? Jumping to Wave 100", Color3.fromRGB(100, 200, 255))

		-- TOGGLE INVINCIBILITY
	elseif input.KeyCode == Enum.KeyCode.J then
		DebugToggleInvincibility:FireServer()
		-- El feedback se mostrará cuando el servidor confirme el cambio
	end
end)

-------------------------------------------------------------------------
-- INVINCIBILITY VISUAL FEEDBACK
-------------------------------------------------------------------------

local invincibilityOverlay = nil

local function createInvincibilityOverlay()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InvincibilityOverlay"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui

	-- Borde dorado brillante
	local frame = Instance.new("Frame")
	frame.Name = "Border"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui

	-- Borde superior
	local topBorder = Instance.new("Frame")
	topBorder.Name = "Top"
	topBorder.Size = UDim2.new(1, 0, 0, 4)
	topBorder.Position = UDim2.new(0, 0, 0, 0)
	topBorder.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	topBorder.BorderSizePixel = 0
	topBorder.Parent = frame

	-- Borde inferior
	local bottomBorder = Instance.new("Frame")
	bottomBorder.Name = "Bottom"
	bottomBorder.Size = UDim2.new(1, 0, 0, 4)
	bottomBorder.Position = UDim2.new(0, 0, 1, -4)
	bottomBorder.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	bottomBorder.BorderSizePixel = 0
	bottomBorder.Parent = frame

	-- Borde izquierdo
	local leftBorder = Instance.new("Frame")
	leftBorder.Name = "Left"
	leftBorder.Size = UDim2.new(0, 4, 1, 0)
	leftBorder.Position = UDim2.new(0, 0, 0, 0)
	leftBorder.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	leftBorder.BorderSizePixel = 0
	leftBorder.Parent = frame

	-- Borde derecho
	local rightBorder = Instance.new("Frame")
	rightBorder.Name = "Right"
	rightBorder.Size = UDim2.new(0, 4, 1, 0)
	rightBorder.Position = UDim2.new(1, -4, 0, 0)
	rightBorder.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
	rightBorder.BorderSizePixel = 0
	rightBorder.Parent = frame

	-- Indicador de texto
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.Size = UDim2.new(0, 300, 0, 40)
	label.Position = UDim2.new(0.5, -150, 0, 20)
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	label.BackgroundTransparency = 0.3
	label.Text = "??? INVENCIBLE"
	label.TextColor3 = Color3.fromRGB(255, 215, 0)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.TextStrokeTransparency = 0.5
	label.Parent = frame

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 10)
	labelCorner.Parent = label

	local labelStroke = Instance.new("UIStroke")
	labelStroke.Color = Color3.fromRGB(255, 215, 0)
	labelStroke.Thickness = 2
	labelStroke.Parent = label

	-- Animación de pulso
	task.spawn(function()
		while screenGui.Enabled do
			for i = 0, 1, 0.05 do
				if not screenGui.Enabled then break end
				local transparency = 0.3 + (math.sin(i * math.pi * 2) * 0.3)
				topBorder.BackgroundTransparency = transparency
				bottomBorder.BackgroundTransparency = transparency
				leftBorder.BackgroundTransparency = transparency
				rightBorder.BackgroundTransparency = transparency
				labelStroke.Transparency = transparency
				task.wait(0.03)
			end
		end
	end)

	return screenGui
end

invincibilityOverlay = createInvincibilityOverlay()

-- Listener para cambios de invencibilidad desde el servidor
DebugInvincibilityChanged.OnClientEvent:Connect(function(isInvincible: boolean)
	invincibilityOverlay.Enabled = isInvincible

	if isInvincible then
		showFeedback("??? INVENCIBILIDAD ACTIVADA", Color3.fromRGB(255, 215, 0))
	else
		showFeedback("?? INVENCIBILIDAD DESACTIVADA", Color3.fromRGB(200, 200, 200))
	end
end)

print("[DEBUG CONTROLS] ? Sistema de debug activado")
print("[DEBUG CONTROLS] ?? Presiona H para ver todos los comandos")