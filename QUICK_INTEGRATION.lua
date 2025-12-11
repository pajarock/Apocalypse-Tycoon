--[[
	QUICK INTEGRATION CODE
	Copia y pega estos fragmentos en tu ShopUIController.luau
]]

--═══════════════════════════════════════════════════════════════════════════
-- 1️⃣ AL INICIO DEL ARCHIVO (después de tus requires)
--═══════════════════════════════════════════════════════════════════════════

local MenuEffects = require(script.Parent.MenuEffects)


--═══════════════════════════════════════════════════════════════════════════
-- 2️⃣ EN LA SECCIÓN DE VARIABLES INTERNAS (después de `local currentMainTab`)
--═══════════════════════════════════════════════════════════════════════════

local effectsSystem: any = nil
local menuOpenSound: Sound? = nil


--═══════════════════════════════════════════════════════════════════════════
-- 3️⃣ DESPUÉS DE CREAR TODO EL UI (al final de tu función que construye el UI)
--═══════════════════════════════════════════════════════════════════════════

-- 🎨 SETUP VISUAL EFFECTS & AUDIO
local function setupEffects()
	print("🎨 Setting up visual effects...")

	-- Recopilar todos los botones
	local allButtons = {}

	-- Main tabs
	for _, btn in pairs(mainTabButtons) do
		table.insert(allButtons, btn)
	end

	-- Sub tabs (si tienes)
	if subTabButtons then
		for _, btn in pairs(subTabButtons) do
			table.insert(allButtons, btn)
		end
	end

	-- Buy button
	if buyButton then
		table.insert(allButtons, buyButton)
	end

	-- Close button (el botón X rojo)
	local closeBtn = mainFrame:FindFirstChild("CloseButton")
	if closeBtn then
		table.insert(allButtons, closeBtn)
	end

	-- Setup completo de efectos
	effectsSystem = MenuEffects.SetupAllEffects(mainFrame, allButtons)
	menuOpenSound = effectsSystem.openSound

	print("✅ Visual effects ready!")
end

-- Llamar setup
setupEffects()


--═══════════════════════════════════════════════════════════════════════════
-- 4️⃣ REEMPLAZA TU FUNCIÓN ToggleMenu() CON ESTA VERSIÓN
--═══════════════════════════════════════════════════════════════════════════

local function ToggleMenu()
	isMenuOpen = not isMenuOpen

	if isMenuOpen then
		-- ═══ ABRIR MENU ═══
		screenGui.Enabled = true

		-- 🎬 Animación de apertura + sonido
		MenuEffects.PlayOpenAnimation(mainFrame, menuOpenSound)

		-- Update UI
		UpdateCurrentTab()
		UpdateCash()

		-- 🔄 Ambient audio (si lo tienes)
		if ambientSound and ambientSound.SoundId ~= "" then
			ambientSound:Play()
		end

		-- Start auto-refresh
		if refreshConnection then refreshConnection:Disconnect() end
		refreshConnection = RunService.Heartbeat:Connect(function()
			task.wait(2)
			if isMenuOpen then
				UpdateItemStates()
			end
		end)

	else
		-- ═══ CERRAR MENU ═══

		-- 🎬 Animación de cierre
		local closeTween = MenuEffects.PlayCloseAnimation(mainFrame)

		-- Esperar a que termine animación
		closeTween.Completed:Connect(function()
			screenGui.Enabled = false
		end)

		-- 🔇 Ambient audio stop
		if ambientSound then
			ambientSound:Stop()
		end

		-- Stop auto-refresh
		if refreshConnection then
			refreshConnection:Disconnect()
			refreshConnection = nil
		end
	end
end


--═══════════════════════════════════════════════════════════════════════════
-- 5️⃣ AUDIO ASSET IDs - ACTUALIZA ESTOS EN MenuEffects.lua
--═══════════════════════════════════════════════════════════════════════════

--[[
	Abre MenuEffects.lua y cambia:

	local SOUNDS = {
		MenuOpen = "rbxassetid://YOUR_ASSET_ID",    -- Sonido apertura
		ClickDrop = "rbxassetid://YOUR_ASSET_ID",   -- Sonido click
	}

	SUGERENCIAS DE ASSET IDs:
	- Menu Open: 3398620867, 5153845714, 6895079853
	- Click/Drop: 12221967, 3398620867, 5273899897
]]


--═══════════════════════════════════════════════════════════════════════════
-- ✅ LISTO! Ahora tienes:
--═══════════════════════════════════════════════════════════════════════════
--
-- ✓ Toxic slime drip cayendo del header
-- ✓ Partículas radioactivas flotando hacia arriba
-- ✓ Sonido de click en todos los botones
-- ✓ Animación suave al abrir/cerrar menu
-- ✓ Sonido al abrir menu
--
-- Para probar: Presiona Z (o tu keybind) para abrir el menu
--═══════════════════════════════════════════════════════════════════════════
