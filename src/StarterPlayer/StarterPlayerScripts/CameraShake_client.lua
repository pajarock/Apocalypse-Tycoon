--!strict
--[[
	CAMERA SHAKE CLIENT - Apocalypse Tycoon
	-----------------------------------------------------------------------

	Script cliente que escucha el RemoteEvent "CameraShake" del servidor
	y aplica el efecto usando CameraController.

	INSTALACIÃÂN:
	1. Copia este script a StarterPlayer.StarterPlayerScripts
	2. Copia CameraController.lua a StarterPlayerScripts.Controllers
	3. AsegÃÂºrate que existe ReplicatedStorage.Remotes.CameraShake

	USO DESDE SERVIDOR:
		local CameraShake = ReplicatedStorage.Remotes.CameraShake
		CameraShake:FireClient(player, "Heavy", 0.5) -- intensity, duration
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Wait for CameraController
local CameraController = require(script.Parent.Controllers.CameraController)

-- Wait for RemoteEvent
local RemotesFolder = ReplicatedStorage:WaitForChild("Remotes") :: Folder
local CameraShake = RemotesFolder:WaitForChild("CameraShake") :: RemoteEvent

-------------------------------------------------------------------------
-- EVENT HANDLER
-------------------------------------------------------------------------

CameraShake.OnClientEvent:Connect(function(intensity: string, duration: number)
	-- Validate parameters
	if typeof(intensity) ~= "string" then
		warn("[CameraShake_Client] Invalid intensity type:", typeof(intensity))
		return
	end

	if typeof(duration) ~= "number" then
		warn("[CameraShake_Client] Invalid duration type:", typeof(duration))
		return
	end

	-- Apply shake
	CameraController:Shake(intensity, duration)
end)

print("[CameraShake_Client] ? Listening for camera shake events")