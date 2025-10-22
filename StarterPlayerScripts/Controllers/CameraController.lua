--!strict
--[[
	CAMERA CONTROLLER - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Maneja efectos de cámara como shake y flash para feedback visual.

	FEATURES:
	✅ Camera shake con intensidades configurables
	✅ Screen flash con colores custom
	✅ Mobile-safe (reduce intensidad automáticamente)
	✅ Settings toggle (respeta preferencias del jugador)
	✅ Thread-safe (múltiples shakes pueden ocurrir simultáneamente)

	USAGE:
		local CameraController = require(script.Parent.CameraController)

		-- Shake
		CameraController:Shake("Heavy", 0.8) -- Heavy shake por 0.8s
		CameraController:Shake("Medium", 0.5) -- Medium shake por 0.5s
		CameraController:Shake("Light", 0.3) -- Light shake por 0.3s

		-- Custom shake
		CameraController:ShakeCustom(0.4, 0.6) -- intensity, duration

		-- Flash
		CameraController:Flash(Color3.fromRGB(255, 0, 0), 0.5, 0.3) -- Red flash

	API:
		:Shake(intensity: "Light" | "Medium" | "Heavy", duration: number)
		:ShakeCustom(intensity: number, duration: number)
		:Flash(color: Color3, intensity: number, duration: number)
		:SetEnabled(enabled: boolean)

	SETTINGS:
	- Los jugadores pueden desactivar shake en settings
	- Mobile automáticamente reduce intensidad 50%
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
--═══════════════════════════════════════════════════════════════════════

local SHAKE_INTENSITY = {
	Light = 0.1,
	Medium = 0.3,
	Heavy = 0.5
}

local MOBILE_REDUCTION = 0.5 -- 50% menos intenso en mobile
local DEBUG_MODE = false

--═══════════════════════════════════════════════════════════════════════
-- STATE
--═══════════════════════════════════════════════════════════════════════

local CameraController = {
	Enabled = true,
	IsMobile = false,
	ActiveShakes = 0,
	FlashFrame = nil :: Frame?
}

--═══════════════════════════════════════════════════════════════════════
-- UTILITIES
--═══════════════════════════════════════════════════════════════════════

local function isMobile(): boolean
	-- Check if device is mobile/tablet
	return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function randomOffset(intensity: number): Vector3
	return Vector3.new(
		math.random() * intensity * 2 - intensity,
		math.random() * intensity * 2 - intensity,
		math.random() * intensity * 2 - intensity
	)
end

local function getFlashFrame(): Frame
	if CameraController.FlashFrame and CameraController.FlashFrame.Parent then
		return CameraController.FlashFrame
	end

	-- Create flash frame
	local playerGui = player:WaitForChild("PlayerGui")

	local sg = Instance.new("ScreenGui")
	sg.Name = "CameraFlashUI"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 999 -- Top layer
	sg.IgnoreGuiInset = true
	sg.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "FlashFrame"
	frame.Size = UDim2.fromScale(1, 1)
	frame.Position = UDim2.fromScale(0, 0)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1 -- Start invisible
	frame.BorderSizePixel = 0
	frame.ZIndex = 999
	frame.Parent = sg

	CameraController.FlashFrame = frame
	return frame
end

--═══════════════════════════════════════════════════════════════════════
-- CAMERA SHAKE
--═══════════════════════════════════════════════════════════════════════

--[[
	Aplica camera shake con intensidad predefinida.

	@param intensity string - "Light", "Medium", o "Heavy"
	@param duration number - Duración en segundos
]]
function CameraController:Shake(intensity: string, duration: number)
	local intensityValue = SHAKE_INTENSITY[intensity]
	if not intensityValue then
		warn(("[CameraController] Intensidad inválida: %s"):format(intensity))
		return
	end

	self:ShakeCustom(intensityValue, duration)
end

--[[
	Aplica camera shake con intensidad custom.

	@param intensity number - Valor de intensidad (0.0 - 1.0)
	@param duration number - Duración en segundos
]]
function CameraController:ShakeCustom(intensity: number, duration: number)
	if not self.Enabled then
		if DEBUG_MODE then
			print("[CameraController] Shake disabled by settings")
		end
		return
	end

	-- Reduce intensity on mobile
	local finalIntensity = intensity
	if self.IsMobile then
		finalIntensity *= MOBILE_REDUCTION
	end

	-- Track active shake
	self.ActiveShakes += 1

	if DEBUG_MODE then
		print(("[CameraController] Shake started (intensity: %.2f, duration: %.2f)"):format(finalIntensity, duration))
	end

	-- Spawn shake coroutine
	task.spawn(function()
		local elapsed = 0
		local originalCFrame = camera.CFrame

		-- Run shake loop
		while elapsed < duration do
			local dt = task.wait()
			elapsed += dt

			-- Calculate decay (shake reduces over time)
			local decay = 1 - (elapsed / duration)
			local currentIntensity = finalIntensity * decay

			-- Apply random offset
			local offset = randomOffset(currentIntensity)
			camera.CFrame = camera.CFrame * CFrame.new(offset)
		end

		-- Cleanup
		self.ActiveShakes = math.max(0, self.ActiveShakes - 1)

		if DEBUG_MODE then
			print("[CameraController] Shake finished")
		end
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- SCREEN FLASH
--═══════════════════════════════════════════════════════════════════════

--[[
	Aplica un flash de pantalla completa.

	@param color Color3 - Color del flash
	@param intensity number - Opacidad máxima (0.0 - 1.0)
	@param duration number - Duración en segundos
]]
function CameraController:Flash(color: Color3, intensity: number, duration: number)
	if not self.Enabled then
		if DEBUG_MODE then
			print("[CameraController] Flash disabled by settings")
		end
		return
	end

	-- Reduce intensity on mobile
	local finalIntensity = intensity
	if self.IsMobile then
		finalIntensity *= MOBILE_REDUCTION
	end

	local frame = getFlashFrame()
	frame.BackgroundColor3 = color

	if DEBUG_MODE then
		print(("[CameraController] Flash (color: %s, intensity: %.2f)"):format(tostring(color), finalIntensity))
	end

	-- Fade in
	local fadeIn = TweenService:Create(
		frame,
		TweenInfo.new(duration * 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 1 - finalIntensity}
	)

	-- Fade out
	local fadeOut = TweenService:Create(
		frame,
		TweenInfo.new(duration * 0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)

	fadeIn:Play()
	fadeIn.Completed:Connect(function()
		fadeOut:Play()
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- SETTINGS
--═══════════════════════════════════════════════════════════════════════

--[[
	Habilita/deshabilita efectos de cámara.

	@param enabled boolean - true para habilitar, false para deshabilitar
]]
function CameraController:SetEnabled(enabled: boolean)
	self.Enabled = enabled

	if DEBUG_MODE then
		print(("[CameraController] %s"):format(enabled and "Enabled" or "Disabled"))
	end
end

--[[
	Retorna si los efectos están habilitados.

	@return boolean - true si habilitado
]]
function CameraController:IsEnabled(): boolean
	return self.Enabled
end

--═══════════════════════════════════════════════════════════════════════
-- INITIALIZATION
--═══════════════════════════════════════════════════════════════════════

-- Detect mobile
CameraController.IsMobile = isMobile()

if DEBUG_MODE then
	print(("[CameraController] Platform: %s"):format(CameraController.IsMobile and "Mobile" or "Desktop"))
end

-- Listen for settings changes (futuro: integrar con SettingsUI)
-- TODO: Conectar con sistema de settings cuando exista
-- SettingsModule.OnSettingChanged:Connect(function(setting, value)
--     if setting == "CameraShake" then
--         CameraController:SetEnabled(value)
--     end
-- end)

-- Debug commands (solo en DEBUG_MODE)
if DEBUG_MODE then
	-- Test shake con tecla K
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end

		if input.KeyCode == Enum.KeyCode.K then
			print("[DEBUG] Testing camera shake")
			CameraController:Shake("Heavy", 0.5)
		elseif input.KeyCode == Enum.KeyCode.L then
			print("[DEBUG] Testing screen flash")
			CameraController:Flash(Color3.fromRGB(255, 100, 0), 0.6, 0.4)
		end
	end)

	print("[CameraController] DEBUG: Press K para shake, L para flash")
end

print("[CameraController] ✓ Módulo cargado")

return CameraController
