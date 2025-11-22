--!strict
--[[
	-----------------------------------------------------------------------
	MASTER MAP GENERATOR - Apocalypse Tycoon
	-----------------------------------------------------------------------
	
	Este script genera automÃ¡ticamente el mapa apocalÃ­ptico prehispÃ¡nico completo.
	Solo necesitas ejecutar: MasterGenerator.Generate()
	
	CARACTERÃSTICAS COMPLETAS:
	? OcÃ©ano de lava peligrosa
	? MontaÃ±as volcÃ¡nicas con altura variable
	? Plataformas elevadas para bases de jugadores
	? Ruinas y pirÃ¡mides prehispÃ¡nicas
	? Estatuas de guerreros jaguares
	? Serpientes emplumadas (QuetzalcÃ³atl)
	? Altares de sacrificio
	? Estelas con glifos mayas/aztecas
	? Calendario solar
	? Cristales mÃ­sticos flotantes
	? Efectos de ceniza y niebla
	? RelÃ¡mpagos rojos apocalÃ­pticos
	? Ondas de calor
	? Burbujas de lava
	? Sonidos ambientales Ã©picos
	? IluminaciÃ³n cinematogrÃ¡fica
	? Post-processing profesional
	
	AUTOR: Claude / Anthropic
	VERSIÃN: 1.0
	-----------------------------------------------------------------------
]]

-- Requiere los mÃ³dulos necesarios
local ServerStorage = game:GetService("ServerStorage")

-- Verificar que los mÃ³dulos existan (en tu juego deben estar en ServerScriptService)
local TerrainGenerator = require(script.Parent:WaitForChild("TerrainGenerator"))
local AmbientEffects = require(script.Parent:WaitForChild("AmbientEffects"))
local PreHispanicDecorations = require(script.Parent:WaitForChild("PreHispanicDecorations"))

local MasterGenerator = {}

-------------------------------------------------------------------------
-- CONFIGURACIÃN GENERAL
-------------------------------------------------------------------------

MasterGenerator.Config = {
	-- Modo de generaciÃ³n
	GenerateTerrain = true,
	GenerateDecorations = true,
	EnableEffects = true,

	-- Modos especiales
	PerformanceMode = false,  -- Reduce efectos para mejor FPS
	DevMode = false,          -- Muestra informaciÃ³n de debug

	-- Opciones visuales
	EnableLightning = true,
	EnableFloatingCrystals = true,
	EnableMysticFog = true,
	EnableAmbientSounds = true,

	-- Opciones de gameplay
	LavaDamage = 50,
	SafeZoneRadius = 300,  -- Radio del Ã¡rea segura central
}

-------------------------------------------------------------------------
-- GENERACIÃN COMPLETA
-------------------------------------------------------------------------

