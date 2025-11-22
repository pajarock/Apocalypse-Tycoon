--!strict
--[[
	WAVE COUNTER UI - VERSIÃN ÃPICA
	-----------------------------------------------------------------------

	FEATURES:
	- Wave counter en esquina superior IZQUIERDA (no tapado)
	- Contador de dinero Ã©pico con animaciÃ³n
	- Mensaje "WAVE X COMPLETED!" en centro
	- DiseÃ±o moderno y llamativo

	INSTALACIÃN:
	1. Reemplazar WaveCounterUI.client.lua existente en StarterGui
	2. O crear nuevo LocalScript con este cÃ³digo
--]]

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-------------------------------------------------------------------------
-- CONFIG
-------------------------------------------------------------------------
local DEBUG = true

-------------------------------------------------------------------------
-- CREAR SCREENGUI PRINCIPAL
-------------------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.DisplayOrder = 10 -- Por encima del leaderboard
screenGui.Parent = playerGui

-------------------------------------------------------------------------
-- WAVE COUNTER (Superior Izquierda)
-------------------------------------------------------------------------

local waveFrame = Instance.new("Frame")
waveFrame.Name = "WaveFrame"
waveFrame.Size = UDim2.fromOffset(220, 80) -- MÃ¡s grande
waveFrame.Position = UDim2.new(0, 10, 0, 10) -- ? Superior IZQUIERDA
waveFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 18)
waveFrame.BackgroundTransparency = 0.05
waveFrame.BorderSizePixel = 0
waveFrame.Rotation = -1.5 -- RotaciÃ³n sutil estilo urbano
waveFrame.Parent = screenGui

local waveCorner = Instance.new("UICorner")
waveCorner.CornerRadius = UDim.new(0, 10)
waveCorner.Parent = waveFrame

local waveStroke = Instance.new("UIStroke")
waveStroke.Color = Color3.fromRGB(255, 170, 0)
waveStroke.Thickness = 4 -- MÃ¡s grueso
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
labelWave.Size = UDim2.fromScale(1, 0.3)
labelWave.Position = UDim2.fromScale(0, 0.08)
labelWave.BackgroundTransparency = 1
labelWave.Text = "WAVE"
labelWave.TextColor3 = Color3.fromRGB(255, 180, 20)
labelWave.TextScaled = true
labelWave.Font = Enum.Font.GothamBlack
labelWave.TextStrokeTransparency = 0.5
labelWave.Parent = waveFrame

-- Label nÃºmero en LuckiestGuy (ESTILO GRAFITI)
local labelNumber = Instance.new("TextLabel")
labelNumber.Name = "LabelNumber"
labelNumber.Size = UDim2.fromScale(1, 0.42)
labelNumber.Position = UDim2.fromScale(0, 0.28)
labelNumber.BackgroundTransparency = 1
labelNumber.Text = "1"
labelNumber.TextColor3 = Color3.new(1, 1, 1)
labelNumber.TextScaled = true
labelNumber.Font = Enum.Font.LuckiestGuy -- GRAFITI
labelNumber.TextStrokeTransparency = 0.3
labelNumber.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
labelNumber.Rotation = -2 -- InclinaciÃ³n grafiti
labelNumber.Parent = waveFrame

-- ? Label "Survived" (rondas sobrevividas)
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

-------------------------------------------------------------------------
-- ? ELIMINADO: CONTADOR DE DINERO (ahora en CashIncomeWidget centralizado)
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- MENSAJE "WAVE COMPLETED" (Centro Pantalla)
-------------------------------------------------------------------------

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

-- Texto principal en LuckiestGuy
local completedText = Instance.new("TextLabel")
completedText.Name = "Text"
completedText.Size = UDim2.fromScale(1, 0.6)
completedText.Position = UDim2.fromScale(0, 0.15)
completedText.BackgroundTransparency = 1
completedText.Text = "WAVE 1 COMPLETED!"
completedText.TextColor3 = Color3.fromRGB(255, 220, 50)
completedText.TextScaled = true
completedText.Font = Enum.Font.LuckiestGuy -- GRAFITI
completedText.TextStrokeTransparency = 0
completedText.TextStrokeColor3 = Color3.fromRGB(100, 50, 0)
completedText.Rotation = -3 -- InclinaciÃ³n grafiti
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

-------------------------------------------------------------------------
-- FUNCIONES DE ANIMACIÃN
-------------------------------------------------------------------------

-- ? ELIMINADO: formatMoney y animateMoneyChange (ahora en CashIncomeWidget)

