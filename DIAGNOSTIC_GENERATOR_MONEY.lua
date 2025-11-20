--[[
	DIAGNOSTIC SCRIPT - Generator Money Production

	Ejecuta esto en Command Bar para diagnosticar por qué no está dando dinero
]]

print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 DIAGNOSTIC: Generator Money Production")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

-- 1. Verificar Knit services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Knit)

print("\n[1] CHECKING KNIT SERVICES...")

local success1, UpgradeService = pcall(function()
	return Knit.GetService("UpgradeService")
end)
print("  UpgradeService:", success1 and "✅ FOUND" or "❌ NOT FOUND")

local success2, PlayerDataService = pcall(function()
	return Knit.GetService("PlayerDataService")
end)
print("  PlayerDataService:", success2 and "✅ FOUND" or "❌ NOT FOUND")

if not success1 or not success2 then
	print("\n❌ CRITICAL: Services not loaded!")
	return
end

-- 2. Verificar generadores activos
print("\n[2] CHECKING ACTIVE GENERATORS...")
local counts = UpgradeService:GetActiveUpgradeCounts()
print("  Active generators:", counts.Generators)

if counts.Generators == 0 then
	print("\n⚠️  NO GENERATORS REGISTERED!")
	print("  Solution: Place a generator in your base")
	return
end

-- 3. Verificar detalles de generadores
print("\n[3] GENERATOR DETAILS...")
local debugInfo = UpgradeService:GetDebugInfo()
for i, gen in ipairs(debugInfo.Generators) do
	print(string.format("  Generator #%d:", i))
	print(string.format("    ObjectId: %s", gen.ObjectId))
	print(string.format("    Owner: %d", gen.UserId))
	print(string.format("    Rate: $%d/s", gen.MoneyPerSecond))
	print(string.format("    Last produced: %ds ago", gen.SecondsSinceProduction))
end

-- 4. Verificar jugador
print("\n[4] CHECKING PLAYER DATA...")
local player = game.Players:GetPlayers()[1]
if not player then
	print("  ❌ No player found!")
	return
end

print(string.format("  Player: %s (UserId: %d)", player.Name, player.UserId))

-- 5. Verificar EconomyModule
print("\n[5] CHECKING ECONOMY MODULE...")
local ServerScriptService = game:GetService("ServerScriptService")
local EconomyModule = require(ServerScriptService.EconomyModule)

local state = EconomyModule.GetState(player.UserId)
if not state then
	print("  ❌ Player not initialized in EconomyModule!")
	print("  This should have been done automatically on join")
	return
end

print(string.format("  Current cash: $%.2f", state.Cash))
print(string.format("  Income/sec: $%.2f", state.IncomePerSec))
print(string.format("  Total earned: $%.2f", state.TotalEarned))

-- 6. Test manual de AddMoney
print("\n[6] TESTING ADDMONEY MANUALLY...")
local beforeCash = state.Cash
local testAmount = 10

local success = PlayerDataService:AddMoney(player.UserId, testAmount)
task.wait(0.1)

local afterState = EconomyModule.GetState(player.UserId)
local afterCash = afterState.Cash

print(string.format("  Before: $%.2f", beforeCash))
print(string.format("  After: $%.2f", afterCash))
print(string.format("  Difference: $%.2f", afterCash - beforeCash))
print(string.format("  Expected: $%.2f", testAmount))

if (afterCash - beforeCash) >= testAmount then
	print("  ✅ AddMoney works correctly!")
else
	print("  ❌ AddMoney NOT working!")
end

-- 7. Monitor por 5 segundos
print("\n[7] MONITORING FOR 5 SECONDS...")
print("  Watching for cash changes...")

local startCash = afterCash
for i = 1, 5 do
	task.wait(1)
	local currentState = EconomyModule.GetState(player.UserId)
	local currentCash = currentState.Cash
	local change = currentCash - startCash
	print(string.format("  [%ds] Cash: $%.2f (Change: +$%.2f)", i, currentCash, change))
	startCash = currentCash
end

print("\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("🔍 DIAGNOSTIC COMPLETE")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("\nIf cash is NOT changing, check:")
print("  1. Is UpgradeService update loop running?")
print("  2. Are there any errors in Output?")
print("  3. Is the generator Model valid (has MainPart)?")
