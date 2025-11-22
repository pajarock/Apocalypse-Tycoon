--!strict
-- 1_CreateRemotes.server.lua
-- Crea todos los remotes ANTES que cualquier otro script

local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[1_REMOTES] Iniciando creaciÃÂ³n de remotes...")

-- Crear carpeta Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

-- Lista de todos los remotes necesarios
local remotesList = {
	{Name = "RequestPurchase", Type = "RemoteEvent"},
	{Name = "RequestState", Type = "RemoteFunction"},
	{Name = "RequestBaseState", Type = "RemoteFunction"},
	{Name = "RequestRepair", Type = "RemoteEvent"},
	{Name = "BaseStateChanged", Type = "RemoteEvent"},
	{Name = "CashTick", Type = "RemoteEvent"},
	{Name = "DebugSpawnMeteor", Type = "RemoteEvent"},
	{Name = "BaseDamaged", Type = "RemoteEvent"},
}

-- Crear cada remote
for _, remote in ipairs(remotesList) do
	if not Remotes:FindFirstChild(remote.Name) then
		local r
		if remote.Type == "RemoteEvent" then
			r = Instance.new("RemoteEvent")
		else
			r = Instance.new("RemoteFunction")
		end
		r.Name = remote.Name
		r.Parent = Remotes
	end
end

print("[1_REMOTES] Ã¢ÂÂ Todos los remotes creados exitosamente")