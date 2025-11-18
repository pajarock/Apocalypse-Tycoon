--[[
	POWER-UPS VERIFICATION SCRIPT
	═══════════════════════════════════════════════════════════════════════

	INSTRUCCIONES:
	1. Abre Roblox Studio
	2. Presiona F9 para abrir la consola
	3. En la pestaña "Server", pega este script completo
	4. Presiona Enter
	5. Lee los resultados - te dirá qué archivos faltan actualizar

	IMPORTANTE: Este script SOLO verifica, NO modifica nada.
]]

print("\n" .. string.rep("=", 70))
print("🔍 VERIFICACIÓN DE POWER-UPS SYSTEM")
print(string.rep("=", 70))

local issues = {}
local success = {}

-- ========================
-- 1. VERIFICAR BaseModule
-- ========================
print("\n📦 Verificando BaseModule...")

local BaseModule = game.ServerScriptService:FindFirstChild("BaseModule")
if not BaseModule then
	table.insert(issues, "❌ BaseModule no encontrado en ServerScriptService")
else
	-- Leer el código fuente
	local source = BaseModule.Source

	-- Buscar el check de Shield Bubble
	if source:find("ShieldActive") and source:find("Shield Bubble") then
		table.insert(success, "✅ BaseModule tiene integración de Shield Bubble")
	else
		table.insert(issues, "❌ BaseModule NO tiene el check de ShieldActive (línea 336-355)")
		table.insert(issues, "   → Copia BaseModule.lua de GitHub a Studio")
	end

	-- Buscar función Heal
	if source:find("function BaseModule.Heal") then
		table.insert(success, "✅ BaseModule tiene función Heal() para Auto-Repair")
	else
		table.insert(issues, "❌ BaseModule NO tiene función Heal() (línea 695-734)")
		table.insert(issues, "   → Copia BaseModule.lua de GitHub a Studio")
	end
end

-- ========================
-- 2. VERIFICAR EconomyModule
-- ========================
print("\n💰 Verificando EconomyModule...")

local EconomyModule = game.ServerScriptService:FindFirstChild("EconomyModule")
if not EconomyModule then
	table.insert(issues, "❌ EconomyModule no encontrado en ServerScriptService")
else
	local source = EconomyModule.Source

	if source:find("CoinMultiplier") and source:find("Coin Rain") then
		table.insert(success, "✅ EconomyModule tiene multiplicador de Coin Rain")
	else
		table.insert(issues, "❌ EconomyModule NO tiene integración de Coin Rain (línea 848-866)")
		table.insert(issues, "   → Copia EconomyModule.lua de GitHub a Studio")
	end
end

-- ========================
-- 3. VERIFICAR PowerUpManager
-- ========================
print("\n⚡ Verificando PowerUpManager...")

local PowerUpManager = game.ServerStorage:FindFirstChild("Managers")
if PowerUpManager then
	PowerUpManager = PowerUpManager:FindFirstChild("PowerUpManager")
end

if not PowerUpManager then
	table.insert(issues, "❌ PowerUpManager no encontrado en ServerStorage/Managers/")
	table.insert(issues, "   → Copia PowerUpManager.lua de GitHub a Studio")
else
	table.insert(success, "✅ PowerUpManager existe")
end

-- ========================
-- 4. VERIFICAR PowerUpConfig
-- ========================
print("\n⚙️ Verificando PowerUpConfig...")

local PowerUpConfig = game.ServerStorage:FindFirstChild("Config")
if PowerUpConfig then
	PowerUpConfig = PowerUpConfig:FindFirstChild("PowerUpConfig")
end

if not PowerUpConfig then
	table.insert(issues, "❌ PowerUpConfig no encontrado en ServerStorage/Config/")
	table.insert(issues, "   → Copia PowerUpConfig.lua de GitHub a Studio")
else
	table.insert(success, "✅ PowerUpConfig existe")
end

-- ========================
-- 5. VERIFICAR RemoteEvents
-- ========================
print("\n📡 Verificando RemoteEvents...")

local Remotes = game.ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	table.insert(issues, "❌ Carpeta Remotes no existe en ReplicatedStorage")
else
	if not Remotes:FindFirstChild("PowerUpCollected") then
		table.insert(issues, "❌ RemoteEvent 'PowerUpCollected' no existe")
	else
		table.insert(success, "✅ RemoteEvent PowerUpCollected existe")
	end

	if not Remotes:FindFirstChild("PowerUpExpired") then
		table.insert(issues, "❌ RemoteEvent 'PowerUpExpired' no existe")
	else
		table.insert(success, "✅ RemoteEvent PowerUpExpired existe")
	end
end

-- ========================
-- 6. VERIFICAR UI Cliente
-- ========================
print("\n🖥️ Verificando cliente...")

local PowerUpUI = game.StarterGui:FindFirstChild("PowerUpUI")
if not PowerUpUI then
	table.insert(issues, "❌ Carpeta PowerUpUI no existe en StarterGui")
else
	if not PowerUpUI:FindFirstChild("PowerUpDisplay") then
		table.insert(issues, "❌ PowerUpDisplay.client.lua no encontrado")
	else
		table.insert(success, "✅ PowerUpDisplay existe")
	end
end

local Controllers = game.StarterPlayer:FindFirstChild("StarterPlayerScripts")
if Controllers then
	Controllers = Controllers:FindFirstChild("Controllers")
end

if not Controllers or not Controllers:FindFirstChild("PowerUpController") then
	table.insert(issues, "❌ PowerUpController.client.lua no encontrado en StarterPlayerScripts/Controllers")
else
	table.insert(success, "✅ PowerUpController existe")
end

-- ========================
-- 7. VERIFICAR EventManager integración
-- ========================
print("\n🌠 Verificando EventManager...")

local EventManager = game.ServerStorage:FindFirstChild("EventManager_REFACTORED")
if not EventManager then
	table.insert(issues, "❌ EventManager_REFACTORED no encontrado en ServerStorage")
else
	local source = EventManager.Source

	if source:find("PowerUpManager:SpawnRandomPowerUp") then
		table.insert(success, "✅ EventManager llama a PowerUpManager.SpawnRandomPowerUp")
	else
		table.insert(issues, "❌ EventManager NO spawna power-ups en impactos (línea 310)")
		table.insert(issues, "   → Reemplaza EventManager_REFACTORED.lua de GitHub")
	end
end

-- ========================
-- RESULTADOS
-- ========================
print("\n" .. string.rep("=", 70))
print("📊 RESULTADOS:")
print(string.rep("=", 70))

if #success > 0 then
	print("\n✅ FUNCIONANDO CORRECTAMENTE:")
	for _, msg in ipairs(success) do
		print("  " .. msg)
	end
end

if #issues > 0 then
	print("\n❌ PROBLEMAS ENCONTRADOS:")
	for _, msg in ipairs(issues) do
		print("  " .. msg)
	end

	print("\n" .. string.rep("=", 70))
	print("🔧 ACCIÓN REQUERIDA:")
	print(string.rep("=", 70))
	print("\nNecesitas copiar los siguientes archivos de GitHub a Studio:")
	print("Repositorio: github.com/pajarock/Apocalypse-Tycoon")
	print("Branch: claude/power-ups-system-018HfvFPabXECWtvHstjiZmd")
	print("\nConsulta POWERUP_INSTALLATION_GUIDE.md para instrucciones detalladas.")
else
	print("\n🎉 ¡TODO ESTÁ CORRECTO! Power-ups system completamente instalado.")
	print("\nPresiona M para testear un meteorito y verifica que:")
	print("  1. Power-ups aparecen al destruir meteorito")
	print("  2. Shield Bubble te hace invulnerable")
	print("  3. Coin Rain muestra efectos dorados + x2 income")
	print("  4. Auto-Repair regenera tu HP")
end

print("\n" .. string.rep("=", 70))
print("Verificación completa. Revisa los mensajes arriba. ⬆️")
print(string.rep("=", 70) .. "\n")
