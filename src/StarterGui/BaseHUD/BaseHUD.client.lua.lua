--!strict
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestBaseState = Remotes:WaitForChild("RequestBaseState")
local BaseStateChanged = Remotes:WaitForChild("BaseStateChanged")

-- Crear UI
local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
sg.Name = "BaseHUD"
sg.ResetOnSpawn = false

local frame = Instance.new("Frame", sg)
frame.Size = UDim2.new(0, 300, 0, 40)
frame.Position = UDim2.new(1, -320, 1, -70)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local bar = Instance.new("Frame", frame)
bar.Name = "Bar"
bar.Size = UDim2.new(1, -10, 1, -10)
bar.Position = UDim2.fromOffset(5, 5)
bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
bar.BorderSizePixel = 0
Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 6)

local label = Instance.new("TextLabel", frame)
label.Size = UDim2.new(1, 0, 1, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBold
label.TextSize = 18
label.TextColor3 = Color3.new(1,1,1)
label.Text = "HP: 100/100"

local repairBtn = Instance.new("TextButton", frame)
repairBtn.Size = UDim2.new(0, 80, 0, 30)
repairBtn.Position = UDim2.new(0, -90, 0, 5)
repairBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
repairBtn.TextColor3 = Color3.new(1,1,1)
repairBtn.Font = Enum.Font.GothamBold
repairBtn.TextSize = 14

local statsLabel = Instance.new("TextLabel", sg)
statsLabel.Size = UDim2.new(0, 200, 0, 30)
statsLabel.Position = UDim2.new(1, -220, 1, -110)
statsLabel.BackgroundTransparency = 0.5
statsLabel.BackgroundColor3 = Color3.fromRGB(20,20,20)
statsLabel.TextColor3 = Color3.new(1,1,1)
statsLabel.Font = Enum.Font.Gotham
statsLabel.TextSize = 14
statsLabel.Text = "Meteors survived: 0"

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
		repairBtn.Text = "? Full HP"
		repairBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	else
		repairBtn.Text = string.format("Repair\n$%d", cost)
		repairBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
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

	if pct > 0.7 then
		bar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	elseif pct > 0.3 then
		bar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
	else
		bar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end

	label.Text = string.format("HP: %d/%d", hp, max)
end

BaseStateChanged.OnClientEvent:Connect(update)

task.spawn(function()
	while true do
		update()
		task.wait(2)
	end
end)

update()