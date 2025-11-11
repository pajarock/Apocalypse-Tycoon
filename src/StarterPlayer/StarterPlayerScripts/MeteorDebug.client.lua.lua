--!strict
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")
local DebugSpawnMeteor = Remotes:WaitForChild("DebugSpawnMeteor")

UIS.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.M then
		DebugSpawnMeteor:FireServer()
	end
end)
