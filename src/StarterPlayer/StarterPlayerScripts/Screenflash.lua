--!strict
--[[
	SCREEN FLASH CLIENT - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Escucha el RemoteEvent "ScreenFlash" del servidor y aplica flashes
	de pantalla completa usando CameraController.

	CARACTERÃÂSTICAS:
	? Soporte para mÃÂºltiples colores (Red, Green, Yellow, White)
	? IntegraciÃÂ³n con CameraController
	? Mobile-safe (reduce intensidad automÃÂ¡ticamente)
	? ValidaciÃÂ³n de parÃÂ¡metros

	INSTALACIÃÂN:
	1. Copia este script a StarterPlayer.StarterPlayerScripts
	2. AsegÃÂºrate que CameraController.lua existe en Controllers/
	3. El RemoteEvent "ScreenFlash" se crea automÃÂ¡ticamente en EventManager

	USO DESDE SERVIDOR:
		local ScreenFlash = ReplicatedStorage.Remotes.ScreenFlash
		ScreenFlash:FireClient(player, "Red", 0.4, 0.3)

		ParÃÂ¡metros:
		- colorName: "Red", "Green", "Yellow", "White", "Blue"
		- intensity: 0.0 - 1.0 (opacidad mÃÂ¡xima)
		- duration: segundos (total de la animaciÃÂ³n)
--]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for CameraController
local CameraController = require(script.Parent.Controllers.CameraController)

-- Wait for RemoteEvent
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local ScreenFlash = RemotesFolder:WaitForChild("ScreenFlash") :: RemoteEvent

-------------------------------------------------------------------------
-- COLOR PRESETS
-------------------------------------------------------------------------

local COLOR_PRESETS = {
	Red = Color3.fromRGB(255, 0, 0),
	Green = Color3.fromRGB(0, 255, 0),
	Yellow = Color3.fromRGB(255, 255, 0),
	White = Color3.fromRGB(255, 255, 255),
	Blue = Color3.fromRGB(0, 100, 255),
	Orange = Color3.fromRGB(255, 150, 0),
	Purple = Color3.fromRGB(200, 0, 255),
}

-------------------------------------------------------------------------
-- EVENT HANDLER
-------------------------------------------------------------------------

ScreenFlash.OnClientEvent:Connect(function(colorName: string, intensity: number, duration: number)
	-- Validate parameters
	if typeof(colorName) ~= "string" then
		warn("[ScreenFlash] Invalid colorName type:", typeof(colorName))
		return
	end

	if typeof(intensity) ~= "number" then
		warn("[ScreenFlash] Invalid intensity type:", typeof(intensity))
		return
	end

	if typeof(duration) ~= "number" then
		warn("[ScreenFlash] Invalid duration type:", typeof(duration))
		return
	end

	-- Get color from preset or use Red as default
	local color = COLOR_PRESETS[colorName] or COLOR_PRESETS.Red

	-- Apply flash via CameraController
	CameraController:Flash(color, intensity, duration)
end)

print("[ScreenFlash] ? Listening for screen flash events")