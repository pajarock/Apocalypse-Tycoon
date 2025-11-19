# 🔧 INSTRUCCIONES: Knit Simplificado para FASE 1

## ❌ Problema Identificado
El Knit oficial de GitHub depende de librerías externas (Promise, Signal) que normalmente se instalan con Wally.
Como estás copiando manualmente, no tienes esas dependencias.

## ✅ Solución: Knit Simplificado (Sin Dependencias)

He creado una versión **simplificada** de Knit que:
- ✅ NO requiere Promise ni Signal
- ✅ Tiene la API básica funcionando
- ✅ Perfecto para FASE 1 (testing)
- ✅ Migraremos a Knit completo en FASE 2+

---

## 📦 Archivos a Crear en Studio

### **Estructura en ReplicatedStorage:**
```
ReplicatedStorage
└── 📗 Knit (ModuleScript)
    ├── 📗 KnitServer (ModuleScript HIJO)
    └── 📗 KnitClient (ModuleScript HIJO)
```

---

## 📝 Código de Cada Archivo

### **1. Knit (ModuleScript principal)**

```lua
--!strict
-- Knit Framework (Versión simplificada FASE 1)
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return require(script.KnitServer)
else
	local KnitServer = script:FindFirstChild("KnitServer")
	if KnitServer and RunService:IsRunning() then
		KnitServer:Destroy()
	end
	return require(script.KnitClient)
end
```

---

### **2. KnitServer (ModuleScript hijo de Knit)**

```lua
--!strict
-- KnitServer - Versión simplificada sin dependencias externas

local KnitServer = {
	Services = {},
	Util = {},
}

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")

function KnitServer.CreateService(serviceDef)
	assert(type(serviceDef) == "table", "Service must be a table")
	assert(type(serviceDef.Name) == "string", "Service must have a Name")
	assert(KnitServer.Services[serviceDef.Name] == nil, "Service already exists: " .. serviceDef.Name)

	local service = serviceDef
	service.Client = service.Client or {}

	-- Crear RemoteEvent/RemoteFunction para cada método Client
	if service.Client then
		local clientComm = Instance.new("Folder")
		clientComm.Name = serviceDef.Name
		clientComm.Parent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 5)

		for key, value in pairs(service.Client) do
			if type(value) == "function" then
				local remote = Instance.new("RemoteFunction")
				remote.Name = key
				remote.OnServerInvoke = function(player, ...)
					return value(service.Client, player, ...)
				end
				remote.Parent = clientComm
			end
		end
	end

	KnitServer.Services[serviceDef.Name] = service
	return service
end

function KnitServer.GetService(serviceName)
	assert(started, "Cannot call GetService until Knit has been started")
	assert(startedComplete, "Cannot call GetService until all services have been initialized")
	local service = KnitServer.Services[serviceName]
	assert(service, "Service does not exist: " .. serviceName)
	return service
end

function KnitServer.Start()
	if started then
		return warn("Knit already started")
	end

	started = true

	-- KnitInit phase
	for _, service in pairs(KnitServer.Services) do
		if type(service.KnitInit) == "function" then
			task.spawn(service.KnitInit, service)
		end
	end

	-- KnitStart phase
	for _, service in pairs(KnitServer.Services) do
		if type(service.KnitStart) == "function" then
			task.spawn(service.KnitStart, service)
		end
	end

	startedComplete = true
	onStartedComplete:Fire()

	-- Simular Promise-like para compatibilidad
	return {
		andThen = function(_, callback)
			task.defer(callback)
			return {
				catch = function() end
			}
		end,
		catch = function() end
	}
end

return KnitServer
```

---

### **3. KnitClient (ModuleScript hijo de Knit)**

