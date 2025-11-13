--!strict
--[[
	UI ÉPICA TÓXICA - APOCALYPSE TYCOON
	═══════════════════════════════════════════════════════════════════════

	FEATURES:
	- Wave counter UNIFICADO: "WAVE 5 | SURVIVED: 4"
	- Money counter TÓXICO radiante (media pantalla derecha)
	- Números verdes con glow, partículas, vida propia
	- Efectos de radiación tóxica
	- Animaciones épicas

	INSTALACIÓN:
	Reemplazar WaveCounterUI.client.lua en StarterGui
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local DEBUG = true

--═══════════════════════════════════════════════════════════════════════
-- CREAR SCREENGUI
--═══════════════════════════════════════════════════════════════════════

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD_Toxic"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

--═══════════════════════════════════════════════════════════════════════
-- WAVE COUNTER UNIFICADO (Superior Izquierda)
--═══════════════════════════════════════════════════════════════════════

local waveFrame = Instance.new("Frame")
waveFrame.Name = "WaveFrame"
waveFrame.Size = UDim2.fromOffset(280, 90)
waveFrame.Position = UDim2.new(0, 10, 0, 10)
waveFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
waveFrame.BackgroundTransparency = 0.1
waveFrame.BorderSizePixel = 0
waveFrame.Parent = screenGui

local waveCorner = Instance.new("UICorner")
waveCorner.CornerRadius = UDim.new(0, 12)
waveCorner.Parent = waveFrame

local waveStroke = Instance.new("UIStroke")
waveStroke.Color = Color3.fromRGB(255, 170, 0)
waveStroke.Thickness = 3
waveStroke.Parent = waveFrame

local waveGradient = Instance.new("UIGradient")
waveGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 0))
}
waveGradient.Rotation = 45
waveGradient.Parent = waveStroke

-- Label "WAVE X"
local labelCurrent = Instance.new("TextLabel")
labelCurrent.Name = "LabelCurrent"
labelCurrent.Size = UDim2.fromScale(1, 0.5)
labelCurrent.Position = UDim2.fromScale(0, 0.05)
labelCurrent.BackgroundTransparency = 1
labelCurrent.Text = "WAVE 1"
labelCurrent.TextColor3 = Color3.fromRGB(255, 200, 0)
labelCurrent.TextScaled = true
labelCurrent.Font = Enum.Font.GothamBlack
labelCurrent.TextStrokeTransparency = 0.5
labelCurrent.Parent = waveFrame

-- Label "SURVIVED: X"
local labelSurvived = Instance.new("TextLabel")
labelSurvived.Name = "LabelSurvived"
labelSurvived.Size = UDim2.fromScale(1, 0.35)
labelSurvived.Position = UDim2.fromScale(0, 0.55)
labelSurvived.BackgroundTransparency = 1
labelSurvived.Text = "SURVIVED: 0"
labelSurvived.TextColor3 = Color3.fromRGB(85, 255, 127)
labelSurvived.TextScaled = true
labelSurvived.Font = Enum.Font.GothamBold
labelSurvived.TextStrokeTransparency = 0.7
labelSurvived.Parent = waveFrame

local wavePadding = Instance.new("UIPadding")
wavePadding.PaddingLeft = UDim.new(0, 15)
wavePadding.PaddingRight = UDim.new(0, 15)
wavePadding.PaddingTop = UDim.new(0, 8)
wavePadding.PaddingBottom = UDim.new(0, 8)
wavePadding.Parent = waveFrame

--═══════════════════════════════════════════════════════════════════════
-- MONEY COUNTER TÓXICO (Media Pantalla Derecha)
--═══════════════════════════════════════════════════════════════════════

local moneyFrame = Instance.new("Frame")
moneyFrame.Name = "MoneyFrame"
moneyFrame.Size = UDim2.fromScale(0.5, 0.15) -- Media pantalla ancho, 15% alto
moneyFrame.Position = UDim2.new(0.5, 0, 0.025, 0) -- Derecha, arriba
moneyFrame.AnchorPoint = Vector2.new(0, 0)
moneyFrame.BackgroundColor3 = Color3.fromRGB(5, 15, 5)
moneyFrame.BackgroundTransparency = 0
moneyFrame.BorderSizePixel = 0
moneyFrame.Parent = screenGui

