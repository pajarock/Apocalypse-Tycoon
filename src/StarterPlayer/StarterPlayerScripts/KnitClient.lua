--!strict
--[[
	KnitClient Bootstrap

	Este script inicializa Knit en el cliente y registra todos los Knit controllers.

	ESTRUCTURA:
	- Controllers/       ? Controllers antiguos (no Knit) - siguen funcionando normalmente
	- KnitControllers/   ? Controllers de Knit - se cargan automáticamente aquí
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Requerir Knit
local Knit = require(ReplicatedStorage.Knit)

-- Registrar todos los Knit controllers de la carpeta KnitControllers
local playerScripts = Players.LocalPlayer:WaitForChild("PlayerScripts")
print("[KnitClient] Buscando KnitControllers en:", playerScripts:GetFullName())

local knitControllersFolder = playerScripts:FindFirstChild("KnitControllers")

if knitControllersFolder then
	print("[KnitClient] ? Carpeta KnitControllers encontrada")
	local controllerCount = 0
	for _, moduleScript in knitControllersFolder:GetChildren() do
		if moduleScript:IsA("ModuleScript") then
			print("?? [KnitClient] Cargando controller:", moduleScript.Name)
			local success, err = pcall(function()
				require(moduleScript)
			end)
			if success then
				controllerCount += 1
				print("? [KnitClient] Controller cargado:", moduleScript.Name)
			else
				warn("? [KnitClient] Error cargando", moduleScript.Name, ":", err)
			end
		end
	end
	print(string.format("[KnitClient] Total controllers cargados: %d", controllerCount))
else
	warn("? [KnitClient] No se encontró carpeta 'KnitControllers'")
	warn("[KnitClient] Estructura actual de PlayerScripts:")
	for _, child in playerScripts:GetChildren() do
		warn("  - " .. child.Name .. " (" .. child.ClassName .. ")")
	end
end

-- Iniciar Knit (versión simplificada sin Promises)
local success, err = pcall(function()
	Knit.Start()
end)

if not success then
	warn("? [KnitClient] Error during startup:", err)
end