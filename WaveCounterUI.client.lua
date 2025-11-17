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
labelNumber.Size = UDim2.fromScale(1, 0.4)
labelNumber.Position = UDim2.fromScale(0, 0.3)
labelNumber.BackgroundTransparency = 1
labelNumber.Text = "1"
labelNumber.TextColor3 = Color3.new(1, 1, 1)
labelNumber.TextScaled = true
labelNumber.Font = Enum.Font.GothamBlack
labelNumber.TextStrokeTransparency = 0.5
labelNumber.Parent = waveFrame

-- ✅ Label "Survived" (rondas sobrevividas)
local labelSurvived = Instance.new("TextLabel")
labelSurvived.Name = "LabelSurvived"
labelSurvived.Size = UDim2.fromScale(1, 0.22)
labelSurvived.Position = UDim2.fromScale(0, 0.73)
labelSurvived.BackgroundTransparency = 1
labelSurvived.Text = "Survived: 0"
labelSurvived.TextColor3 = Color3.fromRGB(150, 150, 150)
labelSurvived.TextScaled = true
labelSurvived.Font = Enum.Font.Gotham
labelSurvived.TextStrokeTransparency = 0.8
labelSurvived.Parent = waveFrame

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
-- 🎁 NOTIFICACIONES ÉPICAS DE RECOMPENSAS (Grande y visible)
--═══════════════════════════════════════════════════════════════════════

local rewardFrame = Instance.new("Frame")
rewardFrame.Name = "EpicRewardFrame"
rewardFrame.Size = UDim2.fromOffset(600, 200)
rewardFrame.Position = UDim2.fromScale(0.5, 0.3)
rewardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
rewardFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
rewardFrame.BackgroundTransparency = 0.2
rewardFrame.BorderSizePixel = 0
rewardFrame.Visible = false
rewardFrame.ZIndex = 200
rewardFrame.Parent = screenGui

local rewardCorner = Instance.new("UICorner")
rewardCorner.CornerRadius = UDim.new(0, 20)
rewardCorner.Parent = rewardFrame

local rewardStroke = Instance.new("UIStroke")
rewardStroke.Color = Color3.fromRGB(255, 215, 0)
rewardStroke.Thickness = 6
rewardStroke.Parent = rewardFrame

local rewardGlow = Instance.new("UIGradient")
rewardGlow.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 215, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 100)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 215, 0))
}
rewardGlow.Rotation = 90
rewardGlow.Parent = rewardStroke

-- Texto principal de recompensa
local rewardText = Instance.new("TextLabel")
rewardText.Name = "RewardText"
rewardText.Size = UDim2.fromScale(1, 0.5)
rewardText.Position = UDim2.fromScale(0, 0.1)
rewardText.BackgroundTransparency = 1
rewardText.Text = "💰 REWARD!"
rewardText.TextColor3 = Color3.fromRGB(255, 215, 0)
rewardText.TextScaled = true
rewardText.Font = Enum.Font.GothamBlack
rewardText.TextStrokeTransparency = 0
rewardText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rewardText.ZIndex = 201
rewardText.Parent = rewardFrame

-- Subtexto de detalles
local rewardDetails = Instance.new("TextLabel")
rewardDetails.Name = "Details"
rewardDetails.Size = UDim2.fromScale(1, 0.3)
rewardDetails.Position = UDim2.fromScale(0, 0.65)
rewardDetails.BackgroundTransparency = 1
rewardDetails.Text = "+$500 | +100 HP"
rewardDetails.TextColor3 = Color3.fromRGB(100, 255, 100)
rewardDetails.TextScaled = true
rewardDetails.Font = Enum.Font.GothamBold
rewardDetails.TextStrokeTransparency = 0.5
rewardDetails.ZIndex = 201
rewardDetails.Parent = rewardFrame

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
-- ✨ FUNCIÓN PARA MOSTRAR RECOMPENSA ÉPICA
--═══════════════════════════════════════════════════════════════════════

