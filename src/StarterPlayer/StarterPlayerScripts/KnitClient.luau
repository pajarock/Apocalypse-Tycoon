--!strict
--[[
	KnitClient Bootstrap

	Este script inicializa Knit en el cliente y registra todos los Knit controllers.

	ESTRUCTURA:
	- Controllers/       → Controllers antiguos (no Knit) - siguen funcionando normalmente
	- KnitControllers/   → Controllers de Knit - se cargan automáticamente aquí
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Requerir Knit
local Knit = require(ReplicatedStorage.Knit)

-- Registrar todos los Knit controllers de la carpeta KnitControllers
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
local knitControllersFolder = playerScripts:FindFirstChild("KnitControllers")

if knitControllersFolder then
	for _, moduleScript in knitControllersFolder:GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			require(moduleScript)
			print("🔵 [KnitClient] Loaded controller:", moduleScript.Name)
		end
	end
else
	warn("[KnitClient] No se encontró carpeta 'KnitControllers'")
end

-- Iniciar Knit
Knit.Start():andThen(function()
	print("✅ [KnitClient] Started successfully")
end):catch(function(err)
	warn("❌ [KnitClient] Error during startup:", err)
end)
