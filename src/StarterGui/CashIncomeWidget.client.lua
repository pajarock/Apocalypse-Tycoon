--!strict
--[[
	CASH & INCOME WIDGET - Apocalypse Tycoon
	------------------------------------------------------------------------

	Widget unificado al centro-superior que muestra:
	?? Cash actual | ? Income per second

	ESTILO: Grafiti urbano vibrante (matching con BaseHUD y Shop)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- Remotes para detectar IncomeBoost
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PowerUpActivated = Remotes:WaitForChild("PowerUpActivated", 10) :: RemoteEvent?
local PowerUpExpired = Remotes:WaitForChild("PowerUpExpired", 10) :: RemoteEvent?

-- Estado del IncomeBoost
local IncomeBoostActive = false

-- Crear ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "CashIncomeWidget"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.DisplayOrder = 10 -- ? FIX: Evitar superposiciÃ³n con otros widgets
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
frame.Rotation = -1.5 -- RotaciÃ³n sutil estilo urbano
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
cashLabel.TextColor3 = Color3.fromRGB(100, 255, 140) -- Verde neÃ³n
cashLabel.TextXAlignment = Enum.TextXAlignment.Left
cashLabel.Text = "?? $0"
cashLabel.TextStrokeTransparency = 0.3
cashLabel.TextStrokeColor3 = Color3.fromRGB(0, 50, 0)
cashLabel.ZIndex = 2
cashLabel.Rotation = -1 -- InclinaciÃ³n grafiti
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
incomeLabel.Text = "? 0/s"
incomeLabel.TextStrokeTransparency = 0.3
incomeLabel.TextStrokeColor3 = Color3.fromRGB(50, 25, 0)
incomeLabel.ZIndex = 2
incomeLabel.Rotation = -1 -- InclinaciÃ³n grafiti
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

-------------------------------------------------------------------------
-- DETECTAR INCOMEBOOST
-------------------------------------------------------------------------

if PowerUpActivated then
	PowerUpActivated.OnClientEvent:Connect(function(powerUpId: string, duration: number)
		if powerUpId == "IncomeBoost" then
			IncomeBoostActive = true
			print("[CashIncomeWidget] ?? IncomeBoost ACTIVO - Showing 2X")

			-- Cambiar color a dorado brillante
			incomeLabel.TextColor3 = Color3.fromRGB(255, 215, 0)

			-- Pulso Ã©pico
			local originalSize = incomeLabel.TextSize
			TweenService:Create(incomeLabel, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
				TextSize = originalSize + 8
			}):Play()

			task.wait(0.3)

			TweenService:Create(incomeLabel, TweenInfo.new(0.3, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
				TextSize = originalSize
			}):Play()

			-- ?? Animar nÃºmero de 1X ? 2X
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local incomeValue = leaderstats:FindFirstChild("IncomePerSec")
				if incomeValue then
					local baseIncome = incomeValue.Value
					animateNumber(displayedIncome, baseIncome * 2, 0.4, function(animatedValue)
						incomeLabel.Text = string.format("?? 2X ? %d/s", animatedValue)
					end)
					displayedIncome = baseIncome * 2
					lastIncome = baseIncome * 2
				end
			end
		end
	end)
end

if PowerUpExpired then
	PowerUpExpired.OnClientEvent:Connect(function(powerUpId: string)
		if powerUpId == "IncomeBoost" then
			IncomeBoostActive = false
			print("[CashIncomeWidget] ?? IncomeBoost EXPIRADO - Showing normal")

			-- Volver a color naranja/dorado normal
			incomeLabel.TextColor3 = Color3.fromRGB(255, 200, 80)

			-- ?? Animar nÃºmero de 2X ? 1X
			local leaderstats = player:FindFirstChild("leaderstats")
			if leaderstats then
				local incomeValue = leaderstats:FindFirstChild("IncomePerSec")
				if incomeValue then
					local baseIncome = incomeValue.Value
					animateNumber(displayedIncome, baseIncome, 0.4, function(animatedValue)
						incomeLabel.Text = string.format("? %d/s", animatedValue)
					end)
					displayedIncome = baseIncome
					lastIncome = baseIncome
				end
			end
		end
	end)
end

-- FunciÃ³n para formatear dinero
local function formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

-- AnimaciÃ³n de pulso cuando cambia el dinero
local lastCash = 0
local lastIncome = 0
local displayedIncome = 0 -- Para animaciÃ³n de contador

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

-- ?? AnimaciÃ³n de nÃºmeros subiendo rÃ¡pidamente
local function animateNumber(startValue: number, endValue: number, duration: number, callback: (number) -> ())
	local elapsed = 0
	local connection: RBXScriptConnection?

	connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
		elapsed += dt
		local alpha = math.min(elapsed / duration, 1)

		-- Easing suave (EaseOut)
		local easedAlpha = 1 - (1 - alpha) ^ 3
		local currentValue = startValue + (endValue - startValue) * easedAlpha

		callback(math.floor(currentValue))

		if alpha >= 1 then
			if connection then
				connection:Disconnect()
			end
		end
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
		cashLabel.Text = string.format("?? %s", formatMoney(newCash))

		-- Pulso si cambiÃ³ el dinero
		if newCash ~= lastCash then
			pulseAnimation(cashLabel)
			lastCash = newCash
		end
	end

	if incomeValue then
		local baseIncome = incomeValue.Value

		-- ?? CALCULAR INCOME REAL (multiplicado por IncomeBoost si estÃ¡ activo)
		local realIncome = baseIncome
		if IncomeBoostActive then
			realIncome = baseIncome * 2 -- 2X cuando IncomeBoost activo
		end

		-- Animar cambio de nÃºmero si es diferente
		if realIncome ~= lastIncome then
			pulseAnimation(incomeLabel)

			-- ?? CONTADOR RÃPIDO animado
			animateNumber(displayedIncome, realIncome, 0.3, function(animatedValue)
				if IncomeBoostActive then
					incomeLabel.Text = string.format("?? 2X ? %d/s", animatedValue)
				else
					incomeLabel.Text = string.format("? %d/s", animatedValue)
				end
			end)

			displayedIncome = realIncome
			lastIncome = realIncome
		else
			-- Actualizar texto sin animar (mantener formato correcto)
			if IncomeBoostActive then
				incomeLabel.Text = string.format("?? 2X ? %d/s", displayedIncome)
			else
				incomeLabel.Text = string.format("? %d/s", displayedIncome)
			end
		end
	end
end

-- AnimaciÃ³n de entrada
task.wait(0.3)
frame.Position = UDim2.new(0.5, -160, 0, -80) -- Fuera de pantalla arriba
frame:TweenPosition(
	UDim2.new(0.5, -160, 0, 20),
	Enum.EasingDirection.Out,
	Enum.EasingStyle.Bounce,
	0.8,
	true
)

-- Loop de actualizaciÃ³n (cada 0.5 segundos para mÃ¡s responsividad)
task.spawn(function()
	while true do
		update()
		task.wait(0.5)
	end
end)

update()

print("[CashIncomeWidget] ? Widget unificado inicializado con estilo grafiti + detecciÃ³n IncomeBoost")