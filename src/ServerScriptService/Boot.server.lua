--!nocheck
print("[Last Bell] Boot starting")

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

pcall(function()
	workspace.StreamingEnabled = false
end)
pcall(function()
	workspace.Terrain:Clear()
end)

local function keep(inst)
	if inst:IsA("Camera") or inst:IsA("Terrain") then
		return true
	end
	if inst.Name == "Harbor" or inst.Name == "BootFloor" or inst.Name == "BootSpawn" then
		return true
	end
	if Players:GetPlayerFromCharacter(inst) then
		return true
	end
	return false
end

for _, child in ipairs(workspace:GetChildren()) do
	if not keep(child) then
		pcall(function()
			child:Destroy()
		end)
	end
end

local function part(name, size, cf, color, parent, mat)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.Wood
	p.Anchored = true
	p.CanCollide = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function glow(p, range, bright, color)
	local l = Instance.new("PointLight")
	l.Range = range
	l.Brightness = bright
	l.Color = color or Color3.fromRGB(255, 200, 120)
	l.Parent = p
end

local function sign(adornee, text, offset, color)
	local bill = Instance.new("BillboardGui")
	bill.Name = "Sign"
	bill.Size = UDim2.fromOffset(320, 48)
	bill.StudsOffset = offset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 220
	bill.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Name = "Text"
	t.Size = UDim2.fromScale(1, 1)
	t.BackgroundTransparency = 1
	t.Text = text
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.Font = Enum.Font.SourceSansBold
	t.TextScaled = true
	t.Parent = bill
end

local floor = workspace:FindFirstChild("BootFloor")
if not (floor and floor:IsA("BasePart")) then
	floor = part("BootFloor", Vector3.new(360, 8, 360), CFrame.new(0, 4, 0), Color3.fromRGB(84, 56, 32), workspace, Enum.Material.Wood)
else
	floor.Size = Vector3.new(360, 8, 360)
end

local spawn = workspace:FindFirstChild("BootSpawn")
if not (spawn and spawn:IsA("SpawnLocation")) then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "BootSpawn"
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 9, 22)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.BrickColor = BrickColor.new("Dark orange")
	spawn.Parent = workspace
end

local oldHarbor = workspace:FindFirstChild("Harbor")
if oldHarbor then
	oldHarbor:Destroy()
end

local folder = Instance.new("Folder")
folder.Name = "Harbor"
folder.Parent = workspace
local decor = Instance.new("Folder")
decor.Name = "Decor"
decor.Parent = folder

local water = part("Water", Vector3.new(900, 10, 900), CFrame.new(0, -5, 0), Color3.fromRGB(12, 38, 68), folder, Enum.Material.Glass)
water.Transparency = 0.28
water.CanCollide = false

part("Dock", Vector3.new(280, 6, 280), CFrame.new(0, 4, 0), Color3.fromRGB(90, 60, 34), folder, Enum.Material.Wood)
part("InnerDeck", Vector3.new(120, 1, 120), CFrame.new(0, 7.2, 0), Color3.fromRGB(110, 78, 46), folder, Enum.Material.Wood)

for i = -5, 5 do
	part("Plank_" .. i, Vector3.new(260, 0.4, 3), CFrame.new(0, 7.35, i * 22), Color3.fromRGB(72, 48, 28), decor, Enum.Material.Wood).CanCollide = false
end

for a = 0, 15 do
	local ang = a / 16 * math.pi * 2
	local r = 138
	local pos = Vector3.new(math.cos(ang) * r, 8.6, math.sin(ang) * r)
	local post = part("EdgePost_" .. a, Vector3.new(1.2, 4.2, 1.2), CFrame.new(pos), Color3.fromRGB(48, 32, 20), decor, Enum.Material.Wood)
	local lamp = part("EdgeLamp_" .. a, Vector3.new(1.1, 1.1, 1.1), CFrame.new(pos + Vector3.new(0, 3, 0)), Color3.fromRGB(255, 196, 110), decor, Enum.Material.Neon)
	lamp.CanCollide = false
	glow(lamp, 22, 1.3)
end

