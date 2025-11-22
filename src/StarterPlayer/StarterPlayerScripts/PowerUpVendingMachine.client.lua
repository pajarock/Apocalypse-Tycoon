--!strict
--[[
	?? POWERUP VENDING MACHINE CLIENT
	-----------------------------------------------------------------------

	Maneja la interacciÃÂ³n con la mÃÂ¡quina expendedora de powerups.

	FEATURES:
	- ProximityPrompt para comprar powerups
	- ComunicaciÃÂ³n con servidor vÃÂ­a RemoteEvent
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

-- Escuchar todos los ProximityPrompts de mÃÂ¡quinas de powerups
ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, playerWhoTriggered: Player)
	if playerWhoTriggered ~= player then return end

	-- Verificar si es el prompt de la mÃÂ¡quina de powerups
	if prompt.Name == "PurchasePrompt" and prompt.Parent and prompt.Parent.Name == "Button" then
		-- Verificar que sea la mÃÂ¡quina del jugador (o permitir cualquiera)
		local machine = prompt.Parent.Parent
		if machine and machine.Name:match("^VendingMachine_") then
			-- Enviar request al servidor
			PurchasePowerUp:FireServer()

			print("[PowerUpVending] ?? Solicitando compra de powerup...")
		end
	end
end)

print("[PowerUpVending] ? Cliente inicializado")