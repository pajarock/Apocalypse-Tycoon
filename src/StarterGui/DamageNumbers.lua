local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local DAMAGE_COLOR = Color3.fromRGB(255, 70, 70)
local CRIT_COLOR = Color3.fromRGB(255, 220, 80) -- Dorado más vibrante
local CRIT_THRESHOLD = 50 -- Daño crítico

game.ReplicatedStorage.Remotes.BaseDamaged.OnClientEvent:Connect(function(damage)
	local basePart = workspace.Bases:FindFirstChild(player.Name .. "_Base")
	if not basePart then return end

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 100)
	billboard.Adornee = basePart
	billboard.StudsOffset = Vector3.new(math.random(-3,3), 10 + math.random(), math.random(-3,3))
	billboard.AlwaysOnTop = true
	billboard.Parent = basePart

	-- Contenedor
	local frame = Instance.new("Frame")
	frame.BackgroundTransparency = 1
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Parent = billboard

	-- Texto principal con estilo según daño
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.Size = UDim2.fromOffset(200, 100)
	label.BackgroundTransparency = 1

	local isCrit = damage >= CRIT_THRESHOLD

	-- Estilo grafiti para críticos
	if isCrit then
		label.Font = Enum.Font.LuckiestGuy -- GRAFITI
		label.Text = "-" .. tostring(damage) .. "!"
		label.TextColor3 = CRIT_COLOR
		label.TextStrokeTransparency = 0.1 -- Borde más fuerte
		label.TextStrokeColor3 = Color3.fromRGB(100, 50, 0)
		label.Rotation = math.random(-8, 8) -- Rotación random grafiti
	else
		label.Font = Enum.Font.GothamBlack
		label.Text = "-" .. tostring(damage)
		label.TextColor3 = DAMAGE_COLOR
		label.TextStrokeTransparency = 0.3
		label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		label.Rotation = 0
	end

	label.TextScaled = true
	label.Parent = frame

	-- Efecto inicial - bounce más dramático para crits
	label.TextTransparency = 0
	label.TextSize = isCrit and 50 or 60
	label.TextScaled = false
	label.TextStrokeTransparency = isCrit and 0.1 or 0.3

	local targetSize = isCrit and 100 or 80 -- ? FIX: Operador ternario correcto (and/or, no :)
	local bounceStyle = isCrit and Enum.EasingStyle.Elastic or Enum.EasingStyle.Back

	local tweenIn = TweenService:Create(label, TweenInfo.new(0.15, bounceStyle, Enum.EasingDirection.Out), {
		TextSize = targetSize,
		TextTransparency = 0
	})
	tweenIn:Play()

	-- Movimiento ascendente y desvanecimiento
	task.spawn(function()
		local riseHeight = isCrit and 6 or 5
		local duration = isCrit and 1.2 or 1.0

		local moveUp = TweenService:Create(billboard, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			StudsOffset = billboard.StudsOffset + Vector3.new(0, riseHeight, 0)
		})
		local fadeOut = TweenService:Create(label, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})

		moveUp:Play()
		task.wait(0.2)
		fadeOut:Play()

		moveUp.Completed:Wait()
		billboard:Destroy()
	end)

	-- Efecto extra para críticos: flash dorado
	if isCrit then
		local flash = Instance.new("Frame")
		flash.Size = UDim2.fromScale(1.5, 1.5)
		flash.Position = UDim2.fromScale(0.5, 0.5)
		flash.AnchorPoint = Vector2.new(0.5, 0.5)
		flash.BackgroundColor3 = Color3.fromRGB(255, 220, 100)
		flash.BackgroundTransparency = 0.7
		flash.BorderSizePixel = 0
		flash.ZIndex = 0
		flash.Parent = frame

		local flashCorner = Instance.new("UICorner")
		flashCorner.CornerRadius = UDim.new(1, 0)
		flashCorner.Parent = flash

		TweenService:Create(flash, TweenInfo.new(0.4), {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(2, 2)
		}):Play()
	end
end)