local pier = part("Pier", Vector3.new(22, 2.4, 110), CFrame.new(0, 6.2, 165), Color3.fromRGB(118, 82, 46), folder, Enum.Material.Wood)
sign(pier, "PIER  ·  press E to harvest", Vector3.new(0, 10, 0), Color3.fromRGB(255, 220, 120))
part("PierRailL", Vector3.new(0.7, 2.6, 110), CFrame.new(-11, 8, 165), Color3.fromRGB(68, 46, 28), folder, Enum.Material.Wood)
part("PierRailR", Vector3.new(0.7, 2.6, 110), CFrame.new(11, 8, 165), Color3.fromRGB(68, 46, 28), folder, Enum.Material.Wood)
for i = 0, 6 do
	local z = 120 + i * 16
	part("PierLegL" .. i, Vector3.new(1.4, 14, 1.4), CFrame.new(-8, 0, z), Color3.fromRGB(54, 36, 22), decor, Enum.Material.Wood)
	part("PierLegR" .. i, Vector3.new(1.4, 14, 1.4), CFrame.new(8, 0, z), Color3.fromRGB(54, 36, 22), decor, Enum.Material.Wood)
end

local crateAnchor = part("CratePile", Vector3.new(12, 1, 12), CFrame.new(0, 7.6, 208), Color3.fromRGB(70, 48, 28), folder, Enum.Material.Wood)
sign(crateAnchor, "CARGO  ·  E harvest", Vector3.new(0, 9, 0), Color3.fromRGB(255, 240, 180))
local harvest = Instance.new("ProximityPrompt")
harvest.Name = "HarvestPrompt"
harvest.ObjectText = "Pier cargo"
harvest.ActionText = "Harvest crate"
harvest.HoldDuration = 0.2
harvest.MaxActivationDistance = 20
harvest.RequiresLineOfSight = false
harvest.KeyboardKeyCode = Enum.KeyCode.E
harvest.Parent = crateAnchor

local pierCrates = Instance.new("Folder")
pierCrates.Name = "PierCrates"
pierCrates.Parent = folder
local crateOff = {
	Vector3.new(-3.2, 1.6, -3),
	Vector3.new(3.2, 1.6, -3),
	Vector3.new(-3.2, 1.6, 3),
	Vector3.new(3.2, 1.6, 3),
	Vector3.new(0, 1.6, 0),
	Vector3.new(0, 4, 0),
}
for i, off in ipairs(crateOff) do
	part("Crate_" .. i, Vector3.new(3, 2.6, 3), crateAnchor.CFrame * CFrame.new(off), Color3.fromRGB(176, 122, 64), pierCrates, Enum.Material.Wood)
end
for i = 1, 8 do
	part("LooseCrate" .. i, Vector3.new(2.4, 2.2, 2.4), CFrame.new(-18 + (i % 4) * 4, 8.4, 198 + math.floor((i - 1) / 4) * 5), Color3.fromRGB(150, 100, 55), decor, Enum.Material.Wood)
end

part("CraneBase", Vector3.new(10, 6, 10), CFrame.new(28, 10, 188), Color3.fromRGB(40, 44, 52), decor, Enum.Material.Metal)
part("CraneMast", Vector3.new(3, 36, 3), CFrame.new(28, 28, 188), Color3.fromRGB(48, 52, 62), decor, Enum.Material.Metal)
part("CraneArm", Vector3.new(42, 2, 3), CFrame.new(10, 45, 188), Color3.fromRGB(210, 150, 50), decor, Enum.Material.Metal)
part("Hook", Vector3.new(1.4, 8, 1.4), CFrame.new(-8, 36, 188), Color3.fromRGB(30, 30, 34), decor, Enum.Material.Metal)

part("Warehouse", Vector3.new(48, 22, 28), CFrame.new(-90, 18, -40), Color3.fromRGB(78, 58, 42), decor, Enum.Material.Brick)
part("WarehouseRoof", Vector3.new(52, 2, 32), CFrame.new(-90, 30, -40), Color3.fromRGB(48, 32, 24), decor, Enum.Material.Wood)
part("WarehouseDoor", Vector3.new(12, 14, 1), CFrame.new(-90, 14, -26), Color3.fromRGB(30, 22, 16), decor, Enum.Material.Wood)
sign(folder:FindFirstChild("Warehouse") or decor:FindFirstChild("Warehouse"), "BONDED STORE", Vector3.new(0, 16, 0), Color3.fromRGB(255, 210, 140))

