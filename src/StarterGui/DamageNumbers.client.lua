local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local DAMAGE_COLOR = Color3.fromRGB(255, 70, 70)
local CRIT_COLOR = Color3.fromRGB(255, 200, 80)

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

	-- Texto principal
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Position = UDim2.new(0.5, 0, 0.5, 0)
	label.Size = UDim2.fromOffset(200, 100)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.Text = "-" .. tostring(damage)
	label.TextColor3 = damage >= 50 and CRIT_COLOR or DAMAGE_COLOR
	label.TextStrokeTransparency = 0.3
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextScaled = true
	label.Parent = frame

	-- Efecto inicial (pequeño rebote)
	label.TextTransparency = 0
	label.TextSize = 60
	label.TextScaled = false
	label.TextStrokeTransparency = 0.3

	local tweenIn = TweenService:Create(label, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 80,
		TextTransparency = 0
	})
	tweenIn:Play()

	-- Movimiento ascendente y desvanecimiento
	task.spawn(function()
		local moveUp = TweenService:Create(billboard, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			StudsOffset = billboard.StudsOffset + Vector3.new(0, 5, 0)
		})
		local fadeOut = TweenService:Create(label, TweenInfo.new(1, Enum.EasingStyle.Linear), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		})

		moveUp:Play()
		task.wait(0.2)
		fadeOut:Play()

		moveUp.Completed:Wait()
		billboard:Destroy()
	end)
end)
