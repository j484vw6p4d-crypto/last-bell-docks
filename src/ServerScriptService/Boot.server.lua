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
	p.Parent = parent
	return p
end

local function sign(adornee, text, offset, color)
	local bill = Instance.new("BillboardGui")
	bill.Name = "Sign"
	bill.Size = UDim2.fromOffset(280, 42)
	bill.StudsOffset = offset
	bill.AlwaysOnTop = true
	bill.MaxDistance = 180
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
	floor = part("BootFloor", Vector3.new(240, 8, 240), CFrame.new(0, 4, 0), Color3.fromRGB(92, 62, 36), workspace, Enum.Material.Wood)
end

local spawn = workspace:FindFirstChild("BootSpawn")
if not (spawn and spawn:IsA("SpawnLocation")) then
	spawn = Instance.new("SpawnLocation")
	spawn.Name = "BootSpawn"
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 9, 16)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.BrickColor = BrickColor.new("Dark orange")
	spawn.Parent = workspace
end

if workspace:FindFirstChild("Harbor") then
	print("[Last Bell] Boot: Harbor already exists")
	return
end

local folder = Instance.new("Folder")
folder.Name = "Harbor"
folder.Parent = workspace

local water = part("Water", Vector3.new(500, 8, 500), CFrame.new(0, -4, 0), Color3.fromRGB(16, 46, 78), folder, Enum.Material.Glass)
water.Transparency = 0.35
water.CanCollide = false

part("Dock", Vector3.new(200, 6, 200), CFrame.new(0, 4, 0), Color3.fromRGB(92, 62, 36), folder, Enum.Material.Wood)

local pier = part("Pier", Vector3.new(18, 2, 70), CFrame.new(0, 6, 110), Color3.fromRGB(112, 78, 44), folder, Enum.Material.Wood)
sign(pier, "PIER - press E to harvest", Vector3.new(0, 9, 0), Color3.fromRGB(255, 220, 120))

part("PierRailL", Vector3.new(0.6, 2.4, 70), CFrame.new(-9, 7.6, 110), Color3.fromRGB(72, 50, 30), folder, Enum.Material.Wood)
part("PierRailR", Vector3.new(0.6, 2.4, 70), CFrame.new(9, 7.6, 110), Color3.fromRGB(72, 50, 30), folder, Enum.Material.Wood)

local crateAnchor = part("CratePile", Vector3.new(8, 1, 8), CFrame.new(0, 7.2, 136), Color3.fromRGB(70, 48, 28), folder, Enum.Material.Wood)
sign(crateAnchor, "CARGO - E harvest", Vector3.new(0, 8, 0), Color3.fromRGB(255, 240, 180))

local harvest = Instance.new("ProximityPrompt")
harvest.Name = "HarvestPrompt"
harvest.ObjectText = "Pier cargo"
harvest.ActionText = "Harvest crate"
harvest.HoldDuration = 0.2
harvest.MaxActivationDistance = 18
harvest.RequiresLineOfSight = false
harvest.KeyboardKeyCode = Enum.KeyCode.E
harvest.Parent = crateAnchor

local pierCrates = Instance.new("Folder")
pierCrates.Name = "PierCrates"
pierCrates.Parent = folder
local offsets = {
	Vector3.new(-2.2, 1.4, -2),
	Vector3.new(2.2, 1.4, -2),
	Vector3.new(-2.2, 1.4, 2),
	Vector3.new(2.2, 1.4, 2),
	Vector3.new(0, 3.4, 0),
	Vector3.new(0, 1.4, 0),
}
for i, off in ipairs(offsets) do
	part("Crate_" .. i, Vector3.new(2.6, 2.2, 2.6), crateAnchor.CFrame * CFrame.new(off), Color3.fromRGB(168, 118, 64), pierCrates, Enum.Material.Wood)
end

part("TowerBase", Vector3.new(14, 2, 14), CFrame.new(0, 8, 0), Color3.fromRGB(48, 48, 62), folder, Enum.Material.SmoothPlastic)
part("BellTower", Vector3.new(7, 24, 7), CFrame.new(0, 21, 0), Color3.fromRGB(42, 42, 58), folder, Enum.Material.SmoothPlastic)
local bell = part("Bell", Vector3.new(6, 4, 6), CFrame.new(0, 34, 0), Color3.fromRGB(228, 186, 52), folder, Enum.Material.Neon)
sign(bell, "THE BELL - P rebirth at 500", Vector3.new(0, 8, 0), Color3.fromRGB(255, 220, 90))

local stalls = Instance.new("Folder")
stalls.Name = "Stalls"
stalls.Parent = folder

for i = 1, 8 do
	local a = ((i - 1) / 8) * math.pi * 2
	local pos = Vector3.new(math.cos(a) * 70, 7.5, math.sin(a) * 70)
	local look = CFrame.new(pos, Vector3.new(0, 7.5, 0))
	local m = Instance.new("Model")
	m.Name = "Stall_" .. i
	m.Parent = stalls
	local fl = part("Floor", Vector3.new(16, 1, 16), look, Color3.fromRGB(58, 42, 30), m, Enum.Material.Wood)
	m.PrimaryPart = fl
	part("Back", Vector3.new(16, 8, 0.7), look * CFrame.new(0, 4.5, 7.6), Color3.fromRGB(86, 60, 38), m, Enum.Material.Wood)
	part("Roof", Vector3.new(17, 0.7, 17), look * CFrame.new(0, 9.2, 0), Color3.fromRGB(72, 48, 30), m, Enum.Material.Wood)
	part("Counter", Vector3.new(10, 2, 2.2), look * CFrame.new(0, 1.6, -6.2), Color3.fromRGB(110, 82, 52), m, Enum.Material.Wood)
	part("Lamp", Vector3.new(1.4, 1.4, 1.4), look * CFrame.new(0, 8.2, 0), Color3.fromRGB(255, 210, 130), m, Enum.Material.Neon)
	local display = Instance.new("Folder")
	display.Name = "Display"
	display.Parent = m
	sign(fl, "Empty stall", Vector3.new(0, 7, 0), Color3.fromRGB(230, 230, 230))
end

Lighting.ClockTime = 16.6
Lighting.Brightness = 2.4

print("[Last Bell] Boot harbor ready")
