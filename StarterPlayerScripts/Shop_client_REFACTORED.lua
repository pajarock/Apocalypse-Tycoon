--!strict
--[[
	SHOP CLIENT - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	VERSIÓN REFACTORIZADA con animaciones épicas.

	CAMBIOS EN ESTA VERSIÓN:
	✅ Integración con UIController para animaciones suaves
	✅ Slide in/out al abrir/cerrar con tecla B
	✅ Hover effects "jugosos" (scale + glow)
	✅ Purchase feedback épico (bounce + partículas)
	✅ Transiciones suaves entre estados (puede/no puede comprar)
	✅ Mantiene TODA la funcionalidad original

	INSTRUCCIONES DE INSTALACIÓN:
	1. Copia UIController.lua a StarterPlayerScripts.Controllers
	2. Reemplaza Shop_client.lua con este archivo
	3. ¡Listo! No requiere cambios en servidor

	COMPATIBILIDAD:
	- Misma API que versión anterior
	- No rompe código existente
	- Solo agrega efectos visuales
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- 🔥 NUEVO: Import UIController
local UIController = require(script.Parent.Controllers.UIController)

-- Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RequestState = Remotes:WaitForChild("RequestState") :: RemoteFunction
local RequestPurchase = Remotes:WaitForChild("RequestPurchase") :: RemoteEvent

-- UI ROOT
local sg = Instance.new("ScreenGui")
sg.Name = "QuickBuyUI"
sg.ResetOnSpawn = false
sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
sg.Parent = player:WaitForChild("PlayerGui")

-- Main frame
local frame = Instance.new("Frame")
frame.Name = "MainFrame"
frame.Size = UDim2.fromOffset(280, 450)
frame.Position = UDim2.fromOffset(20, 100)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Parent = sg

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = frame

-- 🔥 NUEVO: Agregar sombra sutil
local shadow = Instance.new("ImageLabel")
shadow.Name = "Shadow"
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.fromOffset(-10, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxasset://textures/ui/GuiImagePlaceholder.png"
shadow.ImageColor3 = Color3.new(0, 0, 0)
shadow.ImageTransparency = 0.7
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(10, 10, 118, 118)
shadow.ZIndex = frame.ZIndex - 1
shadow.Parent = frame

-- Header
local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 50)
header.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
header.BorderSizePixel = 0
header.Parent = frame

local headerCorner = Instance.new("UICorner")
headerCorner.CornerRadius = UDim.new(0, 12)
headerCorner.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 1, 0)
title.Position = UDim2.fromOffset(10, 0)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.fromRGB(255, 255, 100)
title.TextXAlignment = Enum.TextXAlignment.Left
title.Text = "🛒 QUICK BUY"
title.Parent = header

-- Info panel
local info = Instance.new("TextLabel")
info.Name = "Info"
info.Size = UDim2.new(1, -20, 0, 50)
info.Position = UDim2.fromOffset(10, 60)
info.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
info.BorderSizePixel = 0
info.Font = Enum.Font.Gotham
info.TextSize = 14
info.TextColor3 = Color3.new(1, 1, 1)
info.TextXAlignment = Enum.TextXAlignment.Left
info.Text = "Cargando..."
info.Parent = frame

local infoCorner = Instance.new("UICorner")
infoCorner.CornerRadius = UDim.new(0, 6)
infoCorner.Parent = info

-- Lista de upgrades
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "UpgradeList"
scrollFrame.Size = UDim2.new(1, -20, 1, -130)
scrollFrame.Position = UDim2.fromOffset(10, 120)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = frame

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = scrollFrame

-- Upgrades a mostrar
local UPGRADES = {
	"Upgrade_1",
	"Upgrade_2",
	"Upgrade_3",
	"Upgrade_4",
	"Upgrade_5",
	"Upgrade_6",
	"Upgrade_7",
}

-- Crear botón para cada upgrade
local buttons = {}

for i, upgradeId in ipairs(UPGRADES) do
	local btn = Instance.new("TextButton")
	btn.Name = upgradeId
	btn.Size = UDim2.new(1, 0, 0, 45)
	btn.BackgroundColor3 = Color3.fromRGB(60, 100, 60)
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = upgradeId
	btn.AutoButtonColor = false -- 🔥 Desactivar para control manual
	btn.LayoutOrder = i
	btn.Parent = scrollFrame

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn

	-- 🔥 NUEVO: Guardar color original para efectos
	btn:SetAttribute("OriginalColorR", btn.BackgroundColor3.R)
	btn:SetAttribute("OriginalColorG", btn.BackgroundColor3.G)
	btn:SetAttribute("OriginalColorB", btn.BackgroundColor3.B)

	-- 🔥 NUEVO: Agregar hover effect usando UIController
	UIController:AddHoverEffect(btn, "scale+glow")

	-- Click handler
	btn.MouseButton1Click:Connect(function()
		print(("[QuickBuy] Comprando %s..."):format(upgradeId))
		RequestPurchase:FireServer(upgradeId)

		-- 🔥 NUEVO: Purchase effect épico usando UIController
		UIController:PlayPurchaseEffect(btn)

		-- Sonido de compra
		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://17208380755"
		sound.Volume = 0.4
		sound.Parent = workspace
		sound:Play()
		game:GetService("Debris"):AddItem(sound, 2)
	end)

	buttons[upgradeId] = btn
end

-- Función para formatear dinero
local function formatMoney(amount: number): string
	if amount >= 1000000 then
		return string.format("$%.1fM", amount / 1000000)
	elseif amount >= 1000 then
		return string.format("$%.1fK", amount / 1000)
	else
		return "$" .. tostring(math.floor(amount))
	end
end

-- 🔥 NUEVO: Transiciones suaves de color con tweens
local function updateButtonColor(btn: TextButton, targetColor: Color3, duration: number)
	TweenService:Create(
		btn,
		TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundColor3 = targetColor}
	):Play()