```lua
--!strict
-- KnitClient - Versión simplificada sin dependencias externas

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KnitClient = {
	Controllers = {},
	Util = {},
}

local started = false
local startedComplete = false
local onStartedComplete = Instance.new("BindableEvent")
local servicesFolder

function KnitClient.CreateController(controllerDef)
	assert(type(controllerDef) == "table", "Controller must be a table")
	assert(type(controllerDef.Name) == "string", "Controller must have a Name")
	assert(KnitClient.Controllers[controllerDef.Name] == nil, "Controller already exists: " .. controllerDef.Name)

	KnitClient.Controllers[controllerDef.Name] = controllerDef
	return controllerDef
end

function KnitClient.GetService(serviceName)
	assert(started, "Cannot call GetService until Knit has been started")

	if not servicesFolder then
		servicesFolder = ReplicatedStorage:WaitForChild("Remotes", 10)
		assert(servicesFolder, "Could not find Remotes folder in ReplicatedStorage")
	end

	local folder = servicesFolder:FindFirstChild(serviceName)
	if not folder then
		warn("Service does not exist: " .. serviceName)
		return nil
	end

	-- Crear proxy para llamar métodos remotos
	local serviceProxy = {}

	for _, remote in ipairs(folder:GetChildren()) do
		if remote:IsA("RemoteFunction") then
			serviceProxy[remote.Name] = function(_, ...)
				return remote:InvokeServer(...)
			end
		elseif remote:IsA("RemoteEvent") then
			serviceProxy[remote.Name] = function(_, ...)
				remote:FireServer(...)
			end
		end
	end

	return serviceProxy
end

function KnitClient.GetController(controllerName)
	assert(started, "Cannot call GetController until Knit has been started")
	assert(startedComplete, "Cannot call GetController until all controllers have been initialized")
	local controller = KnitClient.Controllers[controllerName]
	assert(controller, "Controller does not exist: " .. controllerName)
	return controller
end

function KnitClient.Start()
	if started then
		return warn("Knit already started")
	end

	started = true

	-- KnitInit phase
	for _, controller in pairs(KnitClient.Controllers) do
		if type(controller.KnitInit) == "function" then
			task.spawn(controller.KnitInit, controller)
		end
	end

	-- KnitStart phase
	for _, controller in pairs(KnitClient.Controllers) do
		if type(controller.KnitStart) == "function" then
			task.spawn(controller.KnitStart, controller)
		end
	end

	startedComplete = true
	onStartedComplete:Fire()

	-- Simular Promise-like para compatibilidad
	return {
		andThen = function(_, callback)
			task.defer(callback)
			return {
				catch = function() end
			}
		end,
		catch = function() end
	}
end

return KnitClient
```

---

## ✅ Checklist de Implementación

1. [ ] **Borrar** la carpeta `ReplicatedStorage/Knit` actual
2. [ ] **Crear** ModuleScript `Knit` en ReplicatedStorage
3. [ ] Copiar código del archivo 1 (Knit principal)
4. [ ] **Dentro de Knit**, crear ModuleScript hijo `KnitServer`
5. [ ] Copiar código del archivo 2 (KnitServer)
6. [ ] **Dentro de Knit**, crear ModuleScript hijo `KnitClient`
7. [ ] Copiar código del archivo 3 (KnitClient)
8. [ ] Verificar jerarquía en Explorer:
   ```
   ReplicatedStorage
   └── 📗 Knit
       ├── 📗 KnitServer (hijo)
       └── 📗 KnitClient (hijo)
   ```

---

## 🎯 Mensajes Esperados al Probar

**Servidor:**
```
✅ [HelloService] Ready
✅ [KnitServer] Started successfully
```

**Cliente:**
```
🔵 [DebugController] Response from server: Hello from Knit, [TU_NOMBRE]!
✅ [KnitClient] Started successfully
```

---

## 📌 Notas Importantes

- Esta es una versión **simplificada** solo para FASE 1
- NO tiene todas las features de Knit completo
- Suficiente para probar concepto y migrar módulos básicos
- En FASE 2+ instalaremos Knit completo vía Wally

---

## ❓ Si Sigue Dando Error

Si después de copiar estos 3 archivos sigue habiendo errores:
1. Toma screenshot del error en Output
2. Verifica que la jerarquía sea EXACTA (KnitServer y KnitClient hijos de Knit)
3. Verifica que todos sean ModuleScript (ícono verde con M)
