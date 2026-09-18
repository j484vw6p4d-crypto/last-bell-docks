--!nocheck
-- Runs with zero requires. If Main/World break, the player still stands on wood.
print("[Last Bell] Boot starting")

local Players = game:GetService("Players")

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

local floor = workspace:FindFirstChild("BootFloor")
if not (floor and floor:IsA("BasePart")) then
	floor = Instance.new("Part")
	floor.Name = "BootFloor"
	floor.Size = Vector3.new(240, 8, 240)
	floor.CFrame = CFrame.new(0, 4, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Color = Color3.fromRGB(92, 62, 36)
	floor.Material = Enum.Material.Wood
	floor.Parent = workspace
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

print("[Last Bell] Boot floor ready")
