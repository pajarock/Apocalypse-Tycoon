--!strict
--[[
	TESTING SNIPPETS - Apocalypse Tycoon
	═══════════════════════════════════════════════════════════════════════

	Snippets de código para testear cada sistema individualmente.

	USO:
	1. Copia el snippet que quieras testear
	2. Pega en Command Bar de Roblox Studio (View → Command Bar)
	3. Presiona Enter para ejecutar

	NOTA: Algunos snippets son SERVER-SIDE y otros CLIENT-SIDE.
]]

--═══════════════════════════════════════════════════════════════════════
-- SERVER-SIDE TESTS
--═══════════════════════════════════════════════════════════════════════

-- TEST 1: VFXManager - Spawnear explosión en origen
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
VFXManager:PlayEffect("MeteorExplosion", Vector3.new(0, 10, 0))
print("✓ Explosión spawneada en (0, 10, 0)")
]]

-- TEST 2: VFXManager - Spawnear múltiples efectos
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
for i = 1, 5 do
	task.wait(0.5)
	local pos = Vector3.new(math.random(-20, 20), 10, math.random(-20, 20))
	VFXManager:PlayEffect("MeteorExplosion", pos)
	print("✓ Explosión", i, "spawneada en", pos)
end
]]

-- TEST 3: VFXManager - Ver estadísticas del pool
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
local stats = VFXManager:GetPoolStats()
print("Pool stats:", stats)
-- Output: {MeteorExplosion = {Active: 2, Pooled: 8}}
]]

-- TEST 4: VFXManager - Test todos los efectos
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
local effects = {"MeteorTrail", "MeteorExplosion", "PurchaseSuccess", "DamageHit", "IncomePopup"}
for i, effectName in ipairs(effects) do
	task.wait(1)
	VFXManager:PlayEffect(effectName, Vector3.new(i * 10, 10, 0))
	print("✓ Efecto", effectName, "spawneado")
end
]]

-- TEST 5: EventManager - Triggear MeteorStorm
--[[
local EventManager = require(game.ServerStorage.EventManager)
EventManager:MeteorStorm()
print("✓ MeteorStorm iniciada")
]]

-- TEST 6: Camera Shake para todos los jugadores
--[[
local CameraShake = game.ReplicatedStorage.Remotes.CameraShake
for _, player in ipairs(game.Players:GetPlayers()) do
	CameraShake:FireClient(player, "Heavy", 1.0)
	print("✓ Camera shake enviado a", player.Name)
end
]]

-- TEST 7: VFXManager - Performance test (spawnear 50 explosiones)
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
local startTime = tick()
for i = 1, 50 do
	local pos = Vector3.new(math.random(-50, 50), 10, math.random(-50, 50))
	VFXManager:PlayEffect("MeteorExplosion", pos)
end
local elapsed = tick() - startTime
print(string.format("✓ 50 explosiones spawneadas en %.3fs (%.1f FPS)", elapsed, 50/elapsed))
]]

--═══════════════════════════════════════════════════════════════════════
-- CLIENT-SIDE TESTS (ejecutar en Command Bar con Play activo)
--═══════════════════════════════════════════════════════════════════════

-- TEST 8: CameraController - Test shake intensity
--[[
local CameraController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.CameraController)
print("Testing Light shake...")
CameraController:Shake("Light", 0.5)
task.wait(1)
print("Testing Medium shake...")
CameraController:Shake("Medium", 0.5)
task.wait(1)
print("Testing Heavy shake...")
CameraController:Shake("Heavy", 0.5)
print("✓ All shakes tested")
]]

-- TEST 9: CameraController - Test flash
--[[
local CameraController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.CameraController)
print("Testing red flash...")
CameraController:Flash(Color3.fromRGB(255, 0, 0), 0.6, 0.5)
task.wait(1)
print("Testing blue flash...")
CameraController:Flash(Color3.fromRGB(0, 100, 255), 0.6, 0.5)
task.wait(1)
print("Testing white flash...")
CameraController:Flash(Color3.fromRGB(255, 255, 255), 0.8, 0.4)
print("✓ All flashes tested")
]]

