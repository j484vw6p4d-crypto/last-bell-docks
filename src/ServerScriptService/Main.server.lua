--!strict
print("[Last Bell] Main starting")

local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local RS = game:GetService("ReplicatedStorage")

pcall(function()
	workspace.StreamingEnabled = false
end)
pcall(function()
	workspace.Terrain.Decoration = false
	workspace.Terrain:Clear()
end)
for _, child in ipairs(workspace:GetChildren()) do
	if child:IsA("Camera") or child:IsA("Terrain") then
		continue
	end
	if Players:GetPlayerFromCharacter(child) then
		continue
	end
	pcall(function()
		child:Destroy()
	end)
end

local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(RS.Shared.Remotes)
local World = require(script.Parent:WaitForChild("Services"):WaitForChild("World"))

Remotes.init()
local built, buildErr = pcall(function()
	World.build()
end)
if not built then
	warn("[Last Bell] World.build FAILED: ", buildErr)
else
	print("[Last Bell] World.build ok")
end
pcall(function()
	World.guardLeftovers()
end)

for _, child in ipairs(StarterPack:GetChildren()) do
	child:Destroy()
end

type PlayerState = {
	coins: number,
	rebirths: number,
	carried: string?,
	display: { string },
	stallIndex: number?,
}

local states: { [number]: PlayerState } = {}
local stalls: { [number]: Player? } = {}
local phase = "Day"
local nightIndex = 0
local rng = Random.new()
local pierCount = Config.PierMaxCrates
local harvestLock: { [number]: boolean } = {}
local restocking = false

World.setPierGrown(pierCount)

local function notify(p: Player, text: string)
	Remotes.get("Notify"):FireClient(p, text)
end

local function sound(p: Player, key: string)
	Remotes.get("PlaySound"):FireClient(p, key)
end

local function multiplier(st: PlayerState): number
	return 1 + st.rebirths * 0.25
end

local function harborFolder(): Instance
	return workspace:WaitForChild("Harbor")
end

local function pilePart(): BasePart
	return harborFolder():WaitForChild("CratePile") :: BasePart
end

local function findStall(index: number): Instance?
	local folder = harborFolder():FindFirstChild("Stalls")
	if not folder then
		return nil
	end
	return folder:FindFirstChild("Stall_" .. index)
end

local function sync(p: Player)
	local st = states[p.UserId]
	if not st then
		return
	end
	local ls = p:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = p
		local c = Instance.new("IntValue")
		c.Name = "Coins"
		c.Parent = ls
		local n = Instance.new("IntValue")
		n.Name = "Nights"
		n.Parent = ls
	end
	(ls:FindFirstChild("Coins") :: IntValue).Value = st.coins
	(ls:FindFirstChild("Nights") :: IntValue).Value = nightIndex
	Remotes.get("Stats"):FireClient(p, {
		coins = st.coins,
		phase = phase,
		carried = st.carried,
		display = #st.display,
		rebirths = st.rebirths,
		night = nightIndex,
		need = Config.RebirthCost,
	})
end

local function rollCrate(): string
	local total = 0
	for _, w in pairs(Config.CrateWeight) do
		total += w
	end
	local r = rng:NextNumber(0, total)
	local acc = 0
	for name, w in pairs(Config.CrateWeight) do
		acc += w
		if r <= acc then
			return name
		end
	end
	return "Wood"
end

local function stripTools(p: Player)
	local pack = p:FindFirstChild("Backpack")
	if pack then
		for _, t in ipairs(pack:GetChildren()) do
			t:Destroy()
		end
	end
	local char = p.Character
	if char then
		for _, t in ipairs(char:GetChildren()) do
			if t:IsA("Tool") then
				t:Destroy()
			end
		end
	end
end

local function refreshBuyers()
	for i = 1, Config.MaxStalls do
		local owner = stalls[i]
		local show = false
		if phase == "Day" and owner then
			local st = states[owner.UserId]
			show = st ~= nil and #st.display > 0
		end
		World.setBuyer(i, show)
	end
end

