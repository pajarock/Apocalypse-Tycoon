--!strict
--[[
	NOTIFICATION UI - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Sistema de notificaciones flotantes para feedback del jugador.

	FEATURES:
	✅ Notificaciones de dodge ("✓ DODGED!")
	✅ Notificaciones de daño ("-25 HP")
	✅ Animaciones de fade-in/fade-out
	✅ Múltiples notificaciones simultáneas
	✅ Colores personalizables
	✅ Auto-limpieza

	INSTALACIÓN:
	1. Copia este archivo a StarterPlayer.StarterPlayerScripts
	2. Desde el servidor, usa:
		local ShowNotification = ReplicatedStorage.Remotes.ShowNotification
		ShowNotification:FireClient(player, "Message", duration, color)

	USO DESDE SERVIDOR:
		-- Notificación de dodge (verde)
		ShowNotification:FireClient(player, "✓ DODGED!", 1.5, Color3.fromRGB(0, 255, 0))

		-- Notificación de daño (rojo)
		ShowNotification:FireClient(player, "-25 HP", 1.5, Color3.fromRGB(255, 0, 0))

		-- Notificación custom
		ShowNotification:FireClient(player, "Achievement!", 2, Color3.fromRGB(255, 200, 0))
--]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

--═══════════════════════════════════════════════════════════════════════
-- CONSTANTS
--═══════════════════════════════════════════════════════════════════════

local NOTIFICATION_START_POSITION = UDim2.new(0.5, 0, 0.75, 0) -- ✅ FIX: Centro-inferior (75% desde arriba)
local NOTIFICATION_SPACING = 60 -- Píxeles entre notificaciones
local MAX_NOTIFICATIONS = 5 -- Máximo de notificaciones visibles simultáneamente

--═══════════════════════════════════════════════════════════════════════
-- ESTADO
--═══════════════════════════════════════════════════════════════════════

local activeNotifications = 0
local notificationQueue: {Frame} = {}

--═══════════════════════════════════════════════════════════════════════
-- UI SETUP
--═══════════════════════════════════════════════════════════════════════

-- Crear ScreenGui contenedor
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationUI"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 10
screenGui.IgnoreGuiInset = true
screenGui.Parent = player:WaitForChild("PlayerGui")

--═══════════════════════════════════════════════════════════════════════
-- CREAR REMOTE EVENT SI NO EXISTE
--═══════════════════════════════════════════════════════════════════════

local function getOrCreateRemote(): RemoteEvent
	local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)

	if not remotes then
		error("[NotificationUI] ReplicatedStorage.Remotes no existe")
	end

	local showNotification = remotes:FindFirstChild("ShowNotification")

	if not showNotification then
		-- Esperar un poco por si el servidor lo está creando
		showNotification = remotes:WaitForChild("ShowNotification", 5)
	end

	if not showNotification or not showNotification:IsA("RemoteEvent") then
		error("[NotificationUI] ShowNotification RemoteEvent no encontrado")
	end

	return showNotification :: RemoteEvent
end

--═══════════════════════════════════════════════════════════════════════
-- FUNCIONES DE ANIMACIÓN
--═══════════════════════════════════════════════════════════════════════

local function createNotification(message: string, duration: number, color: Color3?): Frame
	color = color or Color3.new(1, 1, 1)

	-- Frame contenedor
	local frame = Instance.new("Frame")
	frame.Name = "Notification"
	frame.Size = UDim2.new(0, 250, 0, 50)
	frame.Position = NOTIFICATION_START_POSITION
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.ZIndex = 10
	frame.Parent = screenGui

	-- Esquinas redondeadas
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	-- Borde de color
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = 3
	stroke.Parent = frame

	-- Texto
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = message
	textLabel.TextColor3 = color
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = 24
	textLabel.TextStrokeTransparency = 0.3
	textLabel.ZIndex = 11
	textLabel.Parent = frame

	return frame
end