function MasterGenerator.Generate()
	print("-----------------------------------------------------------")
	print("  APOCALYPSE TYCOON - GENERADOR DE MAPA MAESTRO")
	print("-----------------------------------------------------------")
	print("[MASTER] Iniciando generaciÃ³n del mapa...")
	print("[MASTER] Esto puede tomar 10-30 segundos...")

	local startTime = tick()

	-- FASE 1: Limpiar mapa anterior
	print("\n[FASE 1/4] Limpiando mapa anterior...")
	MasterGenerator.Clear()
	task.wait(0.5)

	-- FASE 2: Generar terreno base
	if MasterGenerator.Config.GenerateTerrain then
		print("\n[FASE 2/4] Generando terreno apocalÃ­ptico...")
		print("  ? OcÃ©ano de lava")
		print("  ? MontaÃ±as volcÃ¡nicas")
		print("  ? Plataformas de bases")
		print("  ? Ruinas y pilares")

		local mapFolder = TerrainGenerator.GenerateMap()

		print("[FASE 2/4] ? Terreno generado")
	else
		print("\n[FASE 2/4] ? GeneraciÃ³n de terreno omitida")
	end

	-- FASE 3: Decoraciones prehispÃ¡nicas
	if MasterGenerator.Config.GenerateDecorations then
		print("\n[FASE 3/4] Colocando decoraciones prehispÃ¡nicas...")
		print("  ? Estatuas de guerreros")
		print("  ? Serpientes emplumadas")
		print("  ? Altares de sacrificio")
		print("  ? Estelas con glifos")
		print("  ? Calendario solar")

		local mapFolder = workspace:FindFirstChild("ApocalypticMap")
		if mapFolder then
			PreHispanicDecorations.PlaceAll(mapFolder)
		end

		print("[FASE 3/4] ? Decoraciones colocadas")
	else
		print("\n[FASE 3/4] ? Decoraciones omitidas")
	end

	-- FASE 4: Efectos ambientales
	if MasterGenerator.Config.EnableEffects then
		print("\n[FASE 4/4] Activando efectos ambientales...")
		print("  ? Ceniza flotante")
		print("  ? Niebla tÃ³xica")
		print("  ? Ondas de calor")

		if MasterGenerator.Config.EnableLightning then
			print("  ? RelÃ¡mpagos rojos")
		end

		if MasterGenerator.Config.EnableFloatingCrystals then
			print("  ? Cristales mÃ­sticos")
		end

		print("  ? Burbujas de lava")

		if MasterGenerator.Config.EnableAmbientSounds then
			print("  ? Sonidos ambientales")
		end

		print("  ? Post-processing")

		if MasterGenerator.Config.PerformanceMode then
			AmbientEffects.EnablePerformanceMode()
		else
			AmbientEffects.EnableAll()
		end

		print("[FASE 4/4] ? Efectos activados")
	else
		print("\n[FASE 4/4] ? Efectos omitidos")
	end

	-- EstadÃ­sticas finales
	local elapsed = tick() - startTime
	print("\n-----------------------------------------------------------")
	print(string.format("[MASTER] ? MAPA GENERADO EN %.1f SEGUNDOS", elapsed))
	print("-----------------------------------------------------------")
	print("\nCONTROLES:")
	print("  Â /regenmap - Regenerar mapa completo")
	print("  Â /clearmap - Limpiar todo el mapa")
	print("  Â /perfmode - Activar modo performance")
	print("\nESTADÃSTICAS DEL MAPA:")

	-- Contar objetos generados
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if mapFolder then
		local mountains = #mapFolder:FindFirstChild("Mountains"):GetChildren() or 0
		local ruins = #mapFolder:FindFirstChild("Ruins"):GetChildren() or 0
		local decoFolder = mapFolder:FindFirstChild("PreHispanicDecorations")
		local decorations = decoFolder and #decoFolder:GetChildren() or 0

		print(string.format("  Â MontaÃ±as: %d", mountains))
		print(string.format("  Â Ruinas: %d", ruins))
		print(string.format("  Â Decoraciones: %d", decorations))
	end

	print("-----------------------------------------------------------\n")

	return true
end

-------------------------------------------------------------------------
-- LIMPIEZA
-------------------------------------------------------------------------

function MasterGenerator.Clear()
	print("[MASTER] Limpiando mapa...")

	-- Limpiar terreno
	TerrainGenerator.ClearMap()

	-- Limpiar efectos
	AmbientEffects.DisableAll()

	-- Limpiar decoraciones
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if mapFolder then
		local deco = mapFolder:FindFirstChild("PreHispanicDecorations")
		if deco then
			deco:Destroy()
		end
	end

	print("[MASTER] ? Mapa limpiado")
end

-------------------------------------------------------------------------
-- REGENERACIÃN RÃPIDA
-------------------------------------------------------------------------

function MasterGenerator.QuickRegenerate()
	print("[MASTER] RegeneraciÃ³n rÃ¡pida...")
	MasterGenerator.Clear()
	task.wait(1)
	MasterGenerator.Generate()
end

-------------------------------------------------------------------------
-- MODO PERFORMANCE
-------------------------------------------------------------------------

function MasterGenerator.EnablePerformanceMode()
	print("[MASTER] Activando modo performance...")
	MasterGenerator.Config.PerformanceMode = true

	-- Reducir efectos
	AmbientEffects.DisableAll()
	task.wait(0.5)
	AmbientEffects.EnablePerformanceMode()

	-- Reducir partÃ­culas globalmente
	for _, emitter in ipairs(workspace:GetDescendants()) do
		if emitter:IsA("ParticleEmitter") then
			emitter.Rate = math.max(1, math.floor(emitter.Rate * 0.3))
		end
	end

	print("[MASTER] ? Modo performance activado")
	print("  ? FPS deberÃ­a mejorar significativamente")
