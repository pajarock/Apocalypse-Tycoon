--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Remotes = RS:WaitForChild("Remotes")
local BaseDamaged = Remotes:WaitForChild("BaseDamaged")

local plr = Players.LocalPlayer

-- busca la base del jugador al aparecer
local function getMyBase(): BasePart?
	local bases = workspace:WaitForChild("Bases", 10)
	if not bases then return nil end
	local plate = bases:WaitForChild(plr.Name.."_Base", 5)
	if plate and plate:IsA("BasePart") then
		return plate
	end
	return nil
end

local basePart: BasePart? = nil
local ring: Part? = nil

local function ensureRing()
	if ring and ring.Parent then return end
	if not basePart then return end

	ring = Instance.new("Part")
	ring.Name = "ShieldRing"
	ring.Anchored = true
	ring.CanCollide = false
	ring.Material = Enum.Material.Neon
	ring.Color = Color3.fromRGB(50,200,255)
	ring.Transparency = 0.25
	ring.Size = Vector3.new(18, 0.2, 18) -- disco fino
	ring.Shape = Enum.PartType.Cylinder
	ring.Parent = workspace

	-- orientar el cilindro como disco en el suelo
	ring.CFrame = CFrame.new(basePart.Position + Vector3.new(0, 0.7, 0)) * CFrame.Angles(0, 0, math.rad(90))
end

local function updateShieldColor()
	if not ring then return end
	local lvl = plr:GetAttribute("ShieldLevel") or 0
	-- colores por nivel
	local c = Color3.fromRGB(120,120,120)
	if lvl >= 1 then c = Color3.fromRGB(50,200,255) end
	if lvl >= 2 then c = Color3.fromRGB(80,255,120) end
	if lvl >= 3 then c = Color3.fromRGB(255,230,80) end
	ring.Color = c
end

local function pulse()
	if not ring then return end
	local oldT = ring.Transparency
	for i=1,6 do
		ring.Transparency = 0.05 + 0.2 * math.abs(math.sin(i/1.5))
		task.wait(0.03)
	end
	ring.Transparency = oldT
end

-- on damage desde el server
BaseDamaged.OnClientEvent:Connect(function(hpNow: number, dmg: number)
	ensureRing()
	updateShieldColor()
	pulse()
end)

-- init
task.spawn(function()
	basePart = getMyBase()
	ensureRing()
	updateShieldColor()
	-- si el jugador vuelve a spawnear
	plr.CharacterAdded:Connect(function()
		basePart = getMyBase()
		ensureRing()
		updateShieldColor()
	end)
end)
