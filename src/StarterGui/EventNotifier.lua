-- ============================================================================
-- APOCALYPSE NOTIFIER  Limpio pero INTENSO
-- Colores de fuego, urgencia real, sin saturación visual
-- ============================================================================

--!strict

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer

-- ============================================================================
-- CONFIG  Paleta Apocalíptica + POSICIÓN EN PANTALLA
-- ============================================================================

local CONFIG = {
	COLORS = {
		WARNING  = Color3.fromRGB(255, 140,  30),  -- Naranja fuego
		CRITICAL = Color3.fromRGB(220,  30,  30),  -- Rojo lava
		SUCCESS  = Color3.fromRGB(120, 220,  50),  -- Verde ácido/tóxico
		INFO     = Color3.fromRGB(255, 200,  50),  -- Amarillo advertencia
		EPIC     = Color3.fromRGB(255, 170,  20),  -- Naranja dorado intenso
	},
	SOUNDS = {
		WARNING  = "rbxassetid://9125402735",
		CRITICAL = "rbxassetid://9114397505",
		SUCCESS  = "rbxassetid://6895079853",
		INFO     = "rbxassetid://9125402735",
		EPIC     = "rbxassetid://6895079853",
	},
	DEFAULT_TYPE = "WARNING",
	DEFAULT_DURATION = 2.0,  -- Más rápido
	PARTICLE_COUNT = 12,
	SHAKE_INTENSITY = 6,
	MAX_QUEUE_SIZE = 2,  -- Máximo 2 notificaciones en cola

	-- UI: AQUÍ CONTROLAS POSICIÓN Y TAMAÑO DEL NOTIFIER
	UI = {
		-- ANCHOR_Y controla la altura en pantalla (0 = arriba, 1 = abajo).
		-- Si tapa algo, súbelo/bájalo aquí.
		ANCHOR_Y = 0.18, -- ANTES ~0.08. Más abajo para no tapar tu widget.

		WIDTH = 800,
		HEIGHT = 110,
		MIN_WIDTH = 100,
	},
}

-- ============================================================================
-- UTILS
-- ============================================================================

local function getColorFor(typeTag: string?): Color3
	if not typeTag then return CONFIG.COLORS[CONFIG.DEFAULT_TYPE] end
	local key = string.upper(typeTag)
	return CONFIG.COLORS[key] or CONFIG.COLORS[CONFIG.DEFAULT_TYPE]
end

local function getSoundFor(typeTag: string?): string?
	if not typeTag then return CONFIG.SOUNDS[CONFIG.DEFAULT_TYPE] end
	local key = string.upper(typeTag)
	return CONFIG.SOUNDS[key] or CONFIG.SOUNDS[CONFIG.DEFAULT_TYPE]
end

-- Un pequeño boost de shake para cosas épicas/críticas
local function getShakeIntensity(typeTag: string?): number
	typeTag = typeTag and string.upper(typeTag) or CONFIG.DEFAULT_TYPE
	if typeTag == "EPIC" or typeTag == "CRITICAL" then
		return CONFIG.SHAKE_INTENSITY * 1.4
	end
	return CONFIG.SHAKE_INTENSITY
end

-- ============================================================================
-- ROOT GUI
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ApocalypseNotifier"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 5 -- Debajo del HUD permanente
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Contenedor principal
local mainContainer = Instance.new("Frame")
mainContainer.Name = "MainContainer"
mainContainer.AnchorPoint = Vector2.new(0.5, 0)

-- POSICIÓN DEL NOTIFIER EN PANTALLA
-- X = 0.5 (centrado)
-- Y = CONFIG.UI.ANCHOR_Y (ajusta esto si tapa algo)
mainContainer.Position = UDim2.new(0.5, 0, CONFIG.UI.ANCHOR_Y, 0)

-- Tamaño inicial pequeño (se expande con animación)
mainContainer.Size = UDim2.fromOffset(CONFIG.UI.MIN_WIDTH, CONFIG.UI.HEIGHT)

