--!strict
--[[
	HelloService - Servicio de prueba para FASE 1

	Este servicio simple demuestra:
	- Cómo crear un Service en Knit
	- Cómo exponer métodos al cliente
	- Lifecycle hooks (KnitStart)

	NO tiene lógica de juego real, solo es para probar que Knit funciona.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)

-- Crear el servicio
local HelloService = Knit.CreateService({
	Name = "HelloService",
	Client = {}, -- Métodos expuestos al cliente
})

-- KnitStart: Se ejecuta cuando Knit.Start() completa
function HelloService:KnitStart()
	print("✅ [HelloService] Ready")
end

-- Método expuesto al cliente
function HelloService.Client:Ping(player: Player): string
	return "Hello from Knit, " .. player.Name .. "!"
end

-- También podemos tener métodos privados (solo servidor)
function HelloService:GetServerTime(): number
	return os.time()
end

return HelloService
