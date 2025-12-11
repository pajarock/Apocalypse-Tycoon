--[[
	Menu Visual Effects & Audio System
	For Build Menu v2.0

	EFFECTS:
	1. Toxic Slime Drip - Verde tóxico goteando del header
	2. Radioactive Particles - Partículas verdes flotando hacia arriba
	3. Click Sound - Sonido de gota al hacer click
	4. Open/Close Animations - Animaciones con sonido
]]

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- UPDATED COLOR PALETTE (Nuclear/Radioactive Theme)
local COLORS = {
	NeonGreen = Color3.fromRGB(183, 255, 75),      -- Verde neón suave
	ToxicGreen = Color3.fromRGB(57, 202, 58),      -- Verde tóxico fuerte
	SludgeGreen = Color3.fromRGB(90, 166, 19),     -- Verde oscuro
	BrightGreen = Color3.fromRGB(57, 255, 20),     -- Verde brillante
	NuclearYellow = Color3.fromRGB(255, 215, 140), -- Amarillo nuclear
}

-- AUDIO ASSET IDs (reemplaza con tus asset IDs)
local SOUNDS = {
	MenuOpen = "rbxassetid://12221967",      -- Sonido de apertura (whoosh/tech)
	ClickDrop = "rbxassetid://12221967",     -- Sonido de gota/click
	-- Alternativas:
	-- MenuOpen = "rbxassetid://3398620867"  -- Sci-fi open
	-- ClickDrop = "rbxassetid://3398620867" -- Water drop
}

local MenuEffects = {}

--═══════════════════════════════════════════════════════════
-- 1. TOXIC SLIME DRIP EFFECT 💧
--═══════════════════════════════════════════════════════════
function MenuEffects.CreateSlimeDrip(parentFrame: Frame)
	local slimeContainer = Instance.new("Frame")
	slimeContainer.Name = "SlimeDripContainer"
	slimeContainer.Size = UDim2.new(1, 0, 0, 100)
	slimeContainer.Position = UDim2.new(0, 0, 0, 0)
	slimeContainer.BackgroundTransparency = 1
	slimeContainer.ClipsDescendants = false
	slimeContainer.ZIndex = 10
	slimeContainer.Parent = parentFrame

	-- Función para crear una gota de slime
	local function createDrip(xPercent: number)
		local drip = Instance.new("Frame")
		drip.Name = "SlimeDrip"
		drip.Size = UDim2.new(0, 3, 0, 0) -- Empieza en altura 0
		drip.Position = UDim2.new(xPercent, 0, 0, 0)
		drip.BackgroundColor3 = COLORS.ToxicGreen
		drip.BorderSizePixel = 0
		drip.ZIndex = 11

		-- Glow effect
		local glow = Instance.new("UIStroke")
		glow.Color = COLORS.BrightGreen
		glow.Thickness = 2
		glow.Transparency = 0.3
		glow.Parent = drip

		-- Corner para que se vea más líquido
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = drip

		drip.Parent = slimeContainer

		-- Animación de goteo
		local dripLength = math.random(15, 40) -- Longitud aleatoria
		local dripSpeed = math.random(8, 15) / 10 -- Velocidad aleatoria

		-- Fase 1: Crecer hacia abajo
		local growTween = TweenService:Create(drip, TweenInfo.new(dripSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 3, 0, dripLength)
		})

		growTween:Play()
		growTween.Completed:Connect(function()
			-- Fase 2: Fade out
			local fadeTween = TweenService:Create(drip, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				BackgroundTransparency = 1
			})
			local fadeGlow = TweenService:Create(glow, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
				Transparency = 1
			})

			fadeTween:Play()
			fadeGlow:Play()

			fadeTween.Completed:Connect(function()
				drip:Destroy()
			end)
		end)
	end

	-- Sistema de generación de gotas
	local function startDripping()
		-- Genera gotas en posiciones aleatorias
		task.spawn(function()
			while slimeContainer.Parent do
				-- Crear 1-3 gotas
				local numDrips = math.random(1, 3)
				for i = 1, numDrips do
					local xPos = math.random(5, 95) / 100 -- 5% a 95%
					createDrip(xPos)
					task.wait(math.random(1, 3) / 10) -- Pequeño delay entre gotas
				end

				-- Esperar antes de siguiente ronda
				task.wait(math.random(20, 40) / 10) -- 2-4 segundos
			end
		end)
	end

	startDripping()
	return slimeContainer