end

-- Actualizar UI
local function updateUI()
	local ok, state = pcall(function()
		return RequestState:InvokeServer()
	end)

	if not ok or not state then
		info.Text = "❌ Error cargando datos"
		return
	end

	info.Text = string.format(
		"💰 Cash: %s\n📈 Income: %d/s",
		formatMoney(state.Cash or 0),
		state.IncomePerSec or 0
	)

	for upgradeId, btn in pairs(buttons) do
		local upgradeInfo = state.UpgradesInfo and state.UpgradesInfo[upgradeId]

		if upgradeInfo then
			local price = upgradeInfo.Price or 0
			local count = upgradeInfo.Count or 0
			local maxCount = upgradeInfo.MaxCount
			local title = upgradeInfo.Title or upgradeId

			local btnText = string.format(
				"%s\n%s | x%d",
				title,
				formatMoney(price),
				count
			)

			if maxCount then
				btnText = btnText .. string.format(" / %d", maxCount)
			end

			btn.Text = btnText

			-- 🔥 NUEVO: Transiciones de color suaves
			if maxCount and count >= maxCount then
				updateButtonColor(btn, Color3.fromRGB(80, 80, 80), 0.3)
				btn.TextColor3 = Color3.fromRGB(150, 150, 150)
			elseif state.Cash >= price then
				updateButtonColor(btn, Color3.fromRGB(60, 100, 60), 0.3)
				btn.TextColor3 = Color3.new(1, 1, 1)

				-- Store original color for hover
				btn:SetAttribute("OriginalColorR", 60/255)
				btn:SetAttribute("OriginalColorG", 100/255)
				btn:SetAttribute("OriginalColorB", 60/255)
			else
				updateButtonColor(btn, Color3.fromRGB(100, 50, 50), 0.3)
				btn.TextColor3 = Color3.fromRGB(200, 150, 150)

				-- Store original color for hover
				btn:SetAttribute("OriginalColorR", 100/255)
				btn:SetAttribute("OriginalColorG", 50/255)
				btn:SetAttribute("OriginalColorB", 50/255)
			end
		end
	end

	local contentSize = layout.AbsoluteContentSize
	scrollFrame.CanvasSize = UDim2.fromOffset(0, contentSize.Y)
end

-- 🔥 NUEVO: Toggle con animación slide
local visible = true

local function toggleShop()
	visible = not visible

	if visible then
		-- Slide in desde la izquierda
		UIController:SlideIn(frame, "Left", 0.4)
	else
		-- Slide out hacia la izquierda
		UIController:SlideOut(frame, "Left", 0.3)
	end
end

-- Toggle con tecla B
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.B then
		toggleShop()
	end
end)

-- 🔥 NUEVO: Animación de entrada al cargar
task.wait(0.5) -- Esperar a que todo cargue
UIController:SlideIn(frame, "Left", 0.5)

-- Loop de actualización
task.spawn(function()
	while true do
		updateUI()
		task.wait(1)
	end
end)

updateUI()

print("[QuickBuy REFACTORED] ✓ UI inicializada con animaciones. Presiona B para mostrar/ocultar")
