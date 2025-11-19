--!strict
--[[
	DebugController - Controller de prueba para FASE 1

	Este controller simple demuestra:
	- Cómo crear un Controller en Knit
	- Cómo comunicarse con Services del servidor
	- Lifecycle hooks (KnitStart)

	NO tiene lógica de juego real, solo es para probar que Knit funciona.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)

-- Crear el controller
local DebugController = Knit.CreateController({
	Name = "DebugController",
})

-- KnitStart: Se ejecuta cuando Knit.Start() completa
function DebugController:KnitStart()
	-- Obtener referencia al HelloService (servidor)
	local HelloService = Knit.GetService("HelloService")

	-- Llamar al método Ping del servidor
	local response = HelloService:Ping()

	-- Imprimir la respuesta en el cliente
	print("🔵 [DebugController] Response from server:", response)
end

return DebugController
