--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(RS.Shared.Remotes)
local World = require(script.Parent.Services.World)
Remotes.init()
World.build()

type PlayerState = { coins: number, rebirths: number, carried: string?, display: { string }, stallIndex: number? }
local states: { [number]: PlayerState } = {}
local stalls: { [number]: Player? } = {}
local phase = "Day"
local nightIndex = 0
local rng = Random.new()

local function notify(p: Player, text: string)
	Remotes.get("Notify"):FireClient(p, text)
end
local function sound(p: Player, key: string)
	Remotes.get("PlaySound"):FireClient(p, key)
end
local function multiplier(st: PlayerState): number
	return 1 + st.rebirths * 0.25
end
local function sync(p: Player)
	local st = states[p.UserId]
	if not st then return end
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

local function tryHarvest(player: Player)
	local st = states[player.UserId]
	if not st then return end
	if st.carried then
		notify(player, "You already carry a crate.")
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - Vector3.new(0, 1.2, 40)).Magnitude > 22 then
		notify(player, "Go to the pier.")
		return
	end
	st.carried = rollCrate()
	notify(player, "Harvested " .. (st.carried :: string))
	sound(player, "pick")
	sync(player)
end

local function assignStall(p: Player)
	for i = 1, Config.MaxStalls do
		if stalls[i] == nil then
			stalls[i] = p
			states[p.UserId].stallIndex = i
			local stall = workspace.Harbor.Stalls:FindFirstChild("Stall_" .. i)
			if stall then
				local floor = stall:FindFirstChild("Floor")
				local bill = floor and floor:FindFirstChildOfClass("BillboardGui")
				local lab = bill and bill:FindFirstChild("OwnerLabel")
				if lab and lab:IsA("TextLabel") then
					lab.Text = p.DisplayName
				end
			end
			return
		end
	end
end

Remotes.get("Harvest").OnServerEvent:Connect(tryHarvest)

Remotes.get("StockStall").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st or not st.carried or not st.stallIndex then return end
	if #st.display >= Config.MaxDisplay then
		notify(player, "Stall full — sell first.")
		return
	end
	local stall = workspace.Harbor.Stalls:FindFirstChild("Stall_" .. st.stallIndex)
	if not stall then return end
	local floor = stall.PrimaryPart
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not floor or (hrp.Position - floor.Position).Magnitude > 18 then
		notify(player, "Stand at your stall.")
		return
	end
	table.insert(st.display, st.carried)
	notify(player, "Stocked " .. st.carried)
	st.carried = nil
	sound(player, "pick")
	sync(player)
end)

Remotes.get("Sell").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then return end
	if phase ~= "Day" then
		notify(player, "Buyers only come during the day.")
		return
	end
	if #st.display == 0 then
		notify(player, "Nothing on display.")
		return
	end
	local kind = table.remove(st.display, 1) :: string
	local gain = math.floor(Config.CrateValue[kind] * multiplier(st))
	st.coins += gain
	notify(player, "Sold " .. kind .. " for " .. gain)
	sound(player, "sell")
	sync(player)
end)

Remotes.get("Steal").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then return end
	if phase ~= "Night" then
		notify(player, "Wait for the bell.")
		return
	end
	if st.carried then
		notify(player, "Hands full.")
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local bestPlayer: Player? = nil
	local bestDist = 16
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local ost = states[other.UserId]
			if ost and ost.stallIndex and #ost.display > 0 then
				local stall = workspace.Harbor.Stalls:FindFirstChild("Stall_" .. ost.stallIndex)
				local floor = stall and stall.PrimaryPart
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
		notify(player, "No open stall close enough.")
		return
	end
	local ost = states[bestPlayer.UserId]
	local kind = table.remove(ost.display, 1) :: string
	st.carried = kind
	notify(player, "Stole " .. kind .. " from " .. bestPlayer.DisplayName)
	notify(bestPlayer, player.DisplayName .. " robbed your stall!")
	sound(player, "pick")
	sync(player)
	sync(bestPlayer)
end)

Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then return end
	if st.coins < Config.RebirthCost then
		notify(player, "Need " .. Config.RebirthCost .. " coins to rebirth.")
		return
	end
	st.coins = 0
	st.rebirths += 1
	st.display = {}
	st.carried = nil
	notify(player, "Rebirth " .. st.rebirths .. " — payout x" .. string.format("%.2f", multiplier(st)))
	sync(player)
end)

local pier = workspace:WaitForChild("Harbor"):WaitForChild("Pier")
local prompt = pier:FindFirstChild("HarvestPrompt")
if prompt and prompt:IsA("ProximityPrompt") then
	prompt.Triggered:Connect(tryHarvest)
end

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
	p.CharacterAdded:Connect(function(char)
		task.wait(0.2)
		local hrp = char:FindFirstChild("HumanoidRootPart")
		local idx = states[p.UserId] and states[p.UserId].stallIndex
		if hrp and idx then
			local stall = workspace.Harbor.Stalls:FindFirstChild("Stall_" .. idx)
			if stall and stall.PrimaryPart then
				hrp.CFrame = stall.PrimaryPart.CFrame + Vector3.new(0, 4, 0)
			end
		end
	end)
end
Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	local st = states[p.UserId]
	if st and st.stallIndex then
		stalls[st.stallIndex] = nil
	end
	states[p.UserId] = nil
end)

task.spawn(function()
	while true do
		phase = "Day"
		World.setNight(false)
		Remotes.get("Phase"):FireAllClients("Day")
		task.wait(Config.DaySeconds)
		phase = "Bell"
		Remotes.get("Phase"):FireAllClients("Bell")
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "bell")
		end
		task.wait(Config.BellSeconds)
		phase = "Night"
		nightIndex += 1
		World.setNight(true)
		Remotes.get("Phase"):FireAllClients("Night")
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "night")
			sync(p)
		end
		task.wait(Config.NightSeconds)
	end
end)

print("[Last Bell] BETA 0.1 ready")
