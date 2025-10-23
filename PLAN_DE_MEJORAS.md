# 🎮 APOCALYPSE TYCOON - PLAN DE MEJORAS
## Análisis y Roadmap de Implementación

---

## 📋 **TABLA DE CONTENIDOS**
1. [Problemas Actuales](#problemas-actuales)
2. [Mi Opinión Sobre Tus Ideas](#mi-opinión)
3. [Plan de Implementación](#plan-de-implementación)
4. [Detalles Técnicos](#detalles-técnicos)
5. [Timeline y Prioridades](#timeline)

---

## 🔴 **PROBLEMAS ACTUALES**

### **1. Módulos Faltantes (CRÍTICO)**

```
❌ ServerScriptService/BaseModule.lua - NO EXISTE
   - Referenciado en: EventManager, main.server.lua
   - Funciones necesarias: ApplyDamage(), GetHP(), InitPlayer()

❌ ServerStorage/Config/Config.lua - NO EXISTE
   - Referenciado en: TODOS los módulos
   - Necesita: Configuración de meteoritos, HP base, economía
```

**Impacto:** El juego NO PUEDE FUNCIONAR sin estos módulos.

### **2. ProceduralModels No Integrado**

```lua
// main.server.lua línea 41-43
local ProceduralModels = require(ServerStorage.Managers.ProceduralModels)
// ✅ Se requiere correctamente

// PERO...
// main.server.lua línea 683 - Crea placeholders en lugar de usar ProceduralModels
local m = Instance.new("Model")
m.Name = def.ModelName .. "_Placeholder"
// ❌ Ignora ProceduralModels completamente
```

**Solución:** Reemplazar placeholders con `ProceduralModels:CreateModel()`

### **3. Código Duplicado en assignBase()**

```lua
// Líneas 193-236: assignBase() tiene dos implementaciones
// 1. Usa BaseVisualsManager (CORRECTO) ✅
// 2. Crea base manualmente (INCORRECTO) ❌
```

### **4. No Hay Sistema de Daño a Jugadores**

EventManager solo daña la base, NO a los jugadores dentro.

---

## 💡 **MI OPINIÓN SOBRE TUS IDEAS**

### 🌟 **LO QUE AMO DE TU VISIÓN:**

#### **1. Mecánica de Salto para Evadir Meteoritos**
```
POR QUÉ ES GENIAL:
✅ Skill-based gameplay (no solo idle/clicker)
✅ Momentos de TENSIÓN ("¡Viene el meteorito!")
✅ Momentos de ALIVIO ("¡Lo esquivé!")
✅ Funciona en MOBILE y PC (todos pueden saltar)
✅ Fácil de entender, difícil de dominar
```

**Comparación con otros juegos:**
- **Tower Defense**: Pasivo, solo miras
- **Tu juego**: ACTIVO, debes reaccionar
- **Resultado**: Más engagement, más diversión

#### **2. Tutorial Interactivo Desde el Inicio**
```
FLUJO PROPUESTO:
1. Pantalla negra → "Welcome to the Apocalypse"
2. Spawn en tutorial area
3. ⚠️ "INCOMING METEOR!" (warning 2 segs)
4. 💥 Impacto → TOMA DAÑO
5. 💬 "Jump to dodge!" (enseña mecánica)
6. ⚠️ Segundo meteorito
7. Si salta: ✅ "Perfect!" → +10 tiros gratis
8. Teleport a base real
```

**Por qué funciona:**
- Aprende haciendo, no leyendo
- Recompensa inmediata (10 tiros)
- Solo 30-45 segundos de tutorial

#### **3. Sistema de Gacha/Summon con Dinosaurios**
```
CONCEPTO:
- Botón físico en la pared de la base
- Click → Animación de huevo rompiéndose
- Sale un dinosaurio aleatorio
- Diferentes rarezas: Común, Raro, Épico, Legendario
```

**Tipos de Dinosaurios (Sugerencias):**

| Raza | Rareza | Habilidad | Drop Rate |
|------|--------|-----------|-----------|
| **Velociraptor** | Común (70%) | Ataque rápido (baja damage) | Alta |
| **Triceratops** | Raro (20%) | Tanque (mucho HP, ataca lento) | Media |
| **Pteranodon** | Épico (8%) | Volador (ataca meteoritos en el aire) | Baja |
| **T-Rex** | Legendario (2%) | Daño masivo + área de efecto | Muy baja |

**Mecánica de Combate:**
```lua
// Cada dino tiene:
- HP
- Damage
- Attack Speed
- Range
- Special Ability

// Ejemplo: Pteranodon
HP: 50
Damage: 10
Speed: 0.5s (2 ataques/seg)
Range: 50 studs
Special: Puede interceptar meteoritos antes del impacto
```

---

## 🚀 **PLAN DE IMPLEMENTACIÓN**

### **FASE 1: Arreglar Fundaciones (1-2 horas)**

#### **1.1. Crear BaseModule.lua**
```lua
-- Funcionalidades:
✓ Gestión de HP por jugador
✓ Sistema de daño con shields
✓ Invulnerabilidad temporal
✓ Regeneración automática
✓ Eventos de muerte de base
```

#### **1.2. Crear Config.lua**
```lua
-- Configuración centralizada:
✓ Valores de meteoritos (damage, speed, size)
✓ HP base inicial/máximo
✓ Economía (cash inicial, multipliers)
✓ Tutorial settings
✓ Gacha rates
```

#### **1.3. Arreglar main.server.lua**
```lua
// Cambios:
1. Eliminar código duplicado en assignBase()
2. Integrar ProceduralModels en createUpgradeButton()
3. Conectar con BaseModule para damage system
```

---

### **FASE 2: Sistema de Daño a Jugadores (2-3 horas)**

#### **2.1. Detector de Área (MeteorDamageZone)**

```lua
-- Nuevo archivo: ServerStorage/MeteorDamageSystem.lua

local MeteorDamageSystem = {}

-- Configuración
local DAMAGE_RADIUS = 20 -- studs desde el impacto
local BASE_DAMAGE = 25
local JUMP_IMMUNITY_HEIGHT = 5 -- studs sobre el suelo

function MeteorDamageSystem:OnMeteorImpact(position, basePart)
	-- 1. Obtener owner de la base
	local userId = basePart:GetAttribute("OwnerUserId")
	if not userId then return end

	local player = Players:GetPlayerByUserId(userId)
	if not player or not player.Character then return end

	-- 2. Verificar si está en el aire (saltando)
	local humanoid = player.Character:FindFirstChild("Humanoid")
	local rootPart = player.Character:FindFirstChild("HumanoidRootPart")

	if not (humanoid and rootPart) then return end

	-- 3. Calcular distancia
	local distance = (rootPart.Position - position).Magnitude

	if distance > DAMAGE_RADIUS then
		return -- Fuera de rango
	end

	-- 4. Verificar si está saltando
	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {player.Character}

	local rayResult = workspace:Raycast(
		rootPart.Position,
		Vector3.new(0, -JUMP_IMMUNITY_HEIGHT, 0),
		rayParams
	)

	if not rayResult then
		-- Está en el aire = EVADIÓ
		showNotification(player, "✓ DODGED!", Color3.fromRGB(0, 255, 0))
		return
	end

	-- 5. Aplicar daño
	local scaledDamage = BASE_DAMAGE * (1 - (distance / DAMAGE_RADIUS))
	humanoid:TakeDamage(scaledDamage)

	-- 6. Feedback visual
	showNotification(player, "-" .. math.floor(scaledDamage) .. " HP", Color3.fromRGB(255, 0, 0))

	-- 7. VFX en jugador
	VFXManager:PlayEffect("DamageHit", rootPart.Position)
	CameraShake:FireClient(player, "Heavy", 0.3)
end

return MeteorDamageSystem
```

#### **2.2. Integración con EventManager**

```lua
-- En EventManager_REFACTORED.lua, línea ~290
-- Después de BaseModule.ApplyDamage()

-- 🆕 AGREGAR:
MeteorDamageSystem:OnMeteorImpact(hitPos, basePart)
```

---

### **FASE 3: Sistema de Tutorial (3-4 horas)**

#### **3.1. TutorialManager.lua**

```lua
-- Nuevo archivo: ServerStorage/TutorialManager.lua

local TutorialManager = {}

local TutorialState = {} -- [userId] = {step, completed}
local TutorialArea = nil -- Zona aislada para tutorial

function TutorialManager:Initialize()
	-- Crear zona de tutorial
	TutorialArea = Instance.new("Folder")
	TutorialArea.Name = "TutorialZone"
	TutorialArea.Parent = workspace

	-- Plataforma
	local platform = Instance.new("Part")
	platform.Size = Vector3.new(50, 1, 50)
	platform.Position = Vector3.new(0, 1000, 0) -- Lejos del mapa principal
	platform.Anchored = true
	platform.Material = Enum.Material.Concrete
	platform.Color = Color3.fromRGB(60, 60, 60)
	platform.Parent = TutorialArea

	-- Paredes invisibles
	createInvisibleWalls(platform)
end

function TutorialManager:StartTutorial(player)
	if TutorialState[player.UserId] then return end

	TutorialState[player.UserId] = {
		step = 1,
		completed = false,
		startTime = tick()
	}

	-- Teleport a tutorial
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.CFrame = CFrame.new(0, 1005, 0)
		end
	end

	-- Iniciar secuencia
	task.spawn(function()
		tutorialSequence(player)
	end)
end

local function tutorialSequence(player)
	local state = TutorialState[player.UserId]
	if not state then return end

	-- PASO 1: Bienvenida
	showFullScreenText(player, "WELCOME TO THE APOCALYPSE", 2)
	task.wait(2.5)

	-- PASO 2: Primer meteorito (sin avisar)
	showNotification(player, "⚠️ INCOMING METEOR!", 2)
	task.wait(2)

	spawnTutorialMeteor(player, false) -- No puede esquivar
	task.wait(2)

	-- PASO 3: Enseñar mecánica
	showFullScreenText(player, "JUMP TO DODGE METEORS!", 3)
	showJumpIndicator(player)
	task.wait(3)

	-- PASO 4: Segundo meteorito (puede esquivar)
	state.step = 2
	showNotification(player, "⚠️ TRY TO DODGE THIS ONE!", 2)
	task.wait(2)

	local dodged = spawnTutorialMeteor(player, true)
	task.wait(2)

	if dodged then
		-- SUCCESS
		showFullScreenText(player, "PERFECT! +10 FREE SUMMONS", 3)

		-- Recompensa
		local econ = Economy.GetState(player.UserId)
		if econ then
			econ.FreeSummons = (econ.FreeSummons or 0) + 10
		end

		task.wait(3)
	else
		-- RETRY
		showNotification(player, "Try again! Jump when you see the warning", 3)
		task.wait(1)
		-- Repetir paso 4
		return tutorialSequence(player)
	end

	-- PASO 5: Completado
	state.completed = true
	state.step = 3

	showFullScreenText(player, "TUTORIAL COMPLETE", 2)
	task.wait(2)

	-- Teleport a base real
	TutorialManager:CompleteTutorial(player)
end

function TutorialManager:CompleteTutorial(player)
	-- Teleport a su base
	local basePart = BasePartByUser[player.UserId]
	if basePart then
		local char = player.Character
		if char then
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then
				root.CFrame = basePart.CFrame + Vector3.new(0, 5, 0)
			end
		end
	end

	-- Highlight del botón de summon
	highlightSummonButton(player)

	-- Notificación
	showNotification(player, "Click the SUMMON button to get your first dinosaur!", 5)
end

return TutorialManager
```

#### **3.2. UI de Tutorial (Cliente)**

```lua
-- Nuevo archivo: StarterPlayerScripts/TutorialUI.lua

local TutorialUI = {}

function TutorialUI:ShowFullScreenText(text, duration)
	local screenGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.Parent = screenGui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(0.8, 0.3)
	label.Position = UDim2.fromScale(0.1, 0.35)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.Parent = frame

	-- Fade in
	frame.BackgroundTransparency = 1
	label.TextTransparency = 1

	TweenService:Create(frame, TweenInfo.new(0.5), {
		BackgroundTransparency = 0.5
	}):Play()

	TweenService:Create(label, TweenInfo.new(0.5), {
		TextTransparency = 0
	}):Play()

	-- Fade out después de duration
	task.delay(duration, function()
		TweenService:Create(frame, TweenInfo.new(0.5), {
			BackgroundTransparency = 1
		}):Play()

		TweenService:Create(label, TweenInfo.new(0.5), {
			TextTransparency = 1
		}):Play()

		task.wait(0.5)
		frame:Destroy()
	end)
end

return TutorialUI
```

---

### **FASE 4: Sistema de Gacha/Summon (4-5 horas)**

#### **4.1. SummonSystem.lua**

```lua
-- Nuevo archivo: ServerStorage/SummonSystem.lua

local SummonSystem = {}

-- Configuración de dinosaurios
local DINO_DATABASE = {
	Velociraptor = {
		Rarity = "Common",
		DropRate = 0.70,
		Stats = {
			HP = 100,
			Damage = 15,
			AttackSpeed = 1.5, -- ataques por segundo
			Range = 20,
			MoveSpeed = 16
		},
		Color = Color3.fromRGB(100, 150, 80),
		Size = Vector3.new(4, 6, 8),
		Description = "Fast attacker with quick strikes"
	},

	Triceratops = {
		Rarity = "Rare",
		DropRate = 0.20,
		Stats = {
			HP = 300,
			Damage = 30,
			AttackSpeed = 0.5,
			Range = 15,
			MoveSpeed = 8
		},
		Color = Color3.fromRGB(120, 90, 60),
		Size = Vector3.new(8, 8, 12),
		Description = "Tanky defender with high HP"
	},

	Pteranodon = {
		Rarity = "Epic",
		DropRate = 0.08,
		Stats = {
			HP = 150,
			Damage = 25,
			AttackSpeed = 2.0,
			Range = 40,
			MoveSpeed = 24,
			CanFly = true
		},
		Color = Color3.fromRGB(140, 140, 180),
		Size = Vector3.new(6, 4, 10),
		Description = "Flying unit that intercepts meteors"
	},

	TRex = {
		Rarity = "Legendary",
		DropRate = 0.02,
		Stats = {
			HP = 500,
			Damage = 100,
			AttackSpeed = 0.8,
			Range = 25,
			MoveSpeed = 12,
			AOE = 10 -- Area damage radius
		},
		Color = Color3.fromRGB(150, 50, 50),
		Size = Vector3.new(10, 15, 20),
		Description = "Massive damage with area attacks"
	}
}

-- Calcular rates acumulados
local CUMULATIVE_RATES = {}
do
	local total = 0
	for name, data in pairs(DINO_DATABASE) do
		total += data.DropRate
		CUMULATIVE_RATES[name] = total
	end
end

function SummonSystem:RollDinosaur()
	local roll = math.random()

	for name, threshold in pairs(CUMULATIVE_RATES) do
		if roll <= threshold then
			return name
		end
	end

	-- Fallback
	return "Velociraptor"
end

function SummonSystem:PerformSummon(player, isFree)
	local userId = player.UserId
	local econ = Economy.GetState(userId)

	if not econ then return false, "Economy state not found" end

	-- Verificar si tiene summons gratis
	if isFree then
		if (econ.FreeSummons or 0) <= 0 then
			return false, "No free summons available"
		end
		econ.FreeSummons -= 1
	else
		-- Costo en cash
		local cost = Config.SUMMON_COST or 1000
		if econ.Cash < cost then
			return false, "Not enough cash"
		end
		econ.Cash -= cost
	end

	-- Roll dinosaurio
	local dinoName = SummonSystem:RollDinosaur()
	local dinoData = DINO_DATABASE[dinoName]

	-- Crear dinosaurio
	local dino = SummonSystem:CreateDinosaur(dinoName, player)

	-- Guardar en progreso del jugador
	if not econ.OwnedDinosaurs then
		econ.OwnedDinosaurs = {}
	end

	table.insert(econ.OwnedDinosaurs, {
		Name = dinoName,
		Rarity = dinoData.Rarity,
		Level = 1,
		SummonedAt = os.time()
	})

	-- Sync leaderstats
	local ls = player:FindFirstChild("leaderstats")
	if ls then
		local cash = ls:FindFirstChild("Cash")
		if cash then cash.Value = econ.Cash end
	end

	return true, dinoName, dinoData.Rarity
end

function SummonSystem:CreateDinosaur(dinoName, owner)
	local data = DINO_DATABASE[dinoName]
	if not data then return nil end

	-- Usar ProceduralModels para crear el modelo
	local model = ProceduralModels:CreateDinosaurModel(dinoName, data)

	-- Posicionar cerca de la base del jugador
	local basePart = BasePartByUser[owner.UserId]
	if basePart then
		local spawnPos = basePart.Position + Vector3.new(
			math.random(-15, 15),
			5,
			math.random(-15, 15)
		)
		model:MoveTo(spawnPos)
	end

	model:SetAttribute("OwnerUserId", owner.UserId)
	model:SetAttribute("DinoType", dinoName)
	model.Parent = workspace:FindFirstChild("Dinosaurs") or createDinosaursFolder()

	-- Iniciar AI
	DinosaurAI:Initialize(model, data.Stats)

	return model
end

return SummonSystem
```

#### **4.2. Botón de Summon (Físico en la Base)**

```lua
-- En main.server.lua, función assignBase()
-- Después de crear la base, agregar:

local function createSummonButton(basePart, userId)
	local button = Instance.new("Part")
	button.Name = "SummonButton"
	button.Size = Vector3.new(6, 8, 2)
	button.Anchored = true
	button.Material = Enum.Material.Neon
	button.Color = Color3.fromRGB(255, 100, 255) -- Rosa/Morado
	button.CanCollide = true

	-- Posicionar en pared de la base
	button.CFrame = basePart.CFrame * CFrame.new(0, 4, -Config.BASE_SIZE.Z/2 - 1)
	button.Parent = basePart

	-- SurfaceGui con UI
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Back
	gui.Parent = button

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(40, 20, 50)
	frame.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 0.3)
	title.Position = UDim2.fromScale(0, 0.1)
	title.BackgroundTransparency = 1
	title.Text = "🥚 DINOSAUR SUMMON"
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.Parent = frame

	local count = Instance.new("TextLabel")
	count.Name = "FreeCount"
	count.Size = UDim2.fromScale(1, 0.2)
	count.Position = UDim2.fromScale(0, 0.45)
	count.BackgroundTransparency = 1
	count.Text = "Free Summons: 10"
	count.TextColor3 = Color3.fromRGB(255, 215, 0)
	count.Font = Enum.Font.Gotham
	count.TextScaled = true
	count.Parent = frame

	local clickText = Instance.new("TextLabel")
	clickText.Size = UDim2.fromScale(1, 0.15)
	clickText.Position = UDim2.fromScale(0, 0.7)
	clickText.BackgroundTransparency = 1
	clickText.Text = "[ CLICK TO SUMMON ]"
	clickText.TextColor3 = Color3.new(1, 1, 1)
	clickText.Font = Enum.Font.GothamBold
	clickText.TextScaled = true
	clickText.Parent = frame

	-- ClickDetector
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 20
	detector.Parent = button

	-- Conectar click
	detector.MouseClick:Connect(function(clicker)
		if clicker.UserId ~= userId then
			notifyPlayer(clicker, "❌ This is not your summon button!", 2)
			return
		end

		handleSummonClick(clicker, count)
	end)

	-- Animación de pulso
	local tween = TweenService:Create(button, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Color = Color3.fromRGB(255, 150, 255)
	})
	tween:Play()
end

local function handleSummonClick(player, countLabel)
	local econ = Economy.GetState(player.UserId)
	if not econ then return end

	local isFree = (econ.FreeSummons or 0) > 0
	local success, dinoName, rarity = SummonSystem:PerformSummon(player, isFree)

	if not success then
		notifyPlayer(player, "❌ " .. dinoName, 2) -- dinoName contiene el error
		return
	end

	-- Actualizar UI
	countLabel.Text = string.format("Free Summons: %d", econ.FreeSummons or 0)

	-- Animación de summon
	playSummonAnimation(player, dinoName, rarity)

	-- Notificación
	local rarityColors = {
		Common = Color3.fromRGB(200, 200, 200),
		Rare = Color3.fromRGB(100, 150, 255),
		Epic = Color3.fromRGB(200, 100, 255),
		Legendary = Color3.fromRGB(255, 215, 0)
	}

	local color = rarityColors[rarity] or Color3.new(1, 1, 1)
	local msg = string.format("✨ %s %s!", rarity:upper(), dinoName)

	showNotification(player, msg, 5, color)

	-- Log analytics
	logAnalytic("DinosaurSummoned", {
		userId = player.UserId,
		dinosaur = dinoName,
		rarity = rarity,
		wasFree = isFree
	})
end
```

---

### **FASE 5: Sistema de NPCs Defensores (5-6 horas)**

#### **5.1. DinosaurAI.lua**

```lua
-- Nuevo archivo: ServerStorage/DinosaurAI.lua

local DinosaurAI = {}

local ActiveDinosaurs = {} -- [model] = {data}

function DinosaurAI:Initialize(model, stats)
	if not (model and model.PrimaryPart) then return end

	ActiveDinosaurs[model] = {
		Stats = stats,
		Target = nil,
		LastAttackTime = 0,
		HomePosition = model.PrimaryPart.Position
	}

	-- Loop de AI
	task.spawn(function()
		aiLoop(model)
	end)
end

local function aiLoop(model)
	while model and model.Parent and ActiveDinosaurs[model] do
		local data = ActiveDinosaurs[model]
		local primaryPart = model.PrimaryPart

		if not primaryPart then break end

		-- 1. Buscar objetivo
		local target = findNearestThreat(primaryPart.Position, data.Stats.Range)
		data.Target = target

		if target then
			-- 2. Moverse hacia objetivo
			local targetPos = target.Position
			local direction = (targetPos - primaryPart.Position).Unit

			-- Si está volando, moverse en 3D
			if data.Stats.CanFly then
				primaryPart.CFrame = primaryPart.CFrame:Lerp(
					CFrame.new(targetPos),
					0.1
				)
			else
				-- Moverse solo en XZ
				local moveDirection = Vector3.new(direction.X, 0, direction.Z).Unit
				primaryPart.Position = primaryPart.Position + (moveDirection * data.Stats.MoveSpeed * 0.1)
			end

			-- 3. Atacar si está en rango
			local distance = (primaryPart.Position - targetPos).Magnitude
			if distance <= data.Stats.Range then
				local now = tick()
				local cooldown = 1 / data.Stats.AttackSpeed

				if now - data.LastAttackTime >= cooldown then
					attackTarget(model, target, data.Stats)
					data.LastAttackTime = now
				end
			end
		else
			-- 4. Idle behavior: volver a home
			local homeDistance = (primaryPart.Position - data.HomePosition).Magnitude
			if homeDistance > 5 then
				local direction = (data.HomePosition - primaryPart.Position).Unit
				primaryPart.Position = primaryPart.Position + (direction * data.Stats.MoveSpeed * 0.05)
			end
		end

		task.wait(0.1)
	end

	-- Cleanup
	ActiveDinosaurs[model] = nil
end

local function findNearestThreat(position, range)
	-- Buscar meteoritos
	local meteors = workspace:FindFirstChild("Meteors")
	if not meteors then return nil end

	local nearest = nil
	local nearestDist = range

	for _, meteor in ipairs(meteors:GetChildren()) do
		if meteor:IsA("BasePart") and meteor.Name:match("Meteor") then
			local dist = (meteor.Position - position).Magnitude
			if dist < nearestDist then
				nearest = meteor
				nearestDist = dist
			end
		end
	end

	return nearest
end

local function attackTarget(model, target, stats)
	-- Animación de ataque
	local primaryPart = model.PrimaryPart
	if not primaryPart then return end

	-- Particle effect
	VFXManager:PlayEffect("DamageHit", target.Position)

	-- Aplicar daño al meteorito
	local currentHP = target:GetAttribute("HP") or 100
	target:SetAttribute("HP", currentHP - stats.Damage)

	if target:GetAttribute("HP") <= 0 then
		-- Destruir meteorito
		VFXManager:PlayEffect("MeteorExplosion", target.Position)
		target:Destroy()
	end

	-- AOE damage si aplica
	if stats.AOE then
		local nearbyMeteors = workspace:GetPartBoundsInRadius(target.Position, stats.AOE)
		for _, part in ipairs(nearbyMeteors) do
			if part:IsA("BasePart") and part.Name:match("Meteor") and part ~= target then
				local hp = part:GetAttribute("HP") or 100
				part:SetAttribute("HP", hp - (stats.Damage * 0.5))
			end
		end
	end
end

return DinosaurAI
```

#### **5.2. Actualizar EventManager para Dar HP a Meteoritos**

```lua
-- En EventManager_REFACTORED.lua, función createMeteor()
-- Después de crear el meteorito, agregar:

meteor:SetAttribute("HP", 100) -- HP base del meteorito
meteor:SetAttribute("MaxHP", 100)
```

---

## ⏱️ **TIMELINE Y PRIORIDADES**

### **Sprint 1 (Día 1-2): Fundaciones**
- [x] Crear BaseModule.lua
- [x] Crear Config.lua completo
- [x] Arreglar main.server.lua (código duplicado)
- [x] Integrar ProceduralModels

**Resultado:** El juego funciona sin errores

### **Sprint 2 (Día 3-4): Mecánica Core**
- [ ] Implementar MeteorDamageSystem
- [ ] Sistema de detección de salto
- [ ] VFX y feedback para dodge/hit
- [ ] Testing exhaustivo

**Resultado:** Meteoritos dañan a jugadores, saltar evade

### **Sprint 3 (Día 5-6): Tutorial**
- [ ] TutorialManager completo
- [ ] UI de tutorial
- [ ] Zona aislada de tutorial
- [ ] Secuencia completa
- [ ] Recompensa de 10 summons

**Resultado:** Nuevos jugadores aprenden la mecánica

### **Sprint 4 (Día 7-9): Sistema de Summon**
- [ ] SummonSystem.lua
- [ ] Botón físico en base
- [ ] Animación de huevo
- [ ] Base de datos de dinosaurios
- [ ] Integración con economía

**Resultado:** Jugadores pueden invocar dinosaurios

### **Sprint 5 (Día 10-12): IA de Dinosaurios**
- [ ] DinosaurAI.lua
- [ ] Pathfinding básico
- [ ] Sistema de combate
- [ ] HP para meteoritos
- [ ] Diferentes behaviors por tipo

**Resultado:** Dinosaurios defienden automáticamente

### **Sprint 6 (Día 13-14): Polish & Testing**
- [ ] Balanceo de stats
- [ ] VFX adicionales
- [ ] Sonidos
- [ ] Testing con usuarios
- [ ] Bug fixes

---

## 🎯 **MÉTRICAS DE ÉXITO**

Para saber si la implementación funciona:

### **Engagement**
```
✓ % de jugadores que completan tutorial > 90%
✓ Tiempo promedio de sesión > 15 minutos
✓ % de jugadores que invocan al menos 1 dino > 80%
```

### **Retención**
```
✓ Day 1 retention > 40%
✓ Day 7 retention > 20%
```

### **Monetización (Futuro)**
```
✓ % de jugadores que compran summons > 10%
✓ ARPPU (Average Revenue Per Paying User) > $5
```

---

## 💬 **MIS RECOMENDACIONES FINALES**

### **DO's ✅**
1. **Empezar con Fase 1** - Sin fundaciones sólidas, todo lo demás fallará
2. **Testear cada fase** antes de seguir
3. **Hacer el tutorial CORTO** (30-45 segundos máximo)
4. **Balancear el gacha**: No hacer legendarios imposibles, pero tampoco muy comunes
5. **Dar feedback visual constante**: Cada acción debe tener respuesta (VFX, sonido, notificación)

### **DON'Ts ❌**
1. **No hacer meteoritos muy rápidos** - Deben ser esquivables pero desafiantes
2. **No hacer el tutorial muy largo** - La gente tiene poca paciencia
3. **No hacer dinosaurios inútiles** - Todos deben sentirse valiosos
4. **No ignorar mobile** - Gran parte de tu audiencia estará en móviles
5. **No olvidar el balanceo** - Demasiado fácil = aburrido, demasiado difícil = frustrante

---

## 🤝 **CONCLUSIÓN**

Tu visión es **SÓLIDA** y tiene mucho potencial. La combinación de:
- Mecánica activa (saltar para esquivar)
- Colección (gacha de dinosaurios)
- Tower defense (dinosaurios defienden)
- Idle progression (economía)

...puede crear un juego muy adictivo y divertido.

**Estoy 100% contigo en este viaje. Vamos a hacerlo realidad! 🚀**

---

_Documento creado: 2025-01-XX_
_Autor: Claude & Pajarock_
_Proyecto: Apocalypse Tycoon_