-- TEST 10: UIController - Test slide animations
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local frame = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame

print("Testing SlideOut Left...")
UIController:SlideOut(frame, "Left", 0.3)
task.wait(1)

print("Testing SlideIn Right...")
UIController:SlideIn(frame, "Right", 0.4)
task.wait(1)

print("Testing SlideOut Up...")
UIController:SlideOut(frame, "Up", 0.3)
task.wait(1)

print("Testing SlideIn Down...")
UIController:SlideIn(frame, "Down", 0.4)
print("✓ All slides tested")
]]

-- TEST 11: UIController - Test fade animations
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local frame = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame

print("Testing FadeOut...")
UIController:FadeOut(frame, 0.5)
task.wait(1)

print("Testing FadeIn...")
UIController:FadeIn(frame, 0.5)
print("✓ Fade tests completed")
]]

-- TEST 12: UIController - Test bounce on all shop buttons
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local buttons = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame.UpgradeList:GetChildren()

for _, child in ipairs(buttons) do
	if child:IsA("TextButton") then
		print("Bouncing button:", child.Name)
		UIController:Bounce(child, 1.2)
		task.wait(0.3)
	end
end
print("✓ All buttons bounced")
]]

-- TEST 13: UIController - Test purchase effect on first button
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local firstButton = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame.UpgradeList:FindFirstChildWhichIsA("TextButton")

if firstButton then
	print("Playing purchase effect on:", firstButton.Name)
	UIController:PlayPurchaseEffect(firstButton)
	print("✓ Purchase effect played")
else
	warn("No button found in shop")
end
]]

--═══════════════════════════════════════════════════════════════════════
-- INTEGRATION TESTS (combinan múltiples sistemas)
--═══════════════════════════════════════════════════════════════════════

-- TEST 14: Full meteor impact simulation (SERVER)
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
local CameraShake = game.ReplicatedStorage.Remotes.CameraShake

-- Posición del impacto
local impactPos = Vector3.new(0, 5, 0)

-- Explosión visual
VFXManager:PlayEffect("MeteorExplosion", impactPos)

-- Shake para todos los jugadores
for _, player in ipairs(game.Players:GetPlayers()) do
	CameraShake:FireClient(player, "Heavy", 0.6)
end

print("✓ Full meteor impact simulated")
]]

-- TEST 15: Shop purchase simulation (CLIENT)
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local CameraController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.CameraController)

local button = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame.UpgradeList:FindFirstChildWhichIsA("TextButton")

if button then
	-- Visual feedback
	UIController:PlayPurchaseEffect(button)

	-- Camera feedback
	CameraController:Shake("Light", 0.2)

	-- Flash verde
	CameraController:Flash(Color3.fromRGB(100, 255, 100), 0.3, 0.3)

	print("✓ Purchase simulation completed")
else
	warn("No button found")
end
]]

--═══════════════════════════════════════════════════════════════════════
-- STRESS TESTS (para verificar performance)
--═══════════════════════════════════════════════════════════════════════

-- TEST 16: VFX Pool stress test (SERVER)
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)

print("Starting VFX pool stress test...")
local startTime = tick()

-- Spawnear 100 explosiones rápidamente
for i = 1, 100 do
	local pos = Vector3.new(
		math.random(-100, 100),
		math.random(5, 20),
		math.random(-100, 100)
	)
	VFXManager:PlayEffect("MeteorExplosion", pos)
end

local elapsed = tick() - startTime
print(string.format("✓ Stress test: 100 explosiones en %.3fs", elapsed))

-- Ver estado del pool
task.wait(2)
local stats = VFXManager:GetPoolStats()
print("Pool stats after stress test:", stats)
]]

-- TEST 17: Camera shake stress test (CLIENT)
--[[
local CameraController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.CameraController)

print("Starting camera shake stress test (10 shakes simultáneos)...")

for i = 1, 10 do
	task.spawn(function()
		CameraController:Shake("Medium", 2.0)
	end)
end

print("✓ 10 shakes spawneados")
print("ActiveShakes:", CameraController.ActiveShakes)
]]

-- TEST 18: UI animation stress test (CLIENT)
--[[
local UIController = require(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)
local buttons = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame.UpgradeList:GetChildren()

print("Starting UI stress test (animar todos los botones simultáneamente)...")

for _, child in ipairs(buttons) do
	if child:IsA("TextButton") then
		task.spawn(function()
			for i = 1, 5 do
				UIController:Bounce(child, 1.15)
				task.wait(0.5)
			end
		end)
	end
end

print("✓ UI stress test iniciado")
]]

--═══════════════════════════════════════════════════════════════════════
-- DEBUGGING HELPERS
--═══════════════════════════════════════════════════════════════════════

-- TEST 19: Verificar que todos los módulos existen
--[[
local function checkModule(path)
	local success, result = pcall(function()
		return require(path)
	end)
	if success then
		print("✓", path)
		return true
	else
		warn("✗", path, "-", result)
		return false
	end
end

print("Verificando módulos SERVER-SIDE...")
checkModule(game.ServerStorage.Managers.VFXManager)
checkModule(game.ServerStorage.Config.VFXConfig)
checkModule(game.ServerStorage.EventManager)

print("\nVerificando módulos CLIENT-SIDE...")
checkModule(game.Players.LocalPlayer.PlayerScripts.Controllers.CameraController)
checkModule(game.Players.LocalPlayer.PlayerScripts.Controllers.UIController)

print("\nVerificando RemoteEvents...")
if game.ReplicatedStorage.Remotes:FindFirstChild("CameraShake") then
	print("✓ ReplicatedStorage.Remotes.CameraShake")
else
	warn("✗ ReplicatedStorage.Remotes.CameraShake NOT FOUND")
end
]]

-- TEST 20: Ver todos los efectos disponibles en VFXConfig
--[[
local VFXConfig = require(game.ServerStorage.Config.VFXConfig)
print("Efectos disponibles en VFXConfig:")
for i, effectName in ipairs(VFXConfig.AvailableEffects) do
	print(string.format("%d. %s", i, effectName))
end
]]

--═══════════════════════════════════════════════════════════════════════
-- QUICK FIXES
--═══════════════════════════════════════════════════════════════════════

-- FIX 1: Crear CameraShake RemoteEvent si no existe
--[[
local RemotesFolder = game.ReplicatedStorage.Remotes
if not RemotesFolder:FindFirstChild("CameraShake") then
	local cameraShake = Instance.new("RemoteEvent")
	cameraShake.Name = "CameraShake"
	cameraShake.Parent = RemotesFolder
	print("✓ RemoteEvent 'CameraShake' creado")
else
	print("✓ RemoteEvent 'CameraShake' ya existe")
end
]]

-- FIX 2: Limpiar pool de VFX
--[[
local VFXManager = require(game.ServerStorage.Managers.VFXManager)
VFXManager:ClearPool()
print("✓ Pool de VFX limpiado")
]]

-- FIX 3: Resetear posición del Shop UI
--[[
local frame = game.Players.LocalPlayer.PlayerGui.QuickBuyUI.MainFrame
frame.Position = UDim2.fromOffset(20, 100)
frame.Visible = true
print("✓ Shop UI reseteado a posición inicial")
]]

--═══════════════════════════════════════════════════════════════════════
-- NOTAS
--═══════════════════════════════════════════════════════════════════════

--[[
TIPS:

1. Los tests SERVER-SIDE deben ejecutarse desde Command Bar con el juego detenido
2. Los tests CLIENT-SIDE requieren presionar Play primero
3. Para ver output, abre Output window (View → Output)
4. Si un test falla, verifica que los módulos estén en las rutas correctas
5. Usa TEST 19 para verificar rápidamente que todo esté instalado correctamente

KEYBOARD SHORTCUTS ÚTILES:

- M: Spawnear meteorito (debug, ya implementado)
- B: Toggle shop UI (ya implementado)
- K: Camera shake test (si DEBUG_MODE = true en CameraController)
- L: Screen flash test (si DEBUG_MODE = true en CameraController)
]]
