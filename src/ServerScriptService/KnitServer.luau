--!strict
--[[
	KnitServer Bootstrap

	Este script inicializa Knit en el servidor y registra todos los servicios.
	NO modifica la lógica actual del juego, solo prepara la infraestructura de Knit.

	FASE 1: Setup inicial - Knit corre en paralelo con tus scripts actuales.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- Requerir Knit
local Knit = require(ReplicatedStorage.Knit)

-- Registrar todos los servicios de la carpeta Services
local servicesFolder = ServerScriptService:FindFirstChild("Services")
if servicesFolder then
	for _, moduleScript in servicesFolder:GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			require(moduleScript)
		end
	end
else
	warn("[KnitServer] No se encontró carpeta 'Services'")
end

-- Iniciar Knit
Knit.Start():andThen(function()
	print("✅ [KnitServer] Started successfully")
end):catch(function(err)
	warn("❌ [KnitServer] Error during startup:", err)
end)
