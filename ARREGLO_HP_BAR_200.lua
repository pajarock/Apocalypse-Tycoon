--[[
═══════════════════════════════════════════════════════════════════════
🔧 ARREGLO: Barra de HP Visual Bloqueada en 100
═══════════════════════════════════════════════════════════════════════

PROBLEMA:
Con upgrades de muros, el HP sube hasta 200 en el backend,
pero la barra visual se queda en 100 y no sube.
- Baja correctamente con daño
- NO sube con reparaciones cuando está arriba de 100

CAUSA:
La función UpdateBaseVisuals está calculando hpPercent basado en MaxHP fijo (100)
en lugar del MaxHP actual del jugador.

SOLUCIÓN:
Pasar el MaxHP correcto a UpdateBaseVisuals y actualizar el texto.
═══════════════════════════════════════════════════════════════════════
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 1: VERIFICAR BaseVisualsManager.UpdateBaseVisuals
--═══════════════════════════════════════════════════════════════════════

--[[
Archivo: ServerStorage.Managers.BaseVisualsManager

Busca la función UpdateBaseVisuals (línea ~476):

function BaseVisualsManager:UpdateBaseVisuals(userId: number, currentHP: number, maxHP: number)
	local data = BaseData[userId]
	if not data or not data.base or not data.base.Parent then
		return
	end

	-- ✅ VERIFICAR QUE USE maxHP (parámetro)
	local hpPercent = currentHP / maxHP  -- ← DEBE USAR maxHP del parámetro

	-- Actualizar billboard
	local billboard = data.base:FindFirstChild("BaseBillboard")
	if billboard and billboard:IsA("BillboardGui") then
		local frame = billboard:FindFirstChild("Frame")
		if not frame then return end

		-- HP Bar
		local hpBarBg = frame:FindFirstChild("HPBarBg")
		local hpBar = hpBarBg and hpBarBg:FindFirstChild("HPBar")
		local hpLabel = frame:FindFirstChild("HPLabel")

		if hpBar then
			-- ✅ Animar barra con porcentaje correcto
			TweenService:Create(
				hpBar,
				TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{Size = UDim2.fromScale(hpPercent, 1)}
			):Play()

			-- Color según HP
			if hpPercent > 0.7 then
				hpBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
			elseif hpPercent > 0.3 then
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 200, 0)
			else
				hpBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			end
		end

		if hpLabel then
			-- ✅ IMPORTANTE: Mostrar HP actual vs MaxHP real
			hpLabel.Text = string.format("HP: %d/%d", currentHP, maxHP)
		end
	end

	-- Resto del código de efectos...
end

SI EL CÓDIGO YA ESTÁ ASÍ, SALTA AL PASO 2.
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 2: VERIFICAR LLAMADAS A UpdateBaseVisuals
--═══════════════════════════════════════════════════════════════════════

--[[
Hay que asegurarse de que TODAS las llamadas a UpdateBaseVisuals
pasen el MaxHP CORRECTO (no siempre 100).

LUGARES QUE LLAMAN UpdateBaseVisuals:

1. BaseModule.OnBaseDead (línea ~470)
2. Main.Server - RequestRepair (línea ~932)
3. Cualquier lugar que actualice HP

VERIFICAR CADA UNO:
]]

-- Archivo: ServerScriptService.BaseModule
-- Función: OnBaseDead (línea ~470)
--
-- DEBE SER:
BaseVisualsManager.UpdateBaseVisuals(userId, respawnHP, Config.BASE_MAX_HP)
--
-- ❌ NO: BaseVisualsManager.UpdateBaseVisuals(userId, respawnHP, 100)

-- Archivo: ServerScriptService.Main.Server
-- Función: RequestRepair handler (línea ~932)
--
-- BUSCAR:
BaseStateChanged:FireClient(plr, {
	UserId = plr.UserId,
	BaseHP = Base.GetHP(plr.UserId),
	MaxHP = max,  -- ← VERIFICAR QUE SEA Variable, no 100 fijo
})

--═══════════════════════════════════════════════════════════════════════
-- PASO 3: VERIFICAR Config.BASE_MAX_HP SE ACTUALIZA
--═══════════════════════════════════════════════════════════════════════

--[[
Cuando compras upgrades de muros (Upgrade_7), el código debería
aumentar Config.BASE_MAX_HP:

Archivo: ServerScriptService.Main.Server
Ubicación: RequestPurchase handler, efectos especiales (línea ~822)

DEBE TENER ALGO COMO:
]]

if upgradeId == "Upgrade_7" then
	Config.BASE_MAX_HP += 5
	Base.AddHP(plr.UserId, 5)

	-- ✅ AGREGAR: Actualizar visuales después de aumentar MaxHP
	local baseVisuals = ServerStorage.Managers:FindFirstChild("BaseVisualsManager")
	if baseVisuals then
		local BaseVisualsManager = require(baseVisuals)
		BaseVisualsManager.UpdateBaseVisuals(
			plr.UserId,
			Base.GetHP(plr.UserId),
			Config.BASE_MAX_HP  -- ← MaxHP nuevo
		)
	end

	if DEBUG then
		print(("[PURCHASE] Max HP aumentado a %d"):format(Config.BASE_MAX_HP))
	end
end

--[[
⚠️ PROBLEMA POTENCIAL:
Si Config.BASE_MAX_HP es GLOBAL para todos los jugadores,
aumentará para TODOS cada vez que ALGUIEN compre.

SOLUCIÓN: Usar BaseState[userId].MaxHP individual
]]

--═══════════════════════════════════════════════════════════════════════
-- PASO 4: SOLUCIÓN ROBUSTA - MaxHP Individual por Jugador
--═══════════════════════════════════════════════════════════════════════

--[[
Si quieres que cada jugador tenga su propio MaxHP:

Archivo: ServerScriptService.BaseModule
Función: InitPlayer (línea ~66)
]]

function BaseModule.InitPlayer(userId: number)
	if BaseState[userId] then
		if DEBUG then
			warn(("[BaseModule] Usuario %d ya inicializado"):format(userId))
		end
		return
	end

	BaseState[userId] = {
		HP = Config.BASE_MAX_HP,
		MaxHP = Config.BASE_MAX_HP,  -- ✅ MaxHP individual
		LastDamageTime = 0,
		IsInvulnerable = false,
		ShieldLevel = 0,
		MeteorsSurvived = 0,
		RegenEnabled = true
	}

	if DEBUG then
		print(("[BaseModule] Inicializado userId %d - HP: %d"):format(userId, Config.BASE_MAX_HP))
	end
end

-- Crear función para aumentar MaxHP individual:

function BaseModule.IncreaseMaxHP(userId: number, amount: number)
	if not BaseState[userId] then return end

	BaseState[userId].MaxHP += amount
	BaseState[userId].HP = math.min(
		BaseState[userId].HP + amount,
		BaseState[userId].MaxHP
	)

	if DEBUG then
		print(("[BaseModule] Max HP aumentado - userId %d: %d"):format(
			userId, BaseState[userId].MaxHP
		))
	end

	-- Actualizar visuales
	local BaseVisualsManager = require(game.ServerStorage.Managers.BaseVisualsManager)
	BaseVisualsManager.UpdateBaseVisuals(
		userId,
		BaseState[userId].HP,
		BaseState[userId].MaxHP
	)
end

-- Getter para MaxHP
function BaseModule.GetMaxHP(userId: number): number
	if not BaseState[userId] then
		return Config.BASE_MAX_HP
	end

	return BaseState[userId].MaxHP
end

--[[
Luego en Main.Server, cuando compren Upgrade_7:
]]

if upgradeId == "Upgrade_7" then
	-- ✅ Aumentar MaxHP individual del jugador
	Base.IncreaseMaxHP(plr.UserId, 5)

	if DEBUG then
		print(("[PURCHASE] Max HP de %s aumentado a %d"):format(
			plr.Name, Base.GetMaxHP(plr.UserId)
		))
	end
end

--═══════════════════════════════════════════════════════════════════════
-- TESTING
--═══════════════════════════════════════════════════════════════════════

--[[
1. Aplica los cambios
2. Reinicia el servidor
3. Compra varios Upgrade_7 (Muros)
4. Verifica Output:
   [PURCHASE] Max HP de TuNombre aumentado a 105
   [PURCHASE] Max HP de TuNombre aumentado a 110
   ...
   [PURCHASE] Max HP de TuNombre aumentado a 200

5. Verifica visual:
   - Billboard muestra "HP: 200/200"
   - Barra está llena (verde)

6. Recibe daño:
   - Billboard muestra "HP: 150/200"
   - Barra al 75% (verde/amarillo)

7. Repara:
   - Billboard sube "HP: 180/200"
   - Barra sube al 90%

RESULTADO ESPERADO:
✅ Barra sube y baja correctamente hasta 200
✅ Texto muestra "HP: X/200"
✅ Porcentaje visual correcto
]]

--═══════════════════════════════════════════════════════════════════════
-- RESUMEN DE CAMBIOS
--═══════════════════════════════════════════════════════════════════════

--[[
1. ✅ Agregar MaxHP individual en BaseState
2. ✅ Crear BaseModule.IncreaseMaxHP()
3. ✅ Actualizar BaseModule.GetMaxHP()
4. ✅ Modificar compra de Upgrade_7 para usar IncreaseMaxHP
5. ✅ Verificar que UpdateBaseVisuals use maxHP parámetro
6. ✅ Actualizar todas las llamadas a UpdateBaseVisuals

ARCHIVOS MODIFICADOS:
- ServerScriptService.BaseModule (funciones nuevas)
- ServerScriptService.Main.Server (compra Upgrade_7)
- ServerStorage.Managers.BaseVisualsManager (si necesita corrección)
]]
