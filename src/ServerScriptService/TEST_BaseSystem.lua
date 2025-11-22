--[[
	TEST SCRIPT - Base System

	Este script demuestra cómo usar el nuevo sistema de bases.
	Cópialo a ServerScriptService para probarlo.

	IMPORTANTE: Esto es SOLO para testing. NO es para producción.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

print("[TEST] ?? Esperando a que Knit esté listo...")

-- Esperar a que Knit esté listo (aumentado a 5 segundos para estar seguro)
task.wait(5)

local Knit = require(ReplicatedStorage.Knit)

-- Obtener servicios
local BaseSpawnerService = Knit.GetService("BaseSpawnerService")
local BaseOwnershipService = Knit.GetService("BaseOwnershipService")
local BasePlacementService = Knit.GetService("BasePlacementService")

print("???????????????????????????????????????????????????")
print("?? TEST SCRIPT - Base System Ready")
print("???????????????????????????????????????????????????")
print(string.format("[TEST] ? Servicios cargados: Spawner=%s, Ownership=%s, Placement=%s",
	BaseSpawnerService and "OK" or "FAIL",
	BaseOwnershipService and "OK" or "FAIL",
	BasePlacementService and "OK" or "FAIL"
	))

-- Test 1: Spawnear base automáticamente cuando un jugador se une
Players.PlayerAdded:Connect(function(player)
	-- Esperar a que el character se cargue
	player.CharacterAdded:Wait()

	print(string.format("[TEST] ?? Spawneando base de prueba para %s...", player.Name))

	-- Spawnear base usando el nuevo sistema
	local baseData = BaseSpawnerService:SpawnBase(player.UserId, player.Name)

	if baseData then
		print(string.format("[TEST] ? Base spawneada exitosamente en posición: %s", tostring(baseData.Position)))
		print(string.format("[TEST] BuildZone radio: %.1f studs", 60))
		print(string.format("[TEST] SpawnZone radio: %.1f studs", 15))

		-- Teleportar jugador a su base
		task.wait(0.5)
		if player.Character then
			local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
			if humanoidRootPart then
				humanoidRootPart.CFrame = CFrame.new(baseData.Position + Vector3.new(0, 5, 0))
				print(string.format("[TEST] ?? %s teleportado a su base", player.Name))
			end
		end
	else
		warn("[TEST] ? Error al spawnear base")
	end
end)

-- Test 2: Comando de chat para probar placement
Players.PlayerAdded:Connect(function(player)
	print(string.format("[TEST] ?? Conectando comandos de chat para: %s", player.Name))

	player.Chatted:Connect(function(message)
		print(string.format("[TEST] ?? Chat detectado de %s: '%s'", player.Name, message))

		local args = string.split(message, " ")
		local command = args[1]:lower()

		print(string.format("[TEST] ?? Comando parseado: '%s'", command))

		-- Comando: /testbase - Spawnear una base nueva
		if command == "/testbase" then
			local baseData = BaseSpawnerService:SpawnBase(player.UserId, player.Name)
			if baseData then
				print(string.format("[TEST] Base spawneada para %s", player.Name))
			end
		end

		-- Comando: /destroybase - Destruir base
		if command == "/destroybase" then
			local success = BaseSpawnerService:DestroyBase(player.UserId)
			if success then
				print(string.format("[TEST] Base destruida para %s", player.Name))
			end
		end

		-- Comando: /baseinfo - Ver info de la base
		if command == "/baseinfo" then
			print(string.format("[TEST] ? Comando /baseinfo detectado para %s", player.Name))
			local baseData = BaseSpawnerService:GetBaseData(player.UserId)
			if baseData then
				print("??????????????????????????????")
				print(string.format("?? Base Info - %s", player.Name))
				print(string.format("Position: %s", tostring(baseData.Position)))
				print(string.format("Index: %s", tostring(baseData.Index or "N/A")))

				-- Mostrar objetos colocados
				local objects = BaseOwnershipService:GetBaseObjects(player.UserId)
				print(string.format("Objects placed: %d", #objects))
				for i, obj in ipairs(objects) do
					print(string.format("  %d. %s at %s", i, obj.ObjectType, tostring(obj.Position)))
				end
				print("??????????????????????????????")
			else
				print("[TEST] No tienes base spawneada")
			end
		end

		-- Comando: /testplace - Colocar objeto de prueba
		if command == "/testplace" then
			print(string.format("[TEST] ? Comando /testplace detectado para %s", player.Name))
			local baseData = BaseSpawnerService:GetBaseData(player.UserId)
			if not baseData then
				print("[TEST] ? Necesitas una base primero (/testbase)")
				return
			end

			print(string.format("[TEST] Base encontrada en: %s", tostring(baseData.Position)))

			-- Calcular posición de prueba (lejos del spawn zone)
			local testPosition = baseData.Position + Vector3.new(40, 2, 20)
			local testRotation = 0
			local testSize = Vector3.new(10, 5, 10)

			print(string.format("[TEST] Intentando colocar en: %s (Size: %s)", tostring(testPosition), tostring(testSize)))

			-- Validar placement
			local result = BasePlacementService:CalculatePlacement(
				player.UserId,
				testPosition,
				testRotation,
				testSize
			)

			print(string.format("[TEST] Resultado de validación: IsValid=%s", tostring(result.IsValid)))

			if result.IsValid then
				print("[TEST] ? Posición válida:", result.Position)

				-- Crear objeto visual de prueba
				local testPart = Instance.new("Part")
				testPart.Name = "TestObject"
				testPart.Size = testSize
				testPart.Position = result.Position
				testPart.Anchored = true
				testPart.BrickColor = BrickColor.new("Bright green")
				testPart.Material = Enum.Material.Neon
				testPart.Parent = workspace

				-- Registrar en ownership
				local placedObject = BaseOwnershipService:RegisterObject(
					player.UserId,
					player.UserId,
					"TestObject",
					result.Position,
					result.Rotation,
					testPart
				)

				if placedObject then
					print("[TEST] ?? Objeto registrado:", placedObject.ObjectId)
				end
			else
				print("[TEST] ? Posición inválida:", result.ErrorMessage)
			end
		end

		-- Comando: /clearobjects - Limpiar todos los objetos Y la base
		if command == "/clearobjects" then
			local count = BaseOwnershipService:ClearBaseObjects(player.UserId)
			local baseDestroyed = BaseSpawnerService:DestroyBase(player.UserId)
			print(string.format("[TEST] ?? Limpiados %d objetos | Base destruida: %s", count, tostring(baseDestroyed)))
		end
	end)
end)

print("???????????????????????????????????????????????????")
print("?? COMANDOS DE TEST DISPONIBLES:")
print("   /testbase     - Spawnear una base")
print("   /destroybase  - Destruir tu base")
print("   /baseinfo     - Ver info de tu base")
print("   /testplace    - Colocar objeto de prueba")
print("   /clearobjects - Limpiar objetos de tu base")
print("   Z (tecla)     - Abrir build menu (cliente)")
print("???????????????????????????????????????????????????")

-- Conectar a jugadores que ya están en el juego
for _, player in Players:GetPlayers() do
	print(string.format("[TEST] ?? Conectando comandos para jugador existente: %s", player.Name))

	player.Chatted:Connect(function(message)
		print(string.format("[TEST] ?? Chat detectado de %s: '%s'", player.Name, message))

		local args = string.split(message, " ")
		local command = args[1]:lower()

		print(string.format("[TEST] ?? Comando parseado: '%s'", command))

		-- Procesar comando
		if command == "/testbase" then
			print(string.format("[TEST] ? Comando /testbase detectado para %s", player.Name))
			local baseData = BaseSpawnerService:SpawnBase(player.UserId, player.Name)
			if baseData then
				print(string.format("[TEST] Base spawneada para %s", player.Name))
			end
		elseif command == "/destroybase" then
			local success = BaseSpawnerService:DestroyBase(player.UserId)
			if success then
				print(string.format("[TEST] Base destruida para %s", player.Name))
			end
		elseif command == "/baseinfo" then
			print(string.format("[TEST] ? Comando /baseinfo detectado para %s", player.Name))
			local baseData = BaseSpawnerService:GetBaseData(player.UserId)
			if baseData then
				print("??????????????????????????????")
				print(string.format("?? Base Info - %s", player.Name))
				print(string.format("Position: %s", tostring(baseData.Position)))
				print(string.format("Index: %s", tostring(baseData.Index or "N/A")))

				-- Mostrar objetos colocados
				local objects = BaseOwnershipService:GetBaseObjects(player.UserId)
				print(string.format("Objects placed: %d", #objects))
				for i, obj in ipairs(objects) do
					print(string.format("  %d. %s at %s", i, obj.ObjectType, tostring(obj.Position)))
				end
				print("??????????????????????????????")
			else
				print("[TEST] No tienes base spawneada")
			end
		elseif command == "/testplace" then
			print(string.format("[TEST] ? Comando /testplace detectado para %s", player.Name))
			local baseData = BaseSpawnerService:GetBaseData(player.UserId)
			if not baseData then
				print("[TEST] ? Necesitas una base primero (/testbase)")
				return
			end

			print(string.format("[TEST] Base encontrada en: %s", tostring(baseData.Position)))

			-- Calcular posición de prueba (lejos del spawn zone)
			local testPosition = baseData.Position + Vector3.new(40, 2, 20)
			local testRotation = 0
			local testSize = Vector3.new(10, 5, 10)

			print(string.format("[TEST] Intentando colocar en: %s (Size: %s)", tostring(testPosition), tostring(testSize)))

			-- Validar placement
			local result = BasePlacementService:CalculatePlacement(
				player.UserId,
				testPosition,
				testRotation,
				testSize
			)

			print(string.format("[TEST] Resultado de validación: IsValid=%s", tostring(result.IsValid)))

			if result.IsValid then
				print("[TEST] ? Posición válida:", result.Position)

				-- Crear objeto visual de prueba
				local testPart = Instance.new("Part")
				testPart.Name = "TestObject"
				testPart.Size = testSize
				testPart.Position = result.Position
				testPart.Anchored = true
				testPart.BrickColor = BrickColor.new("Bright green")
				testPart.Material = Enum.Material.Neon
				testPart.Parent = workspace

				-- Registrar en ownership
				local placedObject = BaseOwnershipService:RegisterObject(
					player.UserId,
					player.UserId,
					"TestObject",
					result.Position,
					result.Rotation,
					testPart
				)

				if placedObject then
					print("[TEST] ?? Objeto registrado:", placedObject.ObjectId)
				end
			else
				print("[TEST] ? Posición inválida:", result.ErrorMessage)
			end
		elseif command == "/clearobjects" then
			local count = BaseOwnershipService:ClearBaseObjects(player.UserId)
			local baseDestroyed = BaseSpawnerService:DestroyBase(player.UserId)
			print(string.format("[TEST] ?? Limpiados %d objetos | Base destruida: %s", count, tostring(baseDestroyed)))
		end
	end)
end