mainContainer.BackgroundTransparency = 1
mainContainer.Visible = false
mainContainer.Rotation = -2 -- Inclinación grafiti
mainContainer.Parent = screenGui

-- Sombra dura (no suave - más apocalíptica)
local shadow = Instance.new("Frame")
shadow.Name = "Shadow"
shadow.AnchorPoint = Vector2.new(0.5, 0.5)
shadow.Position = UDim2.new(0.5, 0, 0.5, 5)
shadow.Size = UDim2.fromScale(1.01, 1.05)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.5
shadow.BorderSizePixel = 0
shadow.ZIndex = 1
shadow.Parent = mainContainer

local shadowCorner = Instance.new("UICorner")
shadowCorner.CornerRadius = UDim.new(0, 8)
shadowCorner.Parent = shadow

-- Frame principal - más oscuro para contraste
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
mainFrame.Size = UDim2.fromScale(1, 1)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 20)
mainFrame.BackgroundTransparency = 0.05
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 2
mainFrame.Parent = mainContainer

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

-- Borde INTENSO
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = Color3.fromRGB(255, 140, 30)
stroke.Transparency = 0.2
stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
stroke.Parent = mainFrame

-- Gradiente de fuego/calor
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 140, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(220, 50, 30)),
})
bgGradient.Rotation = 90
bgGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.88),
	NumberSequenceKeypoint.new(1, 0.92),
})
bgGradient.Parent = mainFrame

-- Barra izquierda gruesa (alerta)
local leftBar = Instance.new("Frame")
leftBar.Name = "LeftBar"
leftBar.Position = UDim2.new(0, 0, 0, 0)
leftBar.Size = UDim2.new(0, 8, 1, 0)
leftBar.BackgroundColor3 = Color3.fromRGB(255, 140, 30)
leftBar.BorderSizePixel = 0
leftBar.ZIndex = 3
leftBar.Parent = mainFrame

local leftCorner = Instance.new("UICorner")
leftCorner.CornerRadius = UDim.new(0, 8)
leftCorner.Parent = leftBar

-- Icono de advertencia (MÁS GRANDE Y DRAMÁTICO)
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Position = UDim2.new(0, 25, 0.5, 0)
iconContainer.AnchorPoint = Vector2.new(0, 0.5)
iconContainer.Size = UDim2.fromOffset(70, 70) -- Más grande
iconContainer.BackgroundTransparency = 1
iconContainer.ZIndex = 4
iconContainer.Parent = mainFrame

local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "IconLabel"
iconLabel.AnchorPoint = Vector2.new(0.5, 0.5)
iconLabel.Position = UDim2.fromScale(0.5, 0.5)
iconLabel.Size = UDim2.fromScale(1, 1)
iconLabel.BackgroundTransparency = 1
iconLabel.Font = Enum.Font.LuckiestGuy -- GRAFITI
iconLabel.Text = "?"
iconLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
iconLabel.TextScaled = true
iconLabel.TextStrokeTransparency = 0.2
iconLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
iconLabel.ZIndex = 5
iconLabel.Rotation = -5
iconLabel.Parent = iconContainer

-- ============================================================================
-- TEXTO  Mensaje directo y urgente
-- ============================================================================

local textContainer = Instance.new("Frame")
textContainer.Name = "TextContainer"
textContainer.Position = UDim2.new(0, 85, 0, 0)
textContainer.Size = UDim2.new(1, -100, 1, 0)
textContainer.BackgroundTransparency = 1
textContainer.ZIndex = 4
textContainer.Parent = mainFrame

local messageLabel = Instance.new("TextLabel")
messageLabel.Name = "MessageLabel"
messageLabel.AnchorPoint = Vector2.new(0, 0.5)
messageLabel.Position = UDim2.new(0, 0, 0.5, 0)
messageLabel.Size = UDim2.new(1, 0, 0, 60)
messageLabel.BackgroundTransparency = 1
messageLabel.Font = Enum.Font.LuckiestGuy
messageLabel.Text = ""
messageLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
messageLabel.TextScaled = true
messageLabel.TextWrapped = true
messageLabel.TextStrokeTransparency = 0.2
messageLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
messageLabel.TextXAlignment = Enum.TextXAlignment.Left
messageLabel.TextYAlignment = Enum.TextYAlignment.Center
messageLabel.ZIndex = 5
messageLabel.Rotation = -3
messageLabel.Parent = textContainer

-- ============================================================================
-- EFECTOS DE CALOR/PARTÍCULAS
-- ============================================================================

local particlesContainer = Instance.new("Frame")
particlesContainer.Name = "ParticlesContainer"
particlesContainer.AnchorPoint = Vector2.new(0.5, 0.5)
particlesContainer.Position = UDim2.fromScale(0.5, 0.5)
particlesContainer.Size = UDim2.fromScale(1, 1)
particlesContainer.BackgroundTransparency = 1
particlesContainer.ClipsDescendants = false
particlesContainer.ZIndex = 10
particlesContainer.Parent = mainContainer

-- ============================================================================
-- SONIDO
-- ============================================================================

local soundFolder = SoundService:FindFirstChild("NotificationSounds") :: Folder
if not soundFolder then
	soundFolder = Instance.new("Folder")
	soundFolder.Name = "NotificationSounds"
	soundFolder.Parent = SoundService
end

local function createSound(soundId: string, volume: number?): Sound
	local s = Instance.new("Sound")
	s.SoundId = soundId
	s.Volume = volume or 0.6
	s.Parent = soundFolder
	return s
end

-- ============================================================================
-- EFECTOS VISUALES
-- ============================================================================

local activeAnimations: {RBXScriptConnection} = {}

-- Partículas de calor/ceniza ascendente
local function createParticle(color: Color3): Frame
	local p = Instance.new("Frame")
	p.Size = UDim2.fromOffset(math.random(2, 5), math.random(8, 16))
	p.Position = UDim2.new(math.random(), 0, 1.1, 0)
	p.AnchorPoint = Vector2.new(0.5, 0.5)
	p.BackgroundColor3 = color
	p.BackgroundTransparency = 0.3
	p.BorderSizePixel = 0
	p.ZIndex = 11
	p.Rotation = math.random(-15, 15)
	p.Parent = particlesContainer

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = p

	return p
end

-- Gradiente rotando rápido (efecto de calor)
local function animateGradient()
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function(dt)
		if mainContainer.Visible then
			bgGradient.Rotation = (bgGradient.Rotation + dt * 40) % 360
		else
			conn:Disconnect()
		end
	end)
	table.insert(activeAnimations, conn)
end

-- Pulso RÁPIDO del borde (urgencia)
local function pulseBorder()
	local conn: RBXScriptConnection
	local t = 0
	conn = RunService.RenderStepped:Connect(function(dt)
		if mainContainer.Visible then
			t += dt * 4  -- Más rápido
			stroke.Transparency = 0.15 + math.sin(t) * 0.2
			stroke.Thickness = 2.5 + math.sin(t) * 0.8
		else
			conn:Disconnect()
		end
	end)
	table.insert(activeAnimations, conn)
end

-- Pulso en barra lateral
local function pulseLeftBar()
	local conn: RBXScriptConnection
	local t = 0
	conn = RunService.RenderStepped:Connect(function(dt)
		if mainContainer.Visible then
			t += dt * 5
			leftBar.BackgroundTransparency = math.sin(t) * 0.15
		else
			conn:Disconnect()
		end
	end)
	table.insert(activeAnimations, conn)
end

-- Partículas de ceniza/chispas subiendo
local function animateParticles(duration: number, color: Color3)
	for i = 1, CONFIG.PARTICLE_COUNT do
		local p = createParticle(color)
		local randomDuration = duration * (0.7 + math.random() * 0.5)
		local randomDelay = math.random() * 0.4

		task.delay(randomDelay, function()
			if not p or not p.Parent then return end

			local targetY = -0.2 - math.random() * 0.3
			local wobbleX = p.Position.X.Scale + (math.random() - 0.5) * 0.15

			local tween = TweenService:Create(
				p,
				TweenInfo.new(randomDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{
					Position = UDim2.new(wobbleX, 0, targetY, 0),
					BackgroundTransparency = 1,
					Rotation = p.Rotation + (math.random() - 0.5) * 90
				}
			)
			tween:Play()
			tween.Completed:Connect(function()
				if p then p:Destroy() end
			end)
		end)
	end
end

-- Shake de urgencia
local function shakeEffect(intensity: number, duration: number)
	local start = tick()
	local basePos = mainContainer.Position
	local conn: RBXScriptConnection
	conn = RunService.RenderStepped:Connect(function()
		local e = tick() - start
		if e < duration and mainContainer.Visible then
			local prog = e / duration
			local curI = intensity * (1 - prog)
			local ox = (math.random() - 0.5) * curI
			local oy = (math.random() - 0.5) * curI
			mainContainer.Position = UDim2.new(
				basePos.X.Scale,
				basePos.X.Offset + ox,
				basePos.Y.Scale,
				basePos.Y.Offset + oy
			)
		else
			mainContainer.Position = basePos
			conn:Disconnect()
		end
	end)
	table.insert(activeAnimations, conn)
end

local function clearActive()
	for _, c in ipairs(activeAnimations) do
		if typeof(c) == "RBXScriptConnection" then
			c:Disconnect()
		end
	end
	table.clear(activeAnimations)
end

-- ============================================================================
-- NOTIFICATIONS (QUEUE)
-- ============================================================================

local queue: {{any}} = {}
local busy = false

local function showNotification(message: string, typeTag: string?, duration: number?)
	typeTag = typeTag or CONFIG.DEFAULT_TYPE
	duration = duration or CONFIG.DEFAULT_DURATION

	-- Cola limitada para no atrasar notis
	if busy then
		if #queue >= CONFIG.MAX_QUEUE_SIZE then
			table.remove(queue, 1) -- Saca la más vieja
		end
		table.insert(queue, {message, typeTag, duration})
		return
	end
	busy = true

	clearActive()

	-- Color apocalíptico
	local color = getColorFor(typeTag)

	-- Aplicar tema
	stroke.Color = color
	leftBar.BackgroundColor3 = color
	bgGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(1, Color3.new(
			math.clamp(color.R * 0.5, 0, 1),
			math.clamp(color.G * 0.4, 0, 1),
			math.clamp(color.B * 0.3, 0, 1)
			)),
	})

	-- Iconos
	local icons = {
		WARNING = "?",
		CRITICAL = "?",
		SUCCESS = "?",
		INFO = "?",
		EPIC = "?", -- Radiación para épico
	}
	iconLabel.Text = icons[string.upper(typeTag)] or "?"
	iconLabel.TextColor3 = color

	-- Mensaje en mayúsculas (más urgente)
	messageLabel.Text = string.upper(message)

	-- Reset visual
	mainContainer.Visible = true
	mainContainer.Size = UDim2.fromOffset(CONFIG.UI.MIN_WIDTH, CONFIG.UI.HEIGHT)
	shadow.BackgroundTransparency = 1
	mainFrame.BackgroundTransparency = 1
	leftBar.BackgroundTransparency = 1
	stroke.Transparency = 1
	iconLabel.TextTransparency = 1
	messageLabel.TextTransparency = 1

	-- Sonido
	local sid = getSoundFor(typeTag)
	if sid then
		local s = createSound(sid, 0.65)
		s:Play()
		Debris:AddItem(s, 4)
	end

	-- ===== ENTRADA RÁPIDA =====

	local expandTween = TweenService:Create(
		mainContainer,
		TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Size = UDim2.fromOffset(CONFIG.UI.WIDTH, CONFIG.UI.HEIGHT) }
	)
	expandTween:Play()

	TweenService:Create(shadow, TweenInfo.new(0.2), { BackgroundTransparency = 0.5 }):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.2), { BackgroundTransparency = 0.05 }):Play()
	TweenService:Create(leftBar, TweenInfo.new(0.15), { BackgroundTransparency = 0 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.15), { Transparency = 0.2 }):Play()

	task.wait(0.12)

	iconLabel.Size = UDim2.fromScale(0.5, 0.5)
	iconLabel.Rotation = -25
	TweenService:Create(
		iconLabel,
		TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out),
		{
			Size = UDim2.fromScale(1, 1),
			TextTransparency = 0,
			Rotation = -5
		}
	):Play()

	task.wait(0.08)

	TweenService:Create(
		messageLabel,
		TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		{ TextTransparency = 0 }
	):Play()

	-- Efectos
	animateGradient()
	pulseBorder()
	pulseLeftBar()
	animateParticles(duration, color)
	shakeEffect(getShakeIntensity(typeTag), 0.3)

	-- Tiempo en pantalla
	task.wait(duration)

	-- ===== SALIDA =====

	TweenService:Create(
		messageLabel,
		TweenInfo.new(0.2),
		{ TextTransparency = 1 }
	):Play()

	task.wait(0.08)

	TweenService:Create(iconLabel, TweenInfo.new(0.15), { TextTransparency = 1 }):Play()
	TweenService:Create(leftBar, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.2), { Transparency = 1 }):Play()
	TweenService:Create(mainFrame, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(shadow, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()

	task.wait(0.12)

	local collapseTween = TweenService:Create(
		mainContainer,
		TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Size = UDim2.fromOffset(CONFIG.UI.MIN_WIDTH, CONFIG.UI.HEIGHT) }
	)
	collapseTween:Play()
	collapseTween.Completed:Wait()

	mainContainer.Visible = false
	busy = false

	if #queue > 0 then
		local nxt = table.remove(queue, 1)
		task.wait(0.2)
		showNotification(nxt[1], nxt[2], nxt[3])
	end
end

-- Helper global (por si quieres usarlo desde otros LocalScripts)
_G.ApocalypseNotify = function(msg: string, typeTag: string?, duration: number?)
	showNotification(msg, typeTag, duration)
end

-- ============================================================================
-- REMOTES
-- ============================================================================

-- FORMAS SOPORTADAS DESDE EL SERVIDOR:
-- 1) ShowNotification:FireClient(player, "WAVE 1 INCOMING")
-- 2) ShowNotification:FireClient(player, "WAVE 1 INCOMING", "EPIC")
-- 3) ShowNotification:FireClient(player, "WAVE 1 INCOMING", "EPIC", 3)
-- 4) ShowNotification:FireClient(player, { message = "WAVE 1 INCOMING", type = "EPIC", duration = 3 })

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:WaitForChild("Remotes", 5)
if not remotes then
	warn("[ApocalypseNotifier] 'Remotes' no encontrado.")
else
	local evt = remotes:FindFirstChild("ShowNotification") or remotes:WaitForChild("ShowNotification", 5)
	if not evt then
		warn("[ApocalypseNotifier] RemoteEvent 'ShowNotification' no encontrado.")
	else
		evt.OnClientEvent:Connect(function(a: any, b: any, c: any)
			-- Modo tabla/payload
			if typeof(a) == "table" then
				local payload = a :: {message: any, type: any, duration: any}
				local msg = tostring(payload.message or "")
				if msg == "" then return end
				local t = payload.type and tostring(payload.type) or nil
				local du = (typeof(payload.duration) == "number" and payload.duration or nil)
				showNotification(msg, t, du)
				return
			end

			-- Modo clásico: mensaje, tipo?, duración?
			-- ej: FireClient(plr, "Wave 1 incoming", "EPIC", 3)
			if typeof(a) == "string" then
				local msg = a
				local t = (typeof(b) == "string") and (b :: string) or nil
				local du = (typeof(c) == "number") and (c :: number) or nil
				showNotification(msg, t, du)
				return
			end
		end)
	end
end

print("? Apocalypse Notifier cargado  RUSH MODE")

