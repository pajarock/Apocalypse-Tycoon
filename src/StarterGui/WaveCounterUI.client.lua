--!strict
--[[
	WAVE COUNTER UI - VERSIÓN ÉPICA
	═══════════════════════════════════════════════════════════════════════

	FEATURES:
	- Wave counter en esquina superior IZQUIERDA (no tapado)
	- Contador de dinero épico con animación
	- Mensaje "WAVE X COMPLETED!" en centro
	- Diseño moderno y llamativo

	INSTALACIÓN:
	1. Reemplazar WaveCounterUI.client.lua existente en StarterGui
	2. O crear nuevo LocalScript con este código
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--═══════════════════════════════════════════════════════════════════════
-- CONFIG
--═══════════════════════════════════════════════════════════════════════
local DEBUG = true

--═══════════════════════════════════════════════════════════════════════
-- CREAR SCREENGUI PRINCIPAL
--═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10 -- Por encima del leaderboard
screenGui.Parent = playerGui

--═══════════════════════════════════════════════════════════════════════
-- WAVE COUNTER (Superior Izquierda)
--═══════════════════════════════════════════════════════════════════════

local waveFrame = Instance.new("Frame")
waveFrame.Name = "WaveFrame"
waveFrame.Size = UDim2.fromOffset(200, 70)
waveFrame.Position = UDim2.new(0, 10, 0, 10) -- ✅ Superior IZQUIERDA
waveFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
waveFrame.BackgroundTransparency = 0.1
waveFrame.BorderSizePixel = 0
waveFrame.Parent = screenGui

local waveCorner = Instance.new("UICorner")
waveCorner.CornerRadius = UDim.new(0, 10)
waveCorner.Parent = waveFrame

local waveStroke = Instance.new("UIStroke")
waveStroke.Color = Color3.fromRGB(255, 170, 0)
waveStroke.Thickness = 3
waveStroke.Transparency = 0
waveStroke.Parent = waveFrame

local waveGradient = Instance.new("UIGradient")
waveGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
}
waveGradient.Rotation = 45
waveGradient.Parent = waveStroke

-- Label "WAVE"
local labelWave = Instance.new("TextLabel")
labelWave.Name = "LabelWave"
labelWave.Size = UDim2.fromScale(1, 0.35)
labelWave.Position = UDim2.fromScale(0, 0.1)
labelWave.BackgroundTransparency = 1
labelWave.Text = "WAVE"
labelWave.TextColor3 = Color3.fromRGB(255, 170, 0)
labelWave.TextScaled = true
labelWave.Font = Enum.Font.GothamBold
labelWave.Parent = waveFrame

-- Label número
local labelNumber = Instance.new("TextLabel")
labelNumber.Name = "LabelNumber"
labelNumber.Size = UDim2.fromScale(1, 0.5)
labelNumber.Position = UDim2.fromScale(0, 0.4)
labelNumber.BackgroundTransparency = 1
labelNumber.Text = "1"
labelNumber.TextColor3 = Color3.new(1, 1, 1)
labelNumber.TextScaled = true
labelNumber.Font = Enum.Font.GothamBlack
labelNumber.TextStrokeTransparency = 0.5
labelNumber.Parent = waveFrame

local wavePadding = Instance.new("UIPadding")
wavePadding.PaddingLeft = UDim.new(0, 8)
wavePadding.PaddingRight = UDim.new(0, 8)
wavePadding.PaddingTop = UDim.new(0, 5)
wavePadding.PaddingBottom = UDim.new(0, 5)
wavePadding.Parent = waveFrame

--═══════════════════════════════════════════════════════════════════════
-- CONTADOR DE DINERO ÉPICO (Superior Centro-Derecha)
--═══════════════════════════════════════════════════════════════════════

local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.Size = UDim2.fromOffset(280, 70)
moneyFrame.Position = UDim2.new(0.5, -140, 0, 10) -- Centro superior
moneyFrame.BackgroundColor3 = Color3.fromRGB(10, 15, 10)
moneyFrame.BackgroundTransparency = 0.1
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screenGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 10)
moneyCorner.Parent = moneyFrame

local moneyStroke = Instance.new("UIStroke")
moneyStroke.Color = Color3.fromRGB(85, 255, 127)
moneyStroke.Thickness = 3
moneyStroke.Transparency = 0
moneyStroke.Parent = moneyFrame