local function assignStall(p: Player)
	for i = 1, Config.MaxStalls do
		if stalls[i] == nil then
			stalls[i] = p
			states[p.UserId].stallIndex = i
			World.setStallOwner(i, p.DisplayName .. "'s stall")
			return
		end
	end
end

local function scheduleRestock()
	if restocking then
		return
	end
	restocking = true
	task.spawn(function()
		while pierCount < Config.PierMaxCrates do
			task.wait(Config.GrowSeconds)
			pierCount += 1
			World.setPierGrown(pierCount)
			if pierCount == 1 then
				for _, p in ipairs(Players:GetPlayers()) do
					notify(p, "Pier cargo is ready — E to harvest.")
				end
			end
		end
		restocking = false
	end)
end

local function doHarvest(player: Player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if harvestLock[player.UserId] then
		return
	end
	harvestLock[player.UserId] = true
	task.delay(0.35, function()
		harvestLock[player.UserId] = nil
	end)
	if st.carried then
		notify(player, "Hands full — press F at YOUR stall.")
		return
	end
	if pierCount < 1 then
		notify(player, "Pier is empty — cargo is still being unloaded.")
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local pile = pilePart()
	if not hrp or (hrp.Position - pile.Position).Magnitude > 24 then
		notify(player, "Walk onto the PIER (long dock with crates).")
		return
	end
	pierCount -= 1
	World.setPierGrown(pierCount)
	scheduleRestock()
	st.carried = rollCrate()
	World.attachCarry(player, st.carried)
	notify(player, "Harvested " .. st.carried .. " — F at your stall to stock.")
	sound(player, "pick")
	sync(player)
end

Remotes.get("Harvest").OnServerEvent:Connect(doHarvest)

local pile = pilePart()
local prompt = pile:WaitForChild("HarvestPrompt") :: ProximityPrompt
prompt.Triggered:Connect(doHarvest)

Remotes.get("StockStall").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if not st.carried then
		notify(player, "Harvest a crate first (E on the pier).")
		return
	end
	if not st.stallIndex then
		notify(player, "No stall assigned.")
		return
	end
	if #st.display >= Config.MaxDisplay then
		notify(player, "Stall full — press Q to sell during DAY.")
		return
	end
	local stall = findStall(st.stallIndex)
	local floor = stall and stall:FindFirstChild("Floor") :: BasePart?
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or not floor or (hrp.Position - floor.Position).Magnitude > 22 then
		notify(player, "Stand on YOUR stall floor (the one with your name).")
		return
	end
	local kind = st.carried
	table.insert(st.display, kind)
	st.carried = nil
	World.attachCarry(player, nil)
	World.refreshDisplay(st.stallIndex, st.display)
	refreshBuyers()
	notify(player, "Stocked " .. kind .. " — Q sells to the gold buyer in DAY.")
	sound(player, "pick")
	sync(player)
end)

Remotes.get("Sell").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st or not st.stallIndex then
		return
	end
	if phase ~= "Day" then
		notify(player, "Buyers only come during DAY.")
		return
	end
	if #st.display == 0 then
		notify(player, "Stock the stall first (F).")
		return
	end
	local stall = findStall(st.stallIndex)
	local floor = stall and stall:FindFirstChild("Floor") :: BasePart?
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp or not floor or (hrp.Position - floor.Position).Magnitude > 22 then
		notify(player, "Stand at YOUR stall to sell (gold buyer).")
		return
	end
	local kind = table.remove(st.display, 1) :: string
	local gain = math.floor((Config.CrateValue[kind] or 8) * multiplier(st))
	st.coins += gain
	World.refreshDisplay(st.stallIndex, st.display)
	refreshBuyers()
	World.floatText(floor.Position, "+" .. gain .. " coins", Color3.fromRGB(120, 255, 140))
	notify(player, "Sold " .. kind .. " for " .. gain .. " coins.")
	sound(player, "sell")
	sync(player)
end)