local moneyCorner = Instance.new("UICorner")
moneyCorner.CornerRadius = UDim.new(0, 15)
moneyCorner.Parent = moneyFrame

-- Borde tóxico radiante
local moneyStroke = Instance.new("UIStroke")
moneyStroke.Color = Color3.fromRGB(0, 255, 0)
moneyStroke.Thickness = 4
moneyStroke.Transparency = 0
moneyStroke.Parent = moneyFrame

-- Gradiente tóxico
local moneyGradient = Instance.new("UIGradient")
moneyGradient.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(85, 255, 127)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 0))
}
moneyGradient.Rotation = 0
moneyGradient.Parent = moneyStroke

-- Animación del gradiente (rotación constante para efecto radiante)
task.spawn(function()
	while moneyGradient and moneyGradient.Parent do
		for rotation = 0, 360, 2 do
			if not moneyGradient or not moneyGradient.Parent then break end
			moneyGradient.Rotation = rotation
			task.wait(0.03)
		end
	end
end)

-- Ícono tóxico
local moneyIcon = Instance.new("ImageLabel")
moneyIcon.Name = "Icon"
moneyIcon.Size = UDim2.fromScale(0.15, 0.8)
moneyIcon.Position = UDim2.fromScale(0.05, 0.1)
moneyIcon.AnchorPoint = Vector2.new(0, 0)
moneyIcon.BackgroundTransparency = 1
moneyIcon.Image = "rbxassetid://6031097225" -- Radioactive symbol
moneyIcon.ImageColor3 = Color3.fromRGB(0, 255, 0)
moneyIcon.ScaleType = Enum.ScaleType.Fit
moneyIcon.Parent = moneyFrame

-- Animación de rotación del ícono
task.spawn(function()
	while moneyIcon and moneyIcon.Parent do
		for rotation = 0, 360, 3 do
			if not moneyIcon or not moneyIcon.Parent then break end
			moneyIcon.Rotation = rotation
			task.wait(0.02)
		end
	end
end)

-- Label "$" con glow
local dollarSign = Instance.new("TextLabel")
dollarSign.Name = "DollarSign"
dollarSign.Size = UDim2.fromScale(0.12, 0.8)
dollarSign.Position = UDim2.fromScale(0.22, 0.1)
dollarSign.BackgroundTransparency = 1
dollarSign.Text = "$"
dollarSign.TextColor3 = Color3.fromRGB(0, 255, 0)
dollarSign.TextScaled = true
dollarSign.Font = Enum.Font.GothamBlack
dollarSign.TextStrokeTransparency = 0
dollarSign.TextStrokeColor3 = Color3.fromRGB(0, 100, 0)
dollarSign.Parent = moneyFrame

-- Números tóxicos con glow
local moneyLabel = Instance.new("TextLabel")
moneyLabel.Name = "MoneyLabel"
moneyLabel.Size = UDim2.fromScale(0.6, 0.8)
moneyLabel.Position = UDim2.fromScale(0.35, 0.1)
moneyLabel.BackgroundTransparency = 1
moneyLabel.Text = "0"
moneyLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
moneyLabel.TextScaled = true
moneyLabel.Font = Enum.Font.GothamBlack
moneyLabel.TextStrokeTransparency = 0
moneyLabel.TextStrokeColor3 = Color3.fromRGB(0, 150, 0)
moneyLabel.TextXAlignment = Enum.TextXAlignment.Left
moneyLabel.Parent = moneyFrame

-- Efecto de "respiración" en el brillo del dinero
task.spawn(function()
	while moneyLabel and moneyLabel.Parent do
		-- Inhalar (más brillante)
		TweenService:Create(moneyLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextStrokeTransparency = 0.3
		}):Play()
		task.wait(1.5)

		-- Exhalar (más oscuro)
		if not moneyLabel or not moneyLabel.Parent then break end
		TweenService:Create(moneyLabel, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			TextStrokeTransparency = 0
		}):Play()
		task.wait(1.5)
	end
end)