local moneyGradient = Instance.new("UIGradient")
moneyGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(85, 255, 127)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 100))
}
moneyGradient.Rotation = 90
moneyGradient.Parent = moneyStroke

-- Ícono de dinero
local moneyIcon = Instance.new("TextLabel")
moneyIcon.Name = "Icon"
moneyIcon.Size = UDim2.fromScale(0.2, 0.7)
moneyIcon.Position = UDim2.fromScale(0.05, 0.15)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Text = "💰"
moneyIcon.TextScaled = true
moneyIcon.Font = Enum.Font.GothamBold
moneyIcon.Parent = moneyFrame

-- Label de dinero
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.fromScale(0.7, 0.8)
moneyLabel.Position = UDim2.fromScale(0.28, 0.1)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "$0"
moneyLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.GothamBlack
moneyLabel.TextStrokeTransparency = 0.7
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyFrame

local moneyPadding = Instance.new("UIPadding")
moneyPadding.PaddingLeft = UDim.new(0, 10)
moneyPadding.PaddingRight = UDim.new(0, 10)
moneyPadding.Parent = moneyFrame

--═══════════════════════════════════════════════════════════════════════
-- MENSAJE "WAVE COMPLETED" (Centro Pantalla)
--═══════════════════════════════════════════════════════════════════════

local completedFrame = Instance.new("Frame")
completedFrame.Name = "WaveCompletedFrame"
completedFrame.Size = UDim2.fromOffset(500, 150)
completedFrame.Position = UDim2.fromScale(0.5, 0.4)
completedFrame.AnchorPoint = Vector2.new(0.5, 0.5)
completedFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
completedFrame.BackgroundTransparency = 0.3
completedFrame.BorderSizePixel = 0
completedFrame.Visible = false -- Oculto por defecto
completedFrame.Parent = screenGui

local completedCorner = Instance.new("UICorner")
completedCorner.CornerRadius = UDim.new(0, 20)
completedCorner.Parent = completedFrame

local completedStroke = Instance.new("UIStroke")
completedStroke.Color = Color3.fromRGB(255, 215, 0)
completedStroke.Thickness = 5
completedStroke.Transparency = 0
completedStroke.Parent = completedFrame

-- Texto principal
local completedText = Instance.new("TextLabel")
completedText.Name = "Text"
completedText.Size = UDim2.fromScale(1, 0.6)
completedText.Position = UDim2.fromScale(0, 0.15)
completedText.BackgroundTransparency = 1
completedText.Text = "WAVE 1 COMPLETED!"
completedText.TextColor3 = Color3.fromRGB(255, 215, 0)
completedText.TextScaled = true
completedText.Font = Enum.Font.GothamBlack
completedText.TextStrokeTransparency = 0
completedText.Parent = completedFrame

-- Subtexto
local completedSubtext = Instance.new("TextLabel")
completedSubtext.Name = "Subtext"
completedSubtext.Size = UDim2.fromScale(1, 0.2)
completedSubtext.Position = UDim2.fromScale(0, 0.75)
completedSubtext.BackgroundTransparency = 1
completedSubtext.Text = "Preparing next wave..."
completedSubtext.TextColor3 = Color3.fromRGB(200, 200, 200)
completedSubtext.TextScaled = true
completedSubtext.Font = Enum.Font.Gotham
completedSubtext.Parent = completedFrame

--═══════════════════════════════════════════════════════════════════════
-- FUNCIONES DE ANIMACIÓN
--═══════════════════════════════════════════════════════════════════════

local function formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return string.format("$%d", amount)
	end
end

local function animateMoneyChange(oldValue: number, newValue: number)
	-- Interpolación suave
	local duration = 0.5
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			local alpha = (tick() - startTime) / duration
			local current = oldValue + (newValue - oldValue) * alpha
			moneyLabel.Text = formatMoney(math.floor(current))
			task.wait()
		end
		moneyLabel.Text = formatMoney(newValue)
	end)

	-- Flash verde si ganas dinero, rojo si pierdes
	if newValue > oldValue then
		moneyStroke.Color = Color3.fromRGB(0, 255, 0)
	else
		moneyStroke.Color = Color3.fromRGB(255, 0, 0)
	end

	TweenService:Create(moneyStroke, TweenInfo.new(0.5), {
		Color = Color3.fromRGB(85, 255, 127)
	}):Play()