local function showEpicReward(title: string, money: number?, hp: number?)
	if DEBUG then
		print(("[WaveCounterUI] 🎁 Mostrando recompensa épica: %s | $%s | HP:%s"):format(
			title, tostring(money), tostring(hp)
		))
	end

	-- Configurar textos
	rewardText.Text = title

	local details = {}
	if money and money > 0 then
		table.insert(details, string.format("+$%d", money))
	end
	if hp and hp > 0 then
		table.insert(details, string.format("+%d HP", hp))
	end
	rewardDetails.Text = table.concat(details, " | ")

	-- Mostrar con animación
	rewardFrame.Visible = true
	rewardFrame.Size = UDim2.fromOffset(0, 0)
	rewardFrame.BackgroundTransparency = 1
	rewardText.TextTransparency = 1
	rewardDetails.TextTransparency = 1
	rewardStroke.Transparency = 1

	-- Animación de entrada (rebote épico)
	local tweenIn = TweenService:Create(rewardFrame, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(600, 200),
		BackgroundTransparency = 0.2
	})

	local tweenStroke = TweenService:Create(rewardStroke, TweenInfo.new(0.4), {
		Transparency = 0
	})

	local tweenText = TweenService:Create(rewardText, TweenInfo.new(0.5), {
		TextTransparency = 0
	})

	local tweenDetails = TweenService:Create(rewardDetails, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, 0.2), {
		TextTransparency = 0
	})

	tweenIn:Play()
	tweenStroke:Play()
	tweenText:Play()
	tweenDetails:Play()

	-- Animación de pulso del borde
	task.spawn(function()
		for i = 1, 3 do
			task.wait(0.3)
			local pulse = TweenService:Create(rewardStroke, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
				Thickness = 8
			})
			pulse:Play()
			pulse.Completed:Wait()

			local pulseBack = TweenService:Create(rewardStroke, TweenInfo.new(0.3), {
				Thickness = 6
			})
			pulseBack:Play()
			pulseBack.Completed:Wait()
		end
	end)

	-- Ocultar después de 4 segundos
	task.delay(4, function()
		local tweenOut = TweenService:Create(rewardFrame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		})

		local tweenTextOut = TweenService:Create(rewardText, TweenInfo.new(0.5), {
			TextTransparency = 1
		})

		local tweenDetailsOut = TweenService:Create(rewardDetails, TweenInfo.new(0.5), {
			TextTransparency = 1
		})

		local tweenStrokeOut = TweenService:Create(rewardStroke, TweenInfo.new(0.5), {
			Transparency = 1
		})

		tweenOut:Play()
		tweenTextOut:Play()
		tweenDetailsOut:Play()
		tweenStrokeOut:Play()

		tweenOut.Completed:Connect(function()
			rewardFrame.Visible = false
		end)
	end)
end

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
-- ✅ ANIMACIONES ÉPICAS (VICTORIA / DERROTA)
--═══════════════════════════════════════════════════════════════════════

-- Sonido de victoria
local function playVictorySound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6895079853" -- Sonido épico de victoria
	sound.Volume = 0.7
	sound.Parent = game.SoundService
	sound:Play()
	game.Debris:AddItem(sound, 3)
end

-- Sonido de derrota
local function playDefeatSound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://9114397505" -- Sonido grave de derrota
	sound.Volume = 0.6
	sound.Parent = game.SoundService
	sound:Play()
	game.Debris:AddItem(sound, 3)
end