local function playWavePulse()
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, true)
	TweenService:Create(waveFrame, tweenInfo, {
		Size = UDim2.fromOffset(240, 90) -- MÃ¡s grande el pulse
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
	completedText.Text = string.format("? WAVE %d COMPLETED! ?", waveNum)
	completedFrame.Visible = true
	completedFrame.Size = UDim2.fromOffset(0, 0)
	completedFrame.BackgroundTransparency = 1
	completedText.TextTransparency = 1
	completedSubtext.TextTransparency = 1

	-- AnimaciÃ³n de entrada
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
		print(("[WaveCounterUI] ?? Wave %d!"):format(newWave))
	end
end

-------------------------------------------------------------------------
-- ? ANIMACIONES ÃPICAS (VICTORIA / DERROTA)
-------------------------------------------------------------------------

-- Sonido de victoria
local function playVictorySound()
	local sound = Instance.new("Sound")
	sound.SoundId = "rbxassetid://6895079853" -- Sonido Ã©pico de victoria
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

-- ? ANIMACIÃN ÃPICA DE VICTORIA
local function playVictoryAnimation(waveNum: number, survived: number)
	if DEBUG then
		print(("[WaveCounterUI] ? VICTORIA - Wave %d"):format(waveNum))
	end

	-- Sonido
	playVictorySound()

	-- Bounce Ã©pico del widget
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

	-- ? Flash dorado en borde (3 pulsos)
	waveStroke.Color = Color3.fromRGB(255, 215, 0)
	waveStroke.Thickness = 5

	-- TweenInfo(tiempo, estilo, direcciÃ³n, repeticiones, reversa)
	local pulseInfo = TweenInfo.new(
		0.25,  -- DuraciÃ³n por pulso
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.InOut,
		2,  -- Repetir 2 veces (ida y vuelta = 1 pulso, asÃ­ que 2 repeticiones = 3 pulsos totales)
		true  -- Reversa (ida y vuelta)
	)

	TweenService:Create(waveStroke, pulseInfo, {
		Color = Color3.fromRGB(255, 170, 0),
		Thickness = 3
	}):Play()

	-- ? Flash en texto "WAVE" (3 pulsos)
	labelWave.TextColor3 = Color3.fromRGB(255, 215, 0)
	TweenService:Create(labelWave, pulseInfo, {
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

-- ?? ANIMACIÃN ÃPICA DE DERROTA
local function playDefeatAnimation(waveNum: number)
	if DEBUG then
		print(("[WaveCounterUI] ?? DERROTA - Wave %d"):format(waveNum))
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

-------------------------------------------------------------------------
-- SINCRONIZACIÃN CON SERVIDOR
-------------------------------------------------------------------------

-- Wave Counter
local currentWaveValue = ReplicatedStorage:WaitForChild("CurrentWave", 10)

if currentWaveValue and currentWaveValue:IsA("IntValue") then
	labelNumber.Text = tostring(currentWaveValue.Value)

	local previousWave = currentWaveValue.Value

	currentWaveValue:GetPropertyChangedSignal("Value"):Connect(function()
		local newWave = currentWaveValue.Value

		-- ? ARREGLADO: NO mostrar mensaje automÃ¡tico aquÃ­
		-- El servidor ya envÃ­a el mensaje a travÃ©s de EventNotifier
		-- Si mostramos aquÃ­ tambiÃ©n, sale duplicado

		--[[
		-- CÃDIGO ANTIGUO (CAUSABA DUPLICADOS):
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
		print("[WaveCounterUI] ? Wave counter conectado")
	end
else
	warn("[WaveCounterUI] ?? No se encontrÃ³ CurrentWave")
end

-- ? ELIMINADO: Money Counter (ahora en CashIncomeWidget centralizado)

-- ? Waves Survived Counter
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
			print("[WaveCounterUI] ? Waves survived counter conectado")
		end
	end
end

-------------------------------------------------------------------------
-- ? ESCUCHAR RESULTADOS ÃPICOS DEL SERVIDOR
-------------------------------------------------------------------------

local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
if remotes then
	local waveResultRemote = remotes:WaitForChild("WaveResult", 10)
	if waveResultRemote and waveResultRemote:IsA("RemoteEvent") then
		print("[WaveCounterUI] ? WaveResult remote ENCONTRADO y CONECTADO")

		waveResultRemote.OnClientEvent:Connect(function(data)
			print("[WaveCounterUI] ?? RECIBIDO evento WaveResult:", data)

			if typeof(data) ~= "table" then
				warn("[WaveCounterUI] ?? Data no es tabla:", typeof(data))
				return
			end

			local result = data.result
			local waveNum = data.waveNumber
			local survived = data.newSurvived or data.survivedCount

			print(("[WaveCounterUI] ?? Result: %s, Wave: %d, Survived: %s"):format(
				tostring(result), tostring(waveNum), tostring(survived)
				))

			if result == "victory" then
				-- ? VICTORIA ÃPICA
				print("[WaveCounterUI] ?? Reproduciendo animaciÃ³n de VICTORIA")
				local success, err = pcall(function()
					playVictoryAnimation(waveNum, survived)
				end)
				if not success then
					warn("[WaveCounterUI] ? Error en victoria animation:", err)
				end
			elseif result == "defeat" then
				-- ?? DERROTA ÃPICA
				print("[WaveCounterUI] ?? Reproduciendo animaciÃ³n de DERROTA")
				local success, err = pcall(function()
					playDefeatAnimation(waveNum)
				end)
				if not success then
					warn("[WaveCounterUI] ? Error en defeat animation:", err)
				end
			else
				warn("[WaveCounterUI] ?? Result desconocido:", result)
			end
		end)

		if DEBUG then
			print("[WaveCounterUI] ? WaveResult remote conectado (mensajes Ã©picos)")
		end
	else
		warn("[WaveCounterUI] ?? No se encontrÃ³ WaveResult remote")
	end
end

-------------------------------------------------------------------------

if DEBUG then
	print("[WaveCounterUI] ? HUD Ãpico inicializado")
end