end

local function playWavePulse()
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(waveFrame, tweenInfo, {
		Size = UDim2.fromOffset(220, 80)
	}):Play()
end

local function playWaveFlash()
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

	waveStroke.Color = Color3.new(1, 1, 1)
	TweenService:Create(waveStroke, tweenInfo, {
		Color = Color3.fromRGB(255, 170, 0)
	}):Play()

	labelWave.TextColor3 = Color3.new(1, 1, 1)
	TweenService:Create(labelWave, tweenInfo, {
		TextColor3 = Color3.fromRGB(255, 170, 0)
	}):Play()
end

local function showWaveCompleted(waveNum: number)
	completedText.Text = string.format("✨ WAVE %d COMPLETED! ✨", waveNum)
	completedFrame.Visible = true
	completedFrame.Size = UDim2.fromOffset(0, 0)
	completedFrame.BackgroundTransparency = 1
	completedText.TextTransparency = 1
	completedSubtext.TextTransparency = 1

	-- Animación de entrada
	local tweenIn = TweenService:Create(completedFrame, TweenInfo.new(0.5, Enum.EasingStyle.Elastic), {
		Size = UDim2.fromOffset(500, 150),
		BackgroundTransparency = 0.3
	})

	local tweenText = TweenService:Create(completedText, TweenInfo.new(0.5), {
		TextTransparency = 0
	})

	local tweenSubtext = TweenService:Create(completedSubtext, TweenInfo.new(0.5), {
		TextTransparency = 0
	})

	tweenIn:Play()
	tweenText:Play()
	tweenSubtext:Play()

	-- Esperar 3 segundos y ocultar
	task.delay(3, function()
		local tweenOut = TweenService:Create(completedFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})

		local tweenTextOut = TweenService:Create(completedText, TweenInfo.new(0.5), {
			TextTransparency = 1
		})

		local tweenSubtextOut = TweenService:Create(completedSubtext, TweenInfo.new(0.5), {
			TextTransparency = 1
		})

		tweenOut:Play()
		tweenTextOut:Play()
		tweenSubtextOut:Play()

		tweenOut.Completed:Connect(function()
			completedFrame.Visible = false
		end)
	end)
end

local function updateWave(newWave: number)
	labelNumber.Text = tostring(newWave)

	playWavePulse()
	playWaveFlash()

	if DEBUG then
		print(("[WaveCounterUI] 🎉 Wave %d!"):format(newWave))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- SINCRONIZACIÓN CON SERVIDOR
--═══════════════════════════════════════════════════════════════════════

-- Wave Counter
local currentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

if currentWaveValue and currentWaveValue:IsA("IntValue") then
	labelNumber.Text = tostring(currentWaveValue.Value)

	local previousWave = currentWaveValue.Value

	currentWaveValue:GetPropertyChangedSignal("Value"):Connect(function()
		local newWave = currentWaveValue.Value

		-- ✅ ARREGLADO: NO mostrar mensaje automático aquí
		-- El servidor ya envía el mensaje a través de EventNotifier
		-- Si mostramos aquí también, sale duplicado

		--[[
		-- CÓDIGO ANTIGUO (CAUSABA DUPLICADOS):
		if newWave > previousWave then
			task.delay(0.5, function()
				showWaveCompleted(previousWave)
			end)
		end
		]]--

		updateWave(newWave)
		previousWave = newWave
	end)

	if DEBUG then
		print("[WaveCounterUI] ✓ Wave counter conectado")
	end
else
	warn("[WaveCounterUI] ⚠️ No se encontró CurrentWave")
end

-- Money Counter
local leaderstats = player:WaitForChild("leaderstats")
local cashValue = leaderstats:WaitForChild("Cash")

if cashValue then
	moneyLabel.Text = formatMoney(cashValue.Value)

	local previousCash = cashValue.Value

	cashValue:GetPropertyChangedSignal("Value"):Connect(function()
		animateMoneyChange(previousCash, cashValue.Value)
		previousCash = cashValue.Value
	end)

	if DEBUG then
		print("[WaveCounterUI] ✓ Money counter conectado")
	end
end

--═══════════════════════════════════════════════════════════════════════

if DEBUG then
	print("[WaveCounterUI] ✓ HUD Épico inicializado")
end
