--[[
	KnitClient - Simplified Version (No External Dependencies)

	LIFECYCLE:
	1. CreateController() - Register controllers
	2. Start() - Initialize all controllers
	   a. Call KnitInit() on ALL controllers FIRST
	   b. Then call KnitStart() on ALL controllers
	3. GetController() / GetService() - Available after Start() completes
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KnitClient = {}
local controllers = {}
local services = {}
local started = false
local allControllersInitialized = false

-- Create a controller
function KnitClient.CreateController(controllerDef)
	assert(type(controllerDef) == "table", "Controller must be a table")
	assert(type(controllerDef.Name) == "string", "Controller.Name must be a string")
	assert(not controllers[controllerDef.Name], "Controller " .. controllerDef.Name .. " already exists")
	assert(not started, "Cannot create controllers after Knit.Start() has been called")

	controllers[controllerDef.Name] = controllerDef

	return controllerDef
end

-- Get a controller
function KnitClient.GetController(controllerName)
	assert(started, "Cannot call GetController until Knit.Start() has been called")
	assert(allControllersInitialized, "Cannot call GetController until all controllers have been initialized")
	assert(type(controllerName) == "string", "ControllerName must be a string")
	assert(controllers[controllerName], "Controller " .. controllerName .. " does not exist")

	return controllers[controllerName]
end

-- Get a service (client-side proxy)
function KnitClient.GetService(serviceName)
	assert(started, "Cannot call GetService until Knit.Start() has been called")
	assert(allControllersInitialized, "Cannot call GetService until Knit has been initialized")
	assert(type(serviceName) == "string", "ServiceName must be a string")

	-- Check if we already have a proxy
	if services[serviceName] then
		return services[serviceName]
	end

	-- Wait for service folder to exist
	local servicesFolder = ReplicatedStorage:WaitForChild("Services", 10)
	if not servicesFolder then
		error("Services folder not found in ReplicatedStorage")
	end

	local serviceFolder = servicesFolder:WaitForChild(serviceName, 10)
	if not serviceFolder then
		error("Service " .. serviceName .. " not found")
	end

	-- Create proxy for service
	local serviceProxy = {}

	-- Map RemoteFunctions to proxy methods
	for _, child in ipairs(serviceFolder:GetChildren()) do
		if child:IsA("RemoteFunction") then
			local remoteName = child.Name
			serviceProxy[remoteName] = function(_, ...)
				return child:InvokeServer(...)
			end
		end
	end

	services[serviceName] = serviceProxy
	return serviceProxy
end

-- Start Knit
function KnitClient.Start()
	if started then
		warn("Knit.Start() called more than once")
		return
	end

	started = true

	print("[Knit] Starting on client...")

	-- PHASE 1: Call KnitInit on ALL controllers
	print("[Knit] Phase 1: Initializing all controllers...")
	for name, controller in pairs(controllers) do
		if type(controller.KnitInit) == "function" then
			local success, err = pcall(controller.KnitInit, controller)
			if not success then
				warn("[Knit] Error in " .. name .. ":KnitInit() - " .. tostring(err))
			end
		end
	end

	-- Mark all controllers as initialized
	allControllersInitialized = true
	print("[Knit] All controllers initialized")

	-- PHASE 2: Call KnitStart on ALL controllers (async)
	print("[Knit] Phase 2: Starting all controllers...")
	for name, controller in pairs(controllers) do
		if type(controller.KnitStart) == "function" then
			task.spawn(function()
				local success, err = pcall(controller.KnitStart, controller)
				if not success then
					warn("[Knit] Error in " .. name .. ":KnitStart() - " .. tostring(err))
				end
			end)
		end
	end

	print("[Knit] ✅ Started successfully on client")
end

return KnitClient
