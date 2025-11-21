--!strict
--[[
	UpgradeButtonHandler - Cliente

	PROPÓSITO:
	- Maneja los clicks en los botones de upgrade de generadores
	- Detecta cuando se crean nuevos generadores con botones de upgrade
	- Comunica al servidor vía RemoteEvent para ejecutar el upgrade

	ARQUITECTURA:
	- LocalScript permanente en StarterPlayerScripts
	- El servidor crea el UI (billboard + botón)
	- Este script conecta los eventos del lado del cliente
	- Usa RemoteEvent para comunicarse con el servidor

	RAZÓN:
	- No se puede crear LocalScript con Source en runtime (restricción de Roblox)
	- Los eventos MouseButton1Click solo funcionan del lado del cliente
	- Necesitamos un script permanente que escuche nuevos generadores
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- Esperar a que el RemoteEvent exista
local upgradeRemote = ReplicatedStorage:WaitForChild("UpgradeGeneratorRemote", 10)
if not upgradeRemote then
	warn("[UpgradeButtonHandler] ❌ RemoteEvent 'UpgradeGeneratorRemote' not found!")
	return
end

print("[UpgradeButtonHandler] ✅ RemoteEvent found - listening for upgrade buttons")

-- Tabla para trackear botones ya conectados (evitar duplicados)
local connectedButtons = {}

--[[────────────────────────────────────────────────────────────────────────
	FUNCIÓN: Conectar botón de upgrade
────────────────────────────────────────────────────────────────────────]]
local function connectUpgradeButton(button: TextButton, mainPart: BasePart)
	-- Evitar conectar el mismo botón dos veces
	if connectedButtons[button] then
		return
	end

	-- Obtener objectId del modelo
	local objectIdValue = mainPart:FindFirstChild("ObjectId")
	if not objectIdValue then
		warn("[UpgradeButtonHandler] ❌ ObjectId not found in model!")
		return
	end

	local objectId = objectIdValue.Value

	-- Conectar evento de click
	button.MouseButton1Click:Connect(function()
		print("[UpgradeButtonHandler] 🎯 Upgrade button clicked for:", objectId)

		-- Verificar que el objectId todavía existe (el generator no fue destruido)
		local currentObjectIdValue = mainPart:FindFirstChild("ObjectId")
		if not currentObjectIdValue then
			warn("[UpgradeButtonHandler] ❌ Generator was destroyed!")
			return
		end

		-- Llamar al servidor
		upgradeRemote:FireServer(currentObjectIdValue.Value)
	end)

	-- Marcar como conectado
	connectedButtons[button] = true
	print("[UpgradeButtonHandler] ✅ Upgrade button connected for:", objectId)

	-- Limpiar cuando el botón se destruya
	button.Destroying:Connect(function()
		connectedButtons[button] = nil
	end)
end

--[[────────────────────────────────────────────────────────────────────────
	FUNCIÓN: Buscar botones en un modelo
────────────────────────────────────────────────────────────────────────]]
local function scanModelForUpgradeButtons(model: Model)
	-- Buscar MainPart
	local mainPart = model:FindFirstChild("MainPart")
	if not mainPart or not mainPart:IsA("BasePart") then
		return
	end

	-- Buscar StatsBillboard
	local billboard = mainPart:FindFirstChild("StatsBillboard")
	if not billboard or not billboard:IsA("BillboardGui") then
		return
	end

	-- Buscar Frame
	local frame = billboard:FindFirstChild("Frame")
	if not frame or not frame:IsA("Frame") then
		return
	end

	-- Buscar UpgradeButton
	local upgradeButton = frame:FindFirstChild("UpgradeButton")
	if not upgradeButton or not upgradeButton:IsA("TextButton") then
		return
	end

	-- Conectar el botón
	connectUpgradeButton(upgradeButton, mainPart)
end

--[[────────────────────────────────────────────────────────────────────────
	INICIALIZACIÓN: Escanear generadores existentes
────────────────────────────────────────────────────────────────────────]]
local function scanExistingGenerators()
	-- Buscar todos los modelos en Workspace que puedan ser generadores
	for _, obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and obj.Name:match("Generator") then
			scanModelForUpgradeButtons(obj)
		end
	end
end

--[[────────────────────────────────────────────────────────────────────────
	LISTENER: Detectar nuevos generadores
────────────────────────────────────────────────────────────────────────]]
Workspace.DescendantAdded:Connect(function(obj)
	-- Esperar un frame para que el modelo se inicialice completamente
	task.wait()

	-- Si es un BillboardGui llamado "StatsBillboard", buscar el botón
	if obj:IsA("BillboardGui") and obj.Name == "StatsBillboard" then
		local mainPart = obj.Parent
		if mainPart and mainPart:IsA("BasePart") then
			local frame = obj:FindFirstChild("Frame")
			if frame and frame:IsA("Frame") then
				local upgradeButton = frame:FindFirstChild("UpgradeButton")
				if upgradeButton and upgradeButton:IsA("TextButton") then
					connectUpgradeButton(upgradeButton, mainPart)
				end
			end
		end
	end

	-- Si es un modelo de generator, escanearlo
	if obj:IsA("Model") and obj.Name:match("Generator") then
		task.wait(0.1) -- Esperar a que se complete la inicialización
		scanModelForUpgradeButtons(obj)
	end
end)

-- Escanear generadores que ya existen
scanExistingGenerators()

print("[UpgradeButtonHandler] 🚀 System initialized - monitoring for upgrade buttons")
