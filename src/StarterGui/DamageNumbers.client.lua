local Players = game:GetService("Players")
local player = Players.LocalPlayer

game.ReplicatedStorage.Remotes.BaseDamaged.OnClientEvent:Connect(function(damage)
	local camera = workspace.CurrentCamera
	local basePart = workspace.Bases:FindFirstChild(player.Name.."_Base")
	if not basePart then return end

	local label = Instance.new("TextLabel")
	label.Text = "-"..tostring(damage)
	label.TextColor3 = Color3.fromRGB(255, 50, 50)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 48
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromOffset(200, 100)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.fromOffset(200, 100)
	billboard.Adornee = basePart
	billboard.StudsOffset = Vector3.new(math.random(-5,5), 10, math.random(-5,5))
	billboard.AlwaysOnTop = true
	billboard.Parent = basePart
	label.Parent = billboard

	-- AnimaciÃÂ³n
	task.spawn(function()
		for i = 1, 20 do
			billboard.StudsOffset += Vector3.new(0, 0.2, 0)
			label.TextTransparency = i/20
			task.wait(0.05)
		end
		billboard:Destroy()
	end)
end)