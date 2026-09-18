--!strict
local RS = game:GetService("ReplicatedStorage")
local Remotes = {}
local NAMES = { "Harvest", "StockStall", "Sell", "Steal", "Rebirth", "Notify", "Phase", "Stats", "PlaySound" }
local cache = {}
function Remotes.init()
	local f = RS:FindFirstChild("Remotes")
	if not f then f = Instance.new("Folder") f.Name = "Remotes" f.Parent = RS end
	for _, n in ipairs(NAMES) do
		local ev = f:FindFirstChild(n)
		if not ev then ev = Instance.new("RemoteEvent") ev.Name = n ev.Parent = f end
		cache[n] = ev
	end
end
function Remotes.get(name: string): RemoteEvent
	if cache[name] then return cache[name] end
	local f = RS:WaitForChild("Remotes")
	local ev = f:WaitForChild(name) :: RemoteEvent
	cache[name] = ev
	return ev
end
return Remotes
