--!strict
--[[
	?? POWERUP VENDING MACHINE CLIENT
	-----------------------------------------------------------------------

	Maneja la interacción con la máquina expendedora de powerups.

	FEATURES:
	- ProximityPrompt para comprar powerups
	- Comunicación con servidor vía RemoteEvent
	- Feedback visual y auditivo
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local PurchasePowerUp = Remotes:WaitForChild("PurchasePowerUp") :: RemoteEvent

-------------------------------------------------------------------------
-- MANEJO DE PROXIMITYP ROM PTS
-------------------------------------------------------------------------

-- Escuchar todos los ProximityPrompts de máquinas de powerups
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
	if playerWhoTriggered ~= player then return end

	-- Verificar si es el prompt de la máquina de powerups
	if prompt.Name == "PurchasePrompt" and prompt.Parent and prompt.Parent.Name == "Button" then
		-- Verificar que sea la máquina del jugador (o permitir cualquiera)
		local machine = prompt.Parent.Parent
		if machine and machine.Name:match("^VendingMachine_") then
			-- Enviar request al servidor
			PurchasePowerUp:FireServer()

			print("[PowerUpVending] ?? Solicitando compra de powerup...")
		end
	end
end)

print("[PowerUpVending] ? Cliente inicializado")