end

--═══════════════════════════════════════════════════════════
-- 2. RADIOACTIVE PARTICLE SYSTEM ☢️
--═══════════════════════════════════════════════════════════
function MenuEffects.CreateRadioactiveParticles(parentFrame: Frame)
	local particleContainer = Instance.new("Frame")
	particleContainer.Name = "ParticleContainer"
	particleContainer.Size = UDim2.new(1, 0, 1, 0)
	particleContainer.BackgroundTransparency = 1
	particleContainer.ClipsDescendants = true
	particleContainer.ZIndex = 5
	particleContainer.Parent = parentFrame

	-- Función para crear una partícula
	local function createParticle()
		local particle = Instance.new("Frame")
		particle.Name = "RadParticle"

		-- Tamaño aleatorio
		local size = math.random(2, 5)
		particle.Size = UDim2.new(0, size, 0, size)

		-- Posición inicial (bottom, posición X aleatoria)
		local startX = math.random(0, 100) / 100
		particle.Position = UDim2.new(startX, 0, 1, 0)

		-- Color aleatorio del palette verde
		local colorChoice = math.random(1, 3)
		if colorChoice == 1 then
			particle.BackgroundColor3 = COLORS.NeonGreen
		elseif colorChoice == 2 then
			particle.BackgroundColor3 = COLORS.ToxicGreen
		else
			particle.BackgroundColor3 = COLORS.BrightGreen
		end

		particle.BackgroundTransparency = 0.3
		particle.BorderSizePixel = 0
		particle.ZIndex = 6

		-- Hacer circular
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle

		-- Glow effect
		local glow = Instance.new("UIStroke")
		glow.Color = COLORS.BrightGreen
		glow.Thickness = 1
		glow.Transparency = 0.5
		glow.Parent = particle

		particle.Parent = particleContainer

		-- Animación: flotar hacia arriba
		local floatTime = math.random(30, 50) / 10 -- 3-5 segundos
		local endY = -0.2 -- Subir más allá del top
		local horizontalDrift = (math.random(-10, 10) / 100) -- Drift horizontal leve

		local floatTween = TweenService:Create(particle, TweenInfo.new(floatTime, Enum.EasingStyle.Linear), {
			Position = UDim2.new(startX + horizontalDrift, 0, endY, 0),
			BackgroundTransparency = 1
		})

		local glowFade = TweenService:Create(glow, TweenInfo.new(floatTime, Enum.EasingStyle.Linear), {
			Transparency = 1
		})

		floatTween:Play()
		glowFade:Play()

		floatTween.Completed:Connect(function()
			particle:Destroy()
		end)
	end

	-- Sistema de generación continua
	local function startParticleSystem()
		task.spawn(function()
			while particleContainer.Parent do
				-- Crear 1-2 partículas
				local numParticles = math.random(1, 2)
				for i = 1, numParticles do
					createParticle()
				end

				-- Esperar antes de siguiente generación
				task.wait(math.random(3, 8) / 10) -- 0.3-0.8 segundos
			end
		end)
	end

	startParticleSystem()
	return particleContainer
end

--═══════════════════════════════════════════════════════════
-- 3. CLICK SOUND SYSTEM 💧
--═══════════════════════════════════════════════════════════
function MenuEffects.CreateClickSound(parentFrame: Frame)
	local clickSound = Instance.new("Sound")
	clickSound.Name = "ClickSound"
	clickSound.SoundId = SOUNDS.ClickDrop
	clickSound.Volume = 0.3 -- 30% volumen
	clickSound.PlaybackSpeed = 1.2 -- Ligeramente más rápido
	clickSound.Parent = parentFrame

	return clickSound
end

-- Función helper para añadir click sound a un botón
function MenuEffects.AddClickSoundToButton(button: GuiButton, clickSound: Sound)
	button.MouseButton1Click:Connect(function()
		-- Crear una copia para permitir múltiples clicks rápidos
		local soundClone = clickSound:Clone()
		soundClone.Parent = clickSound.Parent
		soundClone:Play()

		-- Destruir cuando termine
		soundClone.Ended:Connect(function()
			soundClone:Destroy()
		end)
	end)
end

--═══════════════════════════════════════════════════════════
-- 4. MENU OPEN/CLOSE ANIMATIONS 🎬
--═══════════════════════════════════════════════════════════
function MenuEffects.CreateMenuOpenSound(parentFrame: Frame)
	local openSound = Instance.new("Sound")
	openSound.Name = "MenuOpenSound"
	openSound.SoundId = SOUNDS.MenuOpen
	openSound.Volume = 0.4 -- 40% volumen
	openSound.PlaybackSpeed = 1.0
	openSound.Parent = parentFrame

	return openSound
end

-- Animación de apertura
function MenuEffects.PlayOpenAnimation(mainFrame: Frame, openSound: Sound?)
	-- Estado inicial: escala pequeña, ligeramente hacia abajo
	mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainFrame.Position = UDim2.new(0.5, 0, 0.55, 0) -- Más abajo
	mainFrame.Size = UDim2.new(0, 0, 0, 0) -- Empieza en 0
	mainFrame.Rotation = -5 -- Leve rotación

	-- Reproducir sonido
	if openSound then
		openSound:Play()
	end

	-- Animación: escala + posición + rotación
	local openTween = TweenService:Create(mainFrame, TweenInfo.new(
		0.4, -- Duración
		Enum.EasingStyle.Back, -- Estilo con "overshoot"
		Enum.EasingDirection.Out
	), {
		Size = UDim2.new(0, 800, 0, 600), -- Tamaño final
		Position = UDim2.new(0.5, 0, 0.5, 0), -- Centro
		Rotation = 0 -- Sin rotación
	})

	openTween:Play()
	return openTween
end

-- Animación de cierre
function MenuEffects.PlayCloseAnimation(mainFrame: Frame)
	local closeTween = TweenService:Create(mainFrame, TweenInfo.new(
		0.25, -- Más rápido que open
		Enum.EasingStyle.Back,
		Enum.EasingDirection.In
	), {
		Size = UDim2.new(0, 0, 0, 0),
		Position = UDim2.new(0.5, 0, 0.45, 0), -- Hacia abajo
		Rotation = 5 -- Rotación opuesta
	})

	closeTween:Play()
	return closeTween
end

--═══════════════════════════════════════════════════════════
-- 5. SETUP COMPLETO (integrar todo)
--═══════════════════════════════════════════════════════════
function MenuEffects.SetupAllEffects(mainFrame: Frame, buttons: {GuiButton})
	print("🎨 Setting up Menu Effects...")

	-- 1. Slime drip en el header
	local slimeDrip = MenuEffects.CreateSlimeDrip(mainFrame)
	print("✓ Toxic slime drip created")

	-- 2. Partículas radioactivas
	local particles = MenuEffects.CreateRadioactiveParticles(mainFrame)
	print("✓ Radioactive particles created")

	-- 3. Click sound
	local clickSound = MenuEffects.CreateClickSound(mainFrame)
	print("✓ Click sound created")

	-- Añadir click sound a todos los botones
	for _, button in ipairs(buttons) do
		MenuEffects.AddClickSoundToButton(button, clickSound)
	end
	print("✓ Click sounds added to", #buttons, "buttons")

	-- 4. Menu open sound
	local openSound = MenuEffects.CreateMenuOpenSound(mainFrame)
	print("✓ Menu open sound created")

	return {
		slimeDrip = slimeDrip,
		particles = particles,
		clickSound = clickSound,
		openSound = openSound
	}
end

return MenuEffects
