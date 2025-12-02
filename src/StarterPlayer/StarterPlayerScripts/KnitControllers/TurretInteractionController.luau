--!strict
--[[
	TurretInteractionController - Sistema de interacción con torretas defensivas

	CARACTERÍSTICAS:
	- Handler centralizado de ProximityPromptService para torretas
	- Detecta prompts "ManageTurret" y abre UI de gestión
	- Comunica con TurretManagementUI module

	ARQUITECTURA:
	- Usa sistema nativo de ProximityPrompt (Roblox)
	- Handler centralizado para TODOS los prompts de torretas
	- No reimplementa detección de distancia (Roblox lo maneja)

	FLUJO DE INTERACCIÓN:
	1. Jugador presiona E cerca de torreta
	2. ProximityPromptService.PromptTriggered detecta evento
	3. Verifica que sea prompt de torreta (Name == "ManageTurret")
	4. Obtiene ObjectId del Attribute
	5. Abre TurretManagementUI con ObjectId

	AUTHOR: Turret Interaction System v1
	CLIENT-SIDE: Knit Controller
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ProximityPromptService = game:GetService("ProximityPromptService")
local Players = game:GetService("Players")
local Knit = require(ReplicatedStorage.Knit)

--[[────────────────────────────────────────────────────────────────────────
	CONTROLLER DEFINITION
────────────────────────────────────────────────────────────────────────]]

local TurretInteractionController = Knit.CreateController({
	Name = "TurretInteractionController",
})

-- Referencias
local player = Players.LocalPlayer
local TurretManagementUI = nil

--[[────────────────────────────────────────────────────────────────────────
	HELPER FUNCTIONS
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

--[[────────────────────────────────────────────────────────────────────────
	EVENT HANDLERS
────────────────────────────────────────────────────────────────────────]]

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
	LIFECYCLE METHODS
────────────────────────────────────────────────────────────────────────]]

function TurretInteractionController:KnitInit()
	print("[TurretInteractionController] Initializing...")

	-- Cargar TurretManagementUI module
	local success, result = pcall(function()
		return require(script.Parent.Parent:WaitForChild("TurretManagementUI"))
	end)

	if success then
		TurretManagementUI = result
		print("[TurretInteractionController] ✅ TurretManagementUI loaded")
	else
		warn("[TurretInteractionController] ❌ Failed to load TurretManagementUI:", result)
	end
end

function TurretInteractionController:KnitStart()
	print("[TurretInteractionController] Starting...")

	-- Conectar al ProximityPromptService (centralizado para TODOS los prompts)
	ProximityPromptService.PromptTriggered:Connect(onPromptTriggered)

	print("[TurretInteractionController] ✅ Listening for turret prompts")
end

--[[────────────────────────────────────────────────────────────────────────
	PUBLIC API (opcional, para testing)
────────────────────────────────────────────────────────────────────────]]

function TurretInteractionController:IsTurretPrompt(prompt: ProximityPrompt): boolean
	return isTurretPrompt(prompt)
end

function TurretInteractionController:GetTurretObjectId(prompt: ProximityPrompt): string?
	return getTurretObjectId(prompt)
end

return TurretInteractionController