-- Partículas tóxicas (usando ImageLabels animados)
for i = 1, 6 do
	local particle = Instance.new("Frame")
	particle.Name = "Particle" .. i
	particle.Size = UDim2.fromOffset(6, 6)
	particle.Position = UDim2.fromScale(math.random(10, 90) / 100, math.random(10, 90) / 100)
	particle.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	particle.BackgroundTransparency = 0.5
	particle.BorderSizePixel = 0
	particle.ZIndex = 0
	particle.Parent = moneyFrame

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = particle

	-- Animación flotante aleatoria
	task.spawn(function()
		while particle and particle.Parent do
			local randomX = math.random(5, 95) / 100
			local randomY = math.random(5, 95) / 100
			local duration = math.random(20, 40) / 10

			TweenService:Create(particle, TweenInfo.new(duration, Enum.EasingStyle.Sine), {
				Position = UDim2.fromScale(randomX, randomY),
				BackgroundTransparency = math.random(30, 80) / 100
			}):Play()

			task.wait(duration)
		end
	end)
end

local moneyPadding = Instance.new("UIPadding")
moneyPadding.PaddingLeft = UDim.new(0, 20)
moneyPadding.PaddingRight = UDim.new(0, 20)
moneyPadding.PaddingTop = UDim.new(0, 10)
moneyPadding.PaddingBottom = UDim.new(0, 10)
moneyPadding.Parent = moneyFrame

--═══════════════════════════════════════════════════════════════════════
-- MENSAJE "WAVE COMPLETED" (Centro)
--═══════════════════════════════════════════════════════════════════════

local completedFrame = Instance.new("Frame")
completedFrame.Name = "WaveCompletedFrame"
completedFrame.Size = UDim2.fromOffset(550, 180)
completedFrame.Position = UDim2.fromScale(0.5, 0.35)
completedFrame.AnchorPoint = Vector2.new(0.5, 0.5)
completedFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
completedFrame.BackgroundTransparency = 0.2
completedFrame.BorderSizePixel = 0
completedFrame.Visible = false
completedFrame.Parent = screenGui

local completedCorner = Instance.new("UICorner")
completedCorner.CornerRadius = UDim.new(0, 25)
completedCorner.Parent = completedFrame

local completedStroke = Instance.new("UIStroke")
completedStroke.Color = Color3.fromRGB(255, 215, 0)
completedStroke.Thickness = 6
completedStroke.Parent = completedFrame

local completedText = Instance.new("TextLabel")
completedText.Size = UDim2.fromScale(1, 0.5)
completedText.Position = UDim2.fromScale(0, 0.15)
completedText.BackgroundTransparency = 1
completedText.Text = "✨ WAVE 1 COMPLETED! ✨"
completedText.TextColor3 = Color3.fromRGB(255, 215, 0)
completedText.TextScaled = true
completedText.Font = Enum.Font.GothamBlack
completedText.TextStrokeTransparency = 0
completedText.Parent = completedFrame

