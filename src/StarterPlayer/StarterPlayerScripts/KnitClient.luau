--!strict
--[[
	KnitClient Bootstrap

	Este script inicializa Knit en el cliente y registra todos los controllers.
	NO modifica la lógica actual del juego, solo prepara la infraestructura de Knit.

	FASE 1: Setup inicial - Knit corre en paralelo con tus scripts actuales.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Requerir Knit
local Knit = require(ReplicatedStorage.Knit)

-- Registrar todos los controllers de la carpeta Controllers
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local controllersFolder = playerScripts:FindFirstChild("Controllers")

if controllersFolder then
	for _, moduleScript in controllersFolder:GetChildren() do
		if moduleScript:IsA("ModuleScript") and moduleScript.Name:match("Controller$") then
			require(moduleScript)
		end
	end
else
	warn("[KnitClient] No se encontró carpeta 'Controllers'")
end

-- Iniciar Knit
Knit.Start():andThen(function()
	print("✅ [KnitClient] Started successfully")
end):catch(function(err)
	warn("❌ [KnitClient] Error during startup:", err)
end)
