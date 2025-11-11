local Players = game:GetService("Players")
local player = Players.LocalPlayer

local sg = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
sg.Name = "EventNotifier"

local label = Instance.new("TextLabel", sg)
label.Size = UDim2.new(0, 600, 0, 100)
label.Position = UDim2.new(0.5, -300, 0.2, 0)
label.BackgroundTransparency = 1
label.Font = Enum.Font.GothamBlack
label.TextSize = 48
label.TextColor3 = Color3.fromRGB(255, 0, 0)
label.TextStrokeTransparency = 0
label.Text = ""
label.Visible = false

local function show(msg: string, duration: number?)
	label.Text = msg
	label.Visible = true
	task.wait(duration or 3)
	label.Visible = false
end

-- Ejemplo: llamar desde servidor
game.ReplicatedStorage.Remotes.ShowNotification.OnClientEvent:Connect(show)