local completedSubtext = Instance.new("TextLabel")
completedSubtext.Size = UDim2.fromScale(1, 0.25)
completedSubtext.Position = UDim2.fromScale(0, 0.7)
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
	if amount >= 1000000000 then
		return string.format("%.2fB", amount / 1000000000)
	elseif amount >= 1000000 then
		return string.format("%.2fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("%.1fK", amount / 1000)
	else
		return string.format("%d", amount)
	end
end

local function animateMoneyChange(oldValue: number, newValue: number)
	-- Interpolación suave
	local duration = 0.6
	local startTime = tick()

	task.spawn(function()
		while tick() - startTime < duration do
			if not moneyLabel or not moneyLabel.Parent then break end

			local alpha = (tick() - startTime) / duration
			local current = oldValue + (newValue - oldValue) * alpha
			moneyLabel.Text = formatMoney(math.floor(current))
			task.wait()
		end

		if moneyLabel and moneyLabel.Parent then
			moneyLabel.Text = formatMoney(newValue)
		end
	end)

	-- Efecto tóxico pulsante
	if newValue > oldValue then
		-- Ganancia: pulso verde brillante
		TweenService:Create(moneyStroke, TweenInfo.new(0.3), {
			Color = Color3.fromRGB(0, 255, 50)
		}):Play()

		TweenService:Create(moneyFrame, TweenInfo.new(0.2, Enum.EasingStyle.Elastic), {
			Size = UDim2.fromScale(0.52, 0.16)
		}):Play()

		task.delay(0.2, function()
			if not moneyFrame or not moneyFrame.Parent then return end
			TweenService:Create(moneyFrame, TweenInfo.new(0.3), {
				Size = UDim2.fromScale(0.5, 0.15)
			}):Play()
		end)
	else
		-- Pérdida: pulso rojo
		TweenService:Create(moneyStroke, TweenInfo.new(0.3), {
			Color = Color3.fromRGB(255, 0, 0)
		}):Play()
	end

	task.delay(0.5, function()
		if not moneyStroke or not moneyStroke.Parent then return end
		TweenService:Create(moneyStroke, TweenInfo.new(0.5), {
			Color = Color3.fromRGB(0, 255, 0)
		}):Play()
	end)
end

local function updateWave(currentWave: number, survivedWaves: number)
	labelCurrent.Text = string.format("WAVE %d", currentWave)
	labelSurvived.Text = string.format("SURVIVED: %d", survivedWaves)

	-- Animación pulse
	TweenService:Create(waveFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true), {
		Size = UDim2.fromOffset(300, 100)
	}):Play()

	-- Flash
	waveStroke.Color = Color3.new(1, 1, 1)
	TweenService:Create(waveStroke, TweenInfo.new(0.5), {
		Color = Color3.fromRGB(255, 170, 0)
	}):Play()

	if DEBUG then
		print(("[UI] 🎉 Wave %d | Survived: %d"):format(currentWave, survivedWaves))
	end
end

local function showWaveCompleted(waveNum: number)
	completedText.Text = string.format("✨ WAVE %d COMPLETED! ✨", waveNum)
	completedFrame.Visible = true
	completedFrame.Size = UDim2.fromOffset(0, 0)
	completedFrame.BackgroundTransparency = 1
	completedText.TextTransparency = 1
	completedSubtext.TextTransparency = 1

	TweenService:Create(completedFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic), {
		Size = UDim2.fromOffset(550, 180),
		BackgroundTransparency = 0.2
	}):Play()

	TweenService:Create(completedText, TweenInfo.new(0.5), {
		TextTransparency = 0
	}):Play()

	TweenService:Create(completedSubtext, TweenInfo.new(0.5), {
		TextTransparency = 0
	}):Play()

	task.delay(3.5, function()
		if not completedFrame or not completedFrame.Parent then return end

		TweenService:Create(completedFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		}):Play()

		TweenService:Create(completedText, TweenInfo.new(0.5), {
			TextTransparency = 1
		}):Play()

		local tween = TweenService:Create(completedSubtext, TweenInfo.new(0.5), {
			TextTransparency = 1
		})
		tween:Play()

		tween.Completed:Connect(function()
			if completedFrame and completedFrame.Parent then
				completedFrame.Visible = false
			end
		end)
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- SINCRONIZACIÓN
--═══════════════════════════════════════════════════════════════════════

-- Wave Counter
local currentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

if currentWaveValue and currentWaveValue:IsA("IntValue") then
	local currentWave = currentWaveValue.Value
	local survivedWaves = math.max(0, currentWave - 1)

	labelCurrent.Text = string.format("WAVE %d", currentWave)
	labelSurvived.Text = string.format("SURVIVED: %d", survivedWaves)

	local previousWave = currentWave

	currentWaveValue:GetPropertyChangedSignal("Value"):Connect(function()
		local newWave = currentWaveValue.Value

		if newWave > previousWave then
			-- Incrementar survived
			survivedWaves = newWave - 1

			task.delay(0.5, function()
				showWaveCompleted(previousWave)
			end)
		end

		updateWave(newWave, survivedWaves)
		previousWave = newWave
	end)

	if DEBUG then
		print("[UI] ✓ Wave counter conectado")
	end
else
	warn("[UI] ⚠️ No se encontró CurrentWave")
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
		print("[UI] ✓ Money counter tóxico conectado")
	end
end

if DEBUG then
	print("[UI] ✨ HUD Tóxico inicializado")
end
