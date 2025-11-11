--!strict
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local Remotes = game.ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchase = Remotes:WaitForChild("RequestPurchase")

-- Detectar cuando el jugador toca un botón de upgrade
workspace.ChildAdded:Connect(function(child)
	if not child:IsA("Model") or not child:GetAttribute("UpgradeButton") then return end

	local upgradeId = child:GetAttribute("UpgradeId")
	local ownerId = child:GetAttribute("OwnerUserId")

	if ownerId ~= player.UserId then return end -- Solo tu base

	-- Crear ProximityPrompt
	local trigger = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")
	if not trigger then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Comprar"
	prompt.ObjectText = child.Name
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = trigger

	prompt.Triggered:Connect(function()
		RequestPurchase:FireServer(upgradeId)
	end)
end)