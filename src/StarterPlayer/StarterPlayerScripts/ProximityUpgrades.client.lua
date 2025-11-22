--!strict
--[[
	PROXIMITY UPGRADES CLIENT
	Sistema de ProximityPrompts en botones físicos
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction

local processedButtons: {[Instance]: boolean} = {}

-------------------------------------------------------------------------
-- CREAR PROXIMITY PROMPT
-------------------------------------------------------------------------
local function createProximityPrompt(buttonModel: Model)
	if processedButtons[buttonModel] then return end
	processedButtons[buttonModel] = true

	local upgradeId = buttonModel:GetAttribute("UpgradeId")
	local ownerId = buttonModel:GetAttribute("OwnerUserId")

	if ownerId ~= player.UserId then return end
	if not upgradeId or typeof(upgradeId) ~= "string" then return end

	local trigger = buttonModel.PrimaryPart or buttonModel:FindFirstChildWhichIsA("BasePart")
	if not trigger then
		warn("[ProximityUpgrades] No se encontró BasePart en", buttonModel.Name)
		return
	end

	if trigger:FindFirstChildOfClass("ProximityPrompt") then return end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Comprar Upgrade"
	prompt.ObjectText = buttonModel.Name:gsub("Button_", "")
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.HoldDuration = 0
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = trigger

	local function updatePromptText()
		local ok, state = pcall(function()
			return RequestState:InvokeServer()
		end)

		if ok and state and state.UpgradesInfo then
			local upgradeInfo = state.UpgradesInfo[upgradeId]
			if upgradeInfo then
				local price = upgradeInfo.Price or 0
				local count = upgradeInfo.Count or 0
				local maxCount = upgradeInfo.MaxCount

				local priceStr = "$" .. tostring(price)
				if price >= 1000000 then
					priceStr = string.format("$%.1fM", price / 1000000)
				elseif price >= 1000 then
					priceStr = string.format("$%.1fK", price / 1000)
				end

				if maxCount and count >= maxCount then
					prompt.ObjectText = string.format("%s [MAX LVL %d]", upgradeInfo.Title or upgradeId, count)
					prompt.Enabled = false
				else
					prompt.ObjectText = string.format("%s (%s) [LVL %d]", 
						upgradeInfo.Title or upgradeId, 
						priceStr,
						count
					)
					prompt.Enabled = true
				end
			end
		end
	end

	updatePromptText()

	task.spawn(function()
		while buttonModel.Parent and trigger.Parent do
			task.wait(2)
			updatePromptText()
		end
	end)

	prompt.Triggered:Connect(function()
		RequestPurchase:FireServer(upgradeId)

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://5217846733"
		sound.Volume = 0.5
		sound.Parent = workspace
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)

		task.wait(0.1)
		updatePromptText()
	end)

	task.spawn(function()
		local base = buttonModel:FindFirstChild("Base")
		if not base or not base:IsA("BasePart") then return end

		local originalColor = base.Color
		while buttonModel.Parent and base.Parent do
			base.Color = Color3.fromRGB(120, 255, 120)
			task.wait(1)
			base.Color = originalColor
			task.wait(1)
		end
	end)

	print(("[ProximityUpgrades] Prompt creado para %s"):format(upgradeId))
end

-------------------------------------------------------------------------
-- DETECTAR BOTONES
-------------------------------------------------------------------------
local function scanExistingButtons()
	local bases = workspace:WaitForChild("Bases", 10)
	if not bases then return end

	for _, child in ipairs(bases:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("UpgradeButton") then
			createProximityPrompt(child)
		end
	end
end

local function watchForNewButtons()
	local bases = workspace:WaitForChild("Bases", 10)
	if not bases then return end

	bases.ChildAdded:Connect(function(child)
		task.wait()

		if child:IsA("Model") and child:GetAttribute("UpgradeButton") then
			createProximityPrompt(child)
		end
	end)
end

-------------------------------------------------------------------------
-- INICIALIZACIÓN
-------------------------------------------------------------------------
player.CharacterAdded:Wait()
task.wait(1)

scanExistingButtons()
watchForNewButtons()

print("[ProximityUpgrades] Sistema inicializado")