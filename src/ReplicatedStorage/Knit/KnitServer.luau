--[[
	KnitServer - Simplified Version (No External Dependencies)

	LIFECYCLE:
	1. CreateService() - Register services
	2. Start() - Initialize all services
	   a. Call KnitInit() on ALL services FIRST
	   b. Then call KnitStart() on ALL services
	3. GetService() - Available after Start() completes phase 2a
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local KnitServer = {}
local services = {}
local started = false
local allServicesInitialized = false

-- Create a service
function KnitServer.CreateService(serviceDef)
	assert(type(serviceDef) == "table", "Service must be a table")
	assert(type(serviceDef.Name) == "string", "Service.Name must be a string")
	assert(not services[serviceDef.Name], "Service " .. serviceDef.Name .. " already exists")
	assert(not started, "Cannot create services after Knit.Start() has been called")

	local service = serviceDef

	-- Initialize Client table
	if type(service.Client) ~= "table" then
		service.Client = {}
	end
	service.Client.Server = service

	services[service.Name] = service

	return service
end

-- Get a service (only after Start)
function KnitServer.GetService(serviceName)
	assert(started, "Cannot call GetService until Knit.Start() has been called")
	assert(allServicesInitialized, "Cannot call GetService until all services have been initialized")
	assert(type(serviceName) == "string", "ServiceName must be a string")
	assert(services[serviceName], "Service " .. serviceName .. " does not exist")

	return services[serviceName]
end

-- Start Knit
function KnitServer.Start()
	if started then
		warn("Knit.Start() called more than once")
		return
	end

	started = true

	print("[Knit] Starting...")

	-- PHASE 1: Call KnitInit on ALL services
	print("[Knit] Phase 1: Initializing all services...")
	for name, service in pairs(services) do
		if type(service.KnitInit) == "function" then
			local success, err = pcall(service.KnitInit, service)
			if not success then
				warn("[Knit] Error in " .. name .. ":KnitInit() - " .. tostring(err))
			end
		end
	end

	-- Mark all services as initialized
	allServicesInitialized = true
	print("[Knit] All services initialized")

	-- Create RemoteFunctions for Client methods
	local remoteFolder = Instance.new("Folder")
	remoteFolder.Name = "Services"
	remoteFolder.Parent = ReplicatedStorage

	for _, service in pairs(services) do
		-- Create folder for this service's remotes
		local serviceFolder = Instance.new("Folder")
		serviceFolder.Name = service.Name
		serviceFolder.Parent = remoteFolder

		-- Create RemoteFunctions for each Client method
		for key, value in pairs(service.Client) do
			if type(value) == "function" and key ~= "Server" then
				local remoteFunc = Instance.new("RemoteFunction")
				remoteFunc.Name = key
				remoteFunc.Parent = serviceFolder

				-- Bind to the function
				remoteFunc.OnServerInvoke = function(player, ...)
					return value(service.Client, player, ...)
				end
			end
		end
	end

	-- PHASE 2: Call KnitStart on ALL services (async)
	print("[Knit] Phase 2: Starting all services...")
	for name, service in pairs(services) do
		if type(service.KnitStart) == "function" then
			task.spawn(function()
				local success, err = pcall(service.KnitStart, service)
				if not success then
					warn("[Knit] Error in " .. name .. ":KnitStart() - " .. tostring(err))
				end
			end)
		end
	end

	print("[Knit] ✅ Started successfully")
end

return KnitServer