end

-------------------------------------------------------------------------
-- COMANDOS DE ADMIN
-------------------------------------------------------------------------

function MasterGenerator.SetupAdminCommands()
	local Players = game:GetService("Players")

	Players.PlayerAdded:Connect(function(plr)
		plr.Chatted:Connect(function(msg)
			local lower = msg:lower()

			-- Solo el creador o admins
			local isAdmin = plr.UserId == game.CreatorId or plr:GetRankInGroup(0) >= 255

			if not isAdmin then return end

			if lower == "/regenmap" then
				print("[ADMIN] " .. plr.Name .. " estÃ¡ regenerando el mapa...")
				MasterGenerator.QuickRegenerate()

			elseif lower == "/clearmap" then
				print("[ADMIN] " .. plr.Name .. " estÃ¡ limpiando el mapa...")
				MasterGenerator.Clear()

			elseif lower == "/perfmode" then
				print("[ADMIN] " .. plr.Name .. " activÃ³ modo performance")
				MasterGenerator.EnablePerformanceMode()

			elseif lower == "/normalmode" then
				print("[ADMIN] " .. plr.Name .. " activÃ³ modo normal")
				MasterGenerator.Config.PerformanceMode = false
				AmbientEffects.DisableAll()
				task.wait(0.5)
				AmbientEffects.EnableAll()

			elseif lower == "/mapstats" then
				-- Mostrar estadÃ­sticas del mapa
				local stats = MasterGenerator.GetMapStats()
				print("\n------- ESTADÃSTICAS DEL MAPA -------")
				for key, value in pairs(stats) do
					print(string.format("  %s: %s", key, tostring(value)))
				end
				print("---------------------------------------\n")
			end
		end)
	end)

	print("[MASTER] ? Comandos de admin configurados")
end

-------------------------------------------------------------------------
-- ESTADÃSTICAS
-------------------------------------------------------------------------

function MasterGenerator.GetMapStats()
	local mapFolder = workspace:FindFirstChild("ApocalypticMap")
	if not mapFolder then
		return {
			Status = "No map generated"
		}
	end

	local stats = {
		Status = "Active",
		TotalParts = 0,
		Mountains = 0,
		Ruins = 0,
		Decorations = 0,
		ParticleEmitters = 0,
		Lights = 0,
	}

	-- Contar todo
	for _, desc in ipairs(mapFolder:GetDescendants()) do
		if desc:IsA("BasePart") then
			stats.TotalParts += 1
		elseif desc:IsA("ParticleEmitter") then
			stats.ParticleEmitters += 1
		elseif desc:IsA("Light") then
			stats.Lights += 1
		end
	end

	-- Contar especÃ­ficos
	local mountainsFolder = mapFolder:FindFirstChild("Mountains")
	if mountainsFolder then
		stats.Mountains = #mountainsFolder:GetChildren()
	end

	local ruinsFolder = mapFolder:FindFirstChild("Ruins")
	if ruinsFolder then
		stats.Ruins = #ruinsFolder:GetChildren()
	end

	local decoFolder = mapFolder:FindFirstChild("PreHispanicDecorations")
	if decoFolder then
		stats.Decorations = #decoFolder:GetChildren()
	end

	return stats
end

-------------------------------------------------------------------------
-- INICIALIZACIÃN AUTOMÃTICA (opcional)
-------------------------------------------------------------------------

function MasterGenerator.Init(autoGenerate: boolean?)
	print("\n[MASTER] Inicializando generador de mapas...")

	-- Configurar comandos
	MasterGenerator.SetupAdminCommands()

	-- Generar automÃ¡ticamente si se especifica
	if autoGenerate then
		task.spawn(function()
			task.wait(3)  -- Esperar a que el juego cargue
			MasterGenerator.Generate()
		end)
	end

	print("[MASTER] ? Generador inicializado")
	print("[MASTER] Usa MasterGenerator.Generate() para crear el mapa")
end

-------------------------------------------------------------------------
-- EXPORT
-------------------------------------------------------------------------

return MasterGenerator