local function animateNotification(frame: Frame, duration: number)
	-- Incrementar contador de notificaciones activas
	activeNotifications += 1
	table.insert(notificationQueue, frame)

	-- Reposicionar notificaciones existentes (empujar hacia abajo)
	for i, notif in ipairs(notificationQueue) do
		if notif == frame then continue end

		local targetY = NOTIFICATION_START_POSITION.Y.Scale + (i * NOTIFICATION_SPACING / 1000)

		TweenService:Create(
			notif,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{Position = UDim2.new(0.5, 0, targetY, 0)}
		):Play()
	end

	-- Fade in (desde transparente a visible)
	frame.BackgroundTransparency = 1
	frame:FindFirstChild("Text").TextTransparency = 1

	local fadeIn = TweenService:Create(
		frame,
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0.3}
	)

	local textFadeIn = TweenService:Create(
		frame:FindFirstChild("Text"),
		TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0, TextStrokeTransparency = 0.3}
	)

	fadeIn:Play()
	textFadeIn:Play()

	-- Esperar duración
	task.wait(duration - 0.4) -- Restar tiempo de fade in/out

	-- Fade out
	local fadeOut = TweenService:Create(
		frame,
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{BackgroundTransparency = 1}
	)

	local textFadeOut = TweenService:Create(
		frame:FindFirstChild("Text"),
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{TextTransparency = 1, TextStrokeTransparency = 1}
	)

	local strokeFadeOut = TweenService:Create(
		frame:FindFirstChildOfClass("UIStroke"),
		TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{Transparency = 1}
	)

	fadeOut:Play()
	textFadeOut:Play()
	strokeFadeOut:Play()

	-- Cleanup
	fadeOut.Completed:Connect(function()
		activeNotifications = math.max(0, activeNotifications - 1)

		-- Remover de la cola
		local index = table.find(notificationQueue, frame)
		if index then
			table.remove(notificationQueue, index)
		end

		frame:Destroy()
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- API PÚBLICA
--═══════════════════════════════════════════════════════════════════════

local function showNotification(message: string, duration: number, color: Color3?)
	-- Validar parámetros
	if typeof(message) ~= "string" then
		warn("[NotificationUI] Mensaje inválido:", message)
		return
	end

	duration = duration or 2
	color = color or Color3.new(1, 1, 1)

	-- Limitar cantidad de notificaciones simultáneas
	if activeNotifications >= MAX_NOTIFICATIONS then
		-- Destruir la notificación más antigua
		local oldest = notificationQueue[1]
		if oldest then
			oldest:Destroy()
			activeNotifications -= 1
			table.remove(notificationQueue, 1)
		end
	end

	-- Crear y animar notificación
	local frame = createNotification(message, duration, color)

	task.spawn(function()
		animateNotification(frame, duration)
	end)
end

--═══════════════════════════════════════════════════════════════════════
-- CONECTAR CON SERVIDOR
--═══════════════════════════════════════════════════════════════════════

local success, remote = pcall(getOrCreateRemote)

if success and remote then
	-- ✅ FIX: Filtrar notificaciones para evitar duplicación con EventNotifier
	-- EventNotifier maneja: (message, type, duration) donde type = "EPIC", "CRITICAL", etc.
	-- NotificationUI maneja: (message, duration, color) donde duration es número
	remote.OnClientEvent:Connect(function(message: any, param2: any, param3: any)
		-- Si el segundo parámetro es un string, es una notificación tipada para EventNotifier
		if typeof(param2) == "string" then
			-- Ignorar - EventNotifier la manejará
			return
		end

		-- Es una notificación simple para nosotros
		local duration = param2
		local color = param3
		showNotification(message, duration, color)
	end)
	print("[NotificationUI] ✓ Conectado a ShowNotification RemoteEvent")
else
	warn("[NotificationUI] ⚠️ No se pudo conectar al RemoteEvent:", remote)
	warn("[NotificationUI] Las notificaciones no funcionarán")
end

-- Exportar función para uso local (opcional)
_G.ShowNotification = showNotification

print("[NotificationUI] ✓ Sistema de notificaciones listo")