Remotes.get("Steal").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if phase ~= "Night" then
		notify(player, "Wait for the bell — steal only at NIGHT.")
		return
	end
	if st.carried then
		notify(player, "Hands full.")
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	local bestPlayer: Player? = nil
	local bestDist = 16
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local ost = states[other.UserId]
			if ost and ost.stallIndex and #ost.display > 0 then
				local stall = findStall(ost.stallIndex)
				local floor = stall and stall:FindFirstChild("Floor") :: BasePart?
				if floor then
					local d = (hrp.Position - floor.Position).Magnitude
					if d < bestDist then
						bestDist = d
						bestPlayer = other
					end
				end
			end
		end
	end
	if not bestPlayer then
		notify(player, "No stocked stall close enough. (Need another player.)")
		return
	end
	local ost = states[bestPlayer.UserId]
	local kind = table.remove(ost.display, 1) :: string
	st.carried = kind
	World.attachCarry(player, kind)
	if ost.stallIndex then
		World.refreshDisplay(ost.stallIndex, ost.display)
	end
	refreshBuyers()
	notify(player, "Stole " .. kind .. " from " .. bestPlayer.DisplayName)
	notify(bestPlayer, player.DisplayName .. " robbed your stall!")
	sound(player, "pick")
	sync(player)
	sync(bestPlayer)
end)

Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if st.coins < Config.RebirthCost then
		notify(player, "Need " .. Config.RebirthCost .. " coins to rebirth. (P at the bell)")
		return
	end
	st.coins = 0
	st.rebirths += 1
	st.display = {}
	st.carried = nil
	World.attachCarry(player, nil)
	if st.stallIndex then
		World.refreshDisplay(st.stallIndex, st.display)
	end
	refreshBuyers()
	notify(player, "Rebirth " .. st.rebirths .. " — payout x" .. string.format("%.2f", multiplier(st)))
	sync(player)
end)

local function onPlayer(p: Player)
	states[p.UserId] = {
		coins = Config.StartingCoins,
		rebirths = 0,
		carried = nil,
		display = {},
		stallIndex = nil,
	}
	assignStall(p)
	sync(p)
	stripTools(p)
	local function hookCharacter(char: Model)
		task.wait(0.2)
		stripTools(p)
		local st = states[p.UserId]
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and st and st.stallIndex then
			local stall = findStall(st.stallIndex)
			local floor = stall and stall:FindFirstChild("Floor") :: BasePart?
			if floor then
				hrp.CFrame = floor.CFrame + Vector3.new(0, 5, 0)
			end
		end
		if st then
			World.attachCarry(p, st.carried)
		end
		if phase == "Night" then
			notify(p, "NIGHT — R near another stall to steal.")
		else
			notify(p, "DAY loop: E pier  →  F your stall  →  Q gold buyer")
		end
	end
	p.CharacterAdded:Connect(hookCharacter)
	if p.Character then
		task.spawn(hookCharacter, p.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	local st = states[p.UserId]
	if st and st.stallIndex then
		stalls[st.stallIndex] = nil
		World.setStallOwner(st.stallIndex, "Empty stall")
		World.refreshDisplay(st.stallIndex, {})
		World.setBuyer(st.stallIndex, false)
	end
	states[p.UserId] = nil
end)

task.spawn(function()
	while true do
		phase = "Day"
		World.setNight(false)
		refreshBuyers()
		Remotes.get("Phase"):FireAllClients("Day")
		for _, p in ipairs(Players:GetPlayers()) do
			notify(p, "DAY — harvest (E), stock (F), sell (Q).")
			sync(p)
		end
		task.wait(Config.DaySeconds)

		phase = "Bell"
		World.ringBell()
		Remotes.get("Phase"):FireAllClients("Bell")
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "bell")
			notify(p, "THE BELL — night is coming.")
		end
		task.wait(Config.BellSeconds)

		phase = "Night"
		nightIndex += 1
		World.setNight(true)
		refreshBuyers()
		Remotes.get("Phase"):FireAllClients("Night")
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "night")
			notify(p, "NIGHT — R near another stall to steal.")
			sync(p)
		end
		task.wait(Config.NightSeconds)
	end
end)

print("[Last Bell] Harbor ready — leftover map wiped, ring on the dock")