part("LightHouseBase", Vector3.new(16, 8, 16), CFrame.new(110, 11, -110), Color3.fromRGB(210, 210, 200), decor, Enum.Material.Concrete)
part("LightHouse", Vector3.new(10, 48, 10), CFrame.new(110, 36, -110), Color3.fromRGB(230, 230, 220), decor, Enum.Material.Concrete)
local beacon = part("Beacon", Vector3.new(8, 6, 8), CFrame.new(110, 62, -110), Color3.fromRGB(255, 230, 140), decor, Enum.Material.Neon)
glow(beacon, 60, 3, Color3.fromRGB(255, 220, 150))
sign(beacon, "LAST BELL HARBOR", Vector3.new(0, 8, 0), Color3.fromRGB(255, 230, 160))

part("TowerBase", Vector3.new(18, 3, 18), CFrame.new(0, 8.6, 0), Color3.fromRGB(36, 38, 52), folder, Enum.Material.Slate)
part("BellTower", Vector3.new(8, 32, 8), CFrame.new(0, 25, 0), Color3.fromRGB(32, 34, 48), folder, Enum.Material.Slate)
local bell = part("Bell", Vector3.new(7, 5, 7), CFrame.new(0, 42, 0), Color3.fromRGB(228, 186, 52), folder, Enum.Material.Neon)
glow(bell, 28, 2)
sign(bell, "THE BELL  ·  P rebirth at 500", Vector3.new(0, 8, 0), Color3.fromRGB(255, 220, 90))

part("MarketRing", Vector3.new(160, 0.6, 160), CFrame.new(0, 7.5, 0), Color3.fromRGB(62, 44, 30), decor, Enum.Material.Wood).CanCollide = false

local stalls = Instance.new("Folder")
stalls.Name = "Stalls"
stalls.Parent = folder
local stallNames = {
	"Salt & Oak",
	"Spice Hold",
	"Silk Yard",
	"Relic Shed",
	"Net & Twine",
	"Amber Casks",
	"North Quay",
	"South Quay",
}
for i = 1, 8 do
	local a = ((i - 1) / 8) * math.pi * 2 + 0.2
	local pos = Vector3.new(math.cos(a) * 78, 8, math.sin(a) * 78)
	local look = CFrame.new(pos, Vector3.new(0, 8, 0))
	local m = Instance.new("Model")
	m.Name = "Stall_" .. i
	m.Parent = stalls
	local fl = part("Floor", Vector3.new(18, 1.2, 18), look, Color3.fromRGB(58, 40, 28), m, Enum.Material.Wood)
	m.PrimaryPart = fl
	part("Back", Vector3.new(18, 10, 0.8), look * CFrame.new(0, 5.4, 8.6), Color3.fromRGB(92, 62, 38), m, Enum.Material.Wood)
	part("SideL", Vector3.new(0.7, 8, 14), look * CFrame.new(-8.6, 4.6, 1), Color3.fromRGB(80, 54, 34), m, Enum.Material.Wood)
	part("SideR", Vector3.new(0.7, 8, 14), look * CFrame.new(8.6, 4.6, 1), Color3.fromRGB(80, 54, 34), m, Enum.Material.Wood)
	part("Roof", Vector3.new(20, 0.8, 20), look * CFrame.new(0, 10.6, 0) * CFrame.Angles(0.08, 0, 0), Color3.fromRGB(64, 40, 24), m, Enum.Material.Wood)
	part("Awning", Vector3.new(18, 0.4, 6), look * CFrame.new(0, 8.2, -8), Color3.fromRGB(180, 70, 50), m, Enum.Material.Fabric)
	part("Counter", Vector3.new(12, 2.2, 2.4), look * CFrame.new(0, 1.8, -7), Color3.fromRGB(120, 86, 52), m, Enum.Material.Wood)
	local lamp = part("Lamp", Vector3.new(1.6, 1.6, 1.6), look * CFrame.new(0, 9.4, 0), Color3.fromRGB(255, 210, 130), m, Enum.Material.Neon)
	glow(lamp, 24, 1.8)
	local display = Instance.new("Folder")
	display.Name = "Display"
	display.Parent = m
	sign(fl, stallNames[i], Vector3.new(0, 8, 0), Color3.fromRGB(255, 230, 180))
end

Lighting.ClockTime = 17.2
Lighting.Brightness = 2.2
Lighting.Ambient = Color3.fromRGB(70, 64, 58)
Lighting.OutdoorAmbient = Color3.fromRGB(110, 100, 88)
Lighting.FogColor = Color3.fromRGB(70, 92, 118)
Lighting.FogStart = 80
Lighting.FogEnd = 420

print("[Last Bell] Boot harbor ready")
