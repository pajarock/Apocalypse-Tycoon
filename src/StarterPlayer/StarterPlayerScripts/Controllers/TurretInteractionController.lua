--[[
	TurretInteractionController.lua
	═══════════════════════════════════════════════════════════════════════

	Cliente controller para manejar interacción con torretas defensivas.

	RESPONSABILIDADES:
	- Escuchar ProximityPromptService.PromptTriggered
	- Detectar ProximityPrompts de torretas ("ManageTurret")
	- Obtener ObjectId del turret model
	- Abrir TurretManagementUI con los datos de la torreta

	ARQUITECTURA:
	- Handler centralizado para TODOS los ProximityPrompts de torretas
	- Usa sistema nativo de Roblox (no reinventa la rueda)
	- Comunica con TurretManagementUI para mostrar panel

	═══════════════════════════════════════════════════════════════════════
]]

local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer

-- Referencia al UI (se inicializará cuando esté disponible)
local TurretManagementUI = nil

--[[────────────────────────────────────────────────────────────────────────
	INITIALIZATION
────────────────────────────────────────────────────────────────────────]]

-- Esperar a que el UI module esté disponible
task.spawn(function()
	local PlayerGui = player:WaitForChild("PlayerGui")

	-- Buscar el módulo de UI (puede estar en PlayerScripts o como módulo)
	local success, result = pcall(function()
		return require(script.Parent.Parent:WaitForChild("TurretManagementUI"))
	end)

	if success then
		TurretManagementUI = result
		print("[TurretInteractionController] ✅ TurretManagementUI loaded")
	else
		warn("[TurretInteractionController] ❌ Failed to load TurretManagementUI:", result)
	end
end)

--[[────────────────────────────────────────────────────────────────────────
	PROXIMITY PROMPT HANDLER
────────────────────────────────────────────────────────────────────────]]

--[[
	Verifica si un ProximityPrompt es de una torreta.

	@param prompt - ProximityPrompt a verificar
	@return boolean - true si es torreta
]]
local function isTurretPrompt(prompt: ProximityPrompt): boolean
	return prompt.Name == "ManageTurret"
end

--[[
	Obtiene el ObjectId de una torreta desde su modelo.

	@param prompt - ProximityPrompt de la torreta
	@return string? - ObjectId o nil si no se encuentra
]]
local function getTurretObjectId(prompt: ProximityPrompt): string?
	-- El prompt está en el PrimaryPart del modelo
	local part = prompt.Parent
	if not part or not part:IsA("BasePart") then
		return nil
	end

	-- Obtener ObjectId del Attribute
	local objectId = part:GetAttribute("ObjectId")
	return objectId
end

--[[
	Maneja el evento de activación de ProximityPrompt.

	@param prompt - ProximityPrompt activado
	@param playerWhoTriggered - Jugador que activó el prompt
]]
local function onPromptTriggered(prompt: ProximityPrompt, playerWhoTriggered: Player)
	-- Solo procesar si es el jugador local
	if playerWhoTriggered ~= player then
		return
	end

	-- Verificar si es un prompt de torreta
	if not isTurretPrompt(prompt) then
		return
	end

	-- Obtener ObjectId
	local objectId = getTurretObjectId(prompt)
	if not objectId then
		warn("[TurretInteractionController] ❌ Cannot get ObjectId from turret prompt")
		return
	end

	print("[TurretInteractionController] 🎯 Turret prompt triggered:", objectId)

	-- Abrir UI si está disponible
	if TurretManagementUI then
		TurretManagementUI.OpenTurretUI(objectId)
	else
		warn("[TurretInteractionController] ❌ TurretManagementUI not loaded yet")
	end
end

--[[────────────────────────────────────────────────────────────────────────
	CONNECTIONS
────────────────────────────────────────────────────────────────────────]]

-- Conectar al ProximityPromptService (centralizado para TODOS los prompts)
ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

print("[TurretInteractionController] ✅ Initialized - Listening for turret prompts")

--[[────────────────────────────────────────────────────────────────────────
	MODULE EXPORT (opcional, para testing)
────────────────────────────────────────────────────────────────────────]]

local TurretInteractionController = {}

-- Exponer funciones para testing (opcional)
function TurretInteractionController.IsTurretPrompt(prompt: ProximityPrompt): boolean
	return isTurretPrompt(prompt)
end

function TurretInteractionController.GetTurretObjectId(prompt: ProximityPrompt): string?
	return getTurretObjectId(prompt)
end

return TurretInteractionController