-- ✨ ANIMACIÓN ÉPICA DE VICTORIA
local function playVictoryAnimation(waveNum: number, survived: number)
	if DEBUG then
		print(("[WaveCounterUI] ✨ VICTORIA - Wave %d"):format(waveNum))
	end

	-- Sonido
	playVictorySound()

	-- Bounce épico del widget
	local originalSize = waveFrame.Size
	local bounceTween = TweenService:Create(
		waveFrame,
		TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(240, 90) }
	)
	bounceTween:Play()
	bounceTween.Completed:Connect(function()
		TweenService:Create(
			waveFrame,
			TweenInfo.new(0.2, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
			{ Size = originalSize }
		):Play()
	end)

	-- Flash dorado en borde
	waveStroke.Color = Color3.fromRGB(255, 215, 0)
	waveStroke.Thickness = 5
	TweenService:Create(waveStroke, TweenInfo.new(0.8), {
		Color = Color3.fromRGB(255, 170, 0),
		Thickness = 3
	}):Play()

	-- Flash en texto "WAVE"
	labelWave.TextColor3 = Color3.fromRGB(255, 215, 0)
	TweenService:Create(labelWave, TweenInfo.new(0.6), {
		TextColor3 = Color3.fromRGB(255, 170, 0)
	}):Play()

	-- "SURVIVED!" temporal
	local tempLabel = Instance.new("TextLabel")
	tempLabel.Size = UDim2.fromScale(1, 0.3)
	tempLabel.Position = UDim2.fromScale(0, 0.35)
	tempLabel.BackgroundTransparency = 1
	tempLabel.Text = "SURVIVED!"
	tempLabel.TextColor3 = Color3.fromRGB(85, 255, 127)
	tempLabel.TextScaled = true
	tempLabel.Font = Enum.Font.GothamBlack
	tempLabel.TextStrokeTransparency = 0
	tempLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tempLabel.TextTransparency = 1
	tempLabel.ZIndex = 100
	tempLabel.Parent = waveFrame

	-- Aparecer y desaparecer
	TweenService:Create(tempLabel, TweenInfo.new(0.2), {
		TextTransparency = 0
	}):Play()

	task.delay(0.8, function()
		TweenService:Create(tempLabel, TweenInfo.new(0.3), {
			TextTransparency = 1
		}):Play()
		task.delay(0.3, function()
			tempLabel:Destroy()
		end)
	end)
end

-- 💀 ANIMACIÓN ÉPICA DE DERROTA
local function playDefeatAnimation(waveNum: number)
	if DEBUG then
		print(("[WaveCounterUI] 💀 DERROTA - Wave %d"):format(waveNum))
	end

	-- Sonido
	playDefeatSound()

	-- Shake violento del widget
	local originalPos = waveFrame.Position
	local shakeIntensity = 8
	local shakeDuration = 0.5

	task.spawn(function()
		local startTime = tick()
		while tick() - startTime < shakeDuration do
			local progress = (tick() - startTime) / shakeDuration
			local intensity = shakeIntensity * (1 - progress)
			local offsetX = (math.random() - 0.5) * intensity
			local offsetY = (math.random() - 0.5) * intensity
			waveFrame.Position = UDim2.new(
				originalPos.X.Scale,
				originalPos.X.Offset + offsetX,
				originalPos.Y.Scale,
				originalPos.Y.Offset + offsetY
			)
			task.wait()
		end
		waveFrame.Position = originalPos
	end)

	-- Flash rojo en borde
	waveStroke.Color = Color3.fromRGB(220, 30, 30)
	waveStroke.Thickness = 5
	TweenService:Create(waveStroke, TweenInfo.new(0.8), {
		Color = Color3.fromRGB(255, 170, 0),
		Thickness = 3
	}):Play()

	-- Survived parpadea rojo
	labelSurvived.TextColor3 = Color3.fromRGB(255, 50, 50)
	TweenService:Create(labelSurvived, TweenInfo.new(0.8), {
		TextColor3 = Color3.fromRGB(150, 150, 150)
	}):Play()

	-- "FAILED!" temporal
	local tempLabel = Instance.new("TextLabel")
	tempLabel.Size = UDim2.fromScale(1, 0.3)
	tempLabel.Position = UDim2.fromScale(0, 0.35)
	tempLabel.BackgroundTransparency = 1
	tempLabel.Text = "FAILED!"
	tempLabel.TextColor3 = Color3.fromRGB(220, 30, 30)
	tempLabel.TextScaled = true
	tempLabel.Font = Enum.Font.GothamBlack
	tempLabel.TextStrokeTransparency = 0
	tempLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	tempLabel.TextTransparency = 1
	tempLabel.ZIndex = 100
	tempLabel.Parent = waveFrame

	-- Aparecer y desaparecer
	TweenService:Create(tempLabel, TweenInfo.new(0.2), {
		TextTransparency = 0
	}):Play()

	task.delay(0.8, function()
		TweenService:Create(tempLabel, TweenInfo.new(0.3), {
			TextTransparency = 1
		}):Play()
		task.delay(0.3, function()
			tempLabel:Destroy()
		end)
	end)
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

-- ✅ Waves Survived Counter
local stats = player:WaitForChild("Stats", 10)
if stats then
	local meteorsSurvived = stats:WaitForChild("MeteorsSurvived", 10)
	if meteorsSurvived then
		-- Actualizar inicial
		labelSurvived.Text = string.format("Survived: %d", meteorsSurvived.Value)

		-- Actualizar cuando cambie
		meteorsSurvived:GetPropertyChangedSignal("Value"):Connect(function()
			labelSurvived.Text = string.format("Survived: %d", meteorsSurvived.Value)

			-- Flash cuando aumenta
			labelSurvived.TextColor3 = Color3.fromRGB(85, 255, 127)
			TweenService:Create(labelSurvived, TweenInfo.new(0.5), {
				TextColor3 = Color3.fromRGB(150, 150, 150)
			}):Play()
		end)

		if DEBUG then
			print("[WaveCounterUI] ✓ Waves survived counter conectado")
		end
	end
end

--═══════════════════════════════════════════════════════════════════════
-- ✅ ESCUCHAR RESULTADOS ÉPICOS DEL SERVIDOR
--═══════════════════════════════════════════════════════════════════════

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if remotes then
	local waveResultRemote = remotes:WaitForChild("WaveResult", 10)
	if waveResultRemote and waveResultRemote:IsA("RemoteEvent") then
		print("[WaveCounterUI] ✅ WaveResult remote ENCONTRADO y CONECTADO")

		waveResultRemote.OnClientEvent:Connect(function(data)
			print("[WaveCounterUI] 📥 RECIBIDO evento WaveResult:", data)

			if typeof(data) ~= "table" then
				warn("[WaveCounterUI] ⚠️ Data no es tabla:", typeof(data))
				return
			end

			local result = data.result
			local waveNum = data.waveNumber
			local survived = data.newSurvived or data.survivedCount

			print(("[WaveCounterUI] 📊 Result: %s, Wave: %d, Survived: %s"):format(
				tostring(result), tostring(waveNum), tostring(survived)
			))

			if result == "victory" then
				-- ✨ VICTORIA ÉPICA
				print("[WaveCounterUI] 🎉 Reproduciendo animación de VICTORIA")
				local success, err = pcall(function()
					playVictoryAnimation(waveNum, survived)
				end)
				if not success then
					warn("[WaveCounterUI] ❌ Error en victoria animation:", err)
				end
			elseif result == "defeat" then
				-- 💀 DERROTA ÉPICA
				print("[WaveCounterUI] 💀 Reproduciendo animación de DERROTA")
				local success, err = pcall(function()
					playDefeatAnimation(waveNum)
				end)
				if not success then
					warn("[WaveCounterUI] ❌ Error en defeat animation:", err)
				end
			else
				warn("[WaveCounterUI] ⚠️ Result desconocido:", result)
			end
		end)

		if DEBUG then
			print("[WaveCounterUI] ✓ WaveResult remote conectado (mensajes épicos)")
		end
	else
		warn("[WaveCounterUI] ⚠️ No se encontró WaveResult remote")
	end
end

--═══════════════════════════════════════════════════════════════════════
-- 🎁 ESCUCHAR NOTIFICACIONES DE RECOMPENSAS
--═══════════════════════════════════════════════════════════════════════

local showNotificationRemote = remotes:FindFirstChild("ShowNotification")
if showNotificationRemote and showNotificationRemote:IsA("RemoteEvent") then
	showNotificationRemote.OnClientEvent:Connect(function(message: string, duration: number?)
		if DEBUG then
			print(("[WaveCounterUI] 📢 Notificación recibida: %s"):format(message))
		end

		-- Detectar si es una notificación de recompensa
		if message:match("BOSS DEFEATED") or message:match("MINI%-BOSS DEFEATED") or message:match("Wave %d+ Survived") then
			-- Extraer información de la notificación
			local money = tonumber(message:match("%+%$(%d+)")) or 0
			local hp = message:match("Full HP") and 100 or 0

			-- Determinar título
			local title = "🎉 WAVE SURVIVED!"
			if message:match("BOSS DEFEATED") then
				title = "💀 BOSS DEFEATED!"
			elseif message:match("MINI%-BOSS DEFEATED") then
				title = "💀 MINI-BOSS DEFEATED!"
			end

			-- Mostrar recompensa épica
			showEpicReward(title, money, hp)
		end
	end)

	if DEBUG then
		print("[WaveCounterUI] ✓ Listener de recompensas conectado")
	end
end

--═══════════════════════════════════════════════════════════════════════

if DEBUG then
	print("[WaveCounterUI] ✓ HUD Épico inicializado")
end
