--!nocheck
print("[Last Bell] Main starting")

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RS = game:GetService("ReplicatedStorage")

local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Remotes = require(RS.Shared.Remotes)
Remotes.init()

local harbor = workspace:WaitForChild("Harbor", 15)
if not harbor then
	warn("[Last Bell] Harbor missing — Boot did not run")
end

local states = {}
local stallOwner = {}
local phase = "Day"
local nightIndex = 0
local rng = Random.new()
local pierCount = Config.PierMaxCrates
local harvestLock = {}
local restocking = false

local function notify(p, text)
	Remotes.get("Notify"):FireClient(p, text)
end

local function sound(p, key)
	Remotes.get("PlaySound"):FireClient(p, key)
end

local function pile()
	local p = harbor and harbor:FindFirstChild("CratePile")
	if p and p:IsA("BasePart") then
		return p
	end
	return nil
end

local function stallModel(i)
	local folder = harbor and harbor:FindFirstChild("Stalls")
	return folder and folder:FindFirstChild("Stall_" .. i)
end

local function stallFloor(i)
	local m = stallModel(i)
	local f = m and m:FindFirstChild("Floor")
	if f and f:IsA("BasePart") then
		return f
	end
	return nil
end

local function setSign(part, text, color)
	if not part then
		return
	end
	local bill = part:FindFirstChild("Sign")
	if not bill then
		bill = Instance.new("BillboardGui")
		bill.Name = "Sign"
		bill.Size = UDim2.fromOffset(280, 42)
		bill.StudsOffset = Vector3.new(0, 7, 0)
		bill.AlwaysOnTop = true
		bill.Parent = part
		local t = Instance.new("TextLabel")
		t.Name = "Text"
		t.Size = UDim2.fromScale(1, 1)
		t.BackgroundTransparency = 1
		t.Font = Enum.Font.SourceSansBold
		t.TextScaled = true
		t.Parent = bill
	end
	local lab = bill:FindFirstChild("Text")
	if lab and lab:IsA("TextLabel") then
		lab.Text = text
		lab.TextColor3 = color or Color3.new(1, 1, 1)
	end
end

local function attachCarry(player, kind)
	local char = player.Character
	if not char then
		return
	end
	local old = char:FindFirstChild("CarriedCrate")
	if old then
		old:Destroy()
	end
	if not kind then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local box = Instance.new("Part")
	box.Name = "CarriedCrate"
	box.Size = Vector3.new(1.8, 1.6, 1.8)
	box.Color = Config.CrateColor[kind] or Color3.fromRGB(160, 110, 60)
	box.Material = Enum.Material.Wood
	box.Massless = true
	box.CanCollide = false
	box.Anchored = false
	box.CFrame = hrp.CFrame * CFrame.new(0, 2.1, -1.5)
	box.Parent = char
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hrp
	weld.Part1 = box
	weld.Parent = box
end

local function refreshDisplay(index, kinds)
	local m = stallModel(index)
	if not m then
		return
	end
	local folder = m:FindFirstChild("Display")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Display"
		folder.Parent = m
	end
	folder:ClearAllChildren()
	local floor = stallFloor(index)
	if not floor then
		return
	end
	for i, kind in ipairs(kinds) do
		local box = Instance.new("Part")
		box.Name = kind
		box.Size = Vector3.new(2.4, 2.2, 2.4)
		box.Anchored = true
		box.CanCollide = false
		box.Color = Config.CrateColor[kind] or Color3.fromRGB(160, 110, 60)
		box.Material = Enum.Material.Wood
		box.CFrame = floor.CFrame * CFrame.new(-4 + (i - 1) * 2.8, 2.4, 1)
		box.Parent = folder
	end
end

local function setBuyer(index, visible)
	local m = stallModel(index)
	if not m then
		return
	end
	local old = m:FindFirstChild("Buyer")
	if old then
		old:Destroy()
	end
	if not visible then
		return
	end
	local floor = stallFloor(index)
	if not floor then
		return
	end
	local buyer = Instance.new("Part")
	buyer.Name = "Buyer"
	buyer.Size = Vector3.new(2.2, 5.2, 2.2)
	buyer.CFrame = floor.CFrame * CFrame.new(5.2, 3.4, -4.5)
	buyer.Color = Color3.fromRGB(255, 196, 64)
	buyer.Material = Enum.Material.Neon
	buyer.Anchored = true
	buyer.CanCollide = false
	buyer.Parent = m
	setSign(buyer, "BUYER - press Q", Color3.fromRGB(255, 230, 120))
	local bill = buyer:FindFirstChild("Sign")
	if bill then
		bill.StudsOffset = Vector3.new(0, 4.2, 0)
	end
end

local function setPierVisual()
	local folder = harbor and harbor:FindFirstChild("PierCrates")
	if not folder then
		return
	end
	local kids = folder:GetChildren()
	table.sort(kids, function(a, b)
		return a.Name < b.Name
	end)
	for i, child in ipairs(kids) do
		if child:IsA("BasePart") then
			child.Transparency = if i <= pierCount then 0 else 0.75
		end
	end
end

local function setNight(on)
	Lighting.ClockTime = if on then 0.4 else 16.6
	Lighting.Brightness = if on then 0.35 else 2.4
	Lighting.Ambient = if on then Color3.fromRGB(18, 20, 32) else Color3.fromRGB(90, 80, 70)
end

local function rollCrate()
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

local function sync(p)
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
	end
	local coins = ls:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		coins.Value = st.coins
	end
	Remotes.get("Stats"):FireClient(p, {
		coins = st.coins,
		phase = phase,
		carried = st.carried,
		display = #st.display,
		rebirths = st.rebirths,
		need = Config.RebirthCost,
	})
end

local function refreshBuyers()
	for i = 1, Config.MaxStalls do
		local owner = stallOwner[i]
		local show = false
		if phase == "Day" and owner and states[owner.UserId] and #states[owner.UserId].display > 0 then
			show = true
		end
		setBuyer(i, show)
	end
end

local function assignStall(p)
	for i = 1, Config.MaxStalls do
		if stallOwner[i] == nil then
			stallOwner[i] = p
			states[p.UserId].stallIndex = i
			setSign(stallFloor(i), p.DisplayName .. "'s stall", Color3.fromRGB(255, 230, 180))
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
			setPierVisual()
		end
		restocking = false
	end)
end

local function doHarvest(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if harvestLock[player.UserId] then
		return
	end
	harvestLock[player.UserId] = true
	task.delay(0.3, function()
		harvestLock[player.UserId] = nil
	end)
	if st.carried then
		notify(player, "Hands full — F at YOUR named stall.")
		return
	end
	if pierCount < 1 then
		notify(player, "Pier empty — cargo is unloading.")
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local crate = pile()
	if not hrp or not crate or (hrp.Position - crate.Position).Magnitude > 28 then
		notify(player, "Walk onto the PIER with the crates.")
		return
	end
	pierCount -= 1
	setPierVisual()
	scheduleRestock()
	st.carried = rollCrate()
	attachCarry(player, st.carried)
	notify(player, "Got " .. st.carried .. " — F at your stall.")
	sound(player, "pick")
	sync(player)
end

Remotes.get("Harvest").OnServerEvent:Connect(doHarvest)
local crate = pile()
if crate then
	local prompt = crate:FindFirstChild("HarvestPrompt")
	if prompt and prompt:IsA("ProximityPrompt") then
		prompt.Triggered:Connect(doHarvest)
	end
end

Remotes.get("StockStall").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if not st.carried then
		notify(player, "Harvest first (E on the pier).")
		return
	end
	if not st.stallIndex then
		notify(player, "No stall assigned.")
		return
	end
	if #st.display >= Config.MaxDisplay then
		notify(player, "Stall full — Q to sell in DAY.")
		return
	end
	local floor = stallFloor(st.stallIndex)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not floor or (hrp.Position - floor.Position).Magnitude > 24 then
		notify(player, "Stand on YOUR stall (your name on the sign).")
		return
	end
	local kind = st.carried
	table.insert(st.display, kind)
	st.carried = nil
	attachCarry(player, nil)
	refreshDisplay(st.stallIndex, st.display)
	refreshBuyers()
	notify(player, "Stocked " .. kind .. " — Q sells in DAY.")
	sound(player, "pick")
	sync(player)
end)

Remotes.get("Sell").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st or not st.stallIndex then
		return
	end
	if phase ~= "Day" then
		notify(player, "Buyers only in DAY.")
		return
	end
	if #st.display == 0 then
		notify(player, "Stock with F first.")
		return
	end
	local floor = stallFloor(st.stallIndex)
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp or not floor or (hrp.Position - floor.Position).Magnitude > 24 then
		notify(player, "Stand at YOUR stall to sell.")
		return
	end
	local kind = table.remove(st.display, 1)
	local gain = math.floor((Config.CrateValue[kind] or 8) * (1 + st.rebirths * 0.25))
	st.coins += gain
	refreshDisplay(st.stallIndex, st.display)
	refreshBuyers()
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
		notify(player, "Steal only after the bell (NIGHT).")
		return
	end
	if st.carried then
		notify(player, "Hands full.")
		return
	end
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local best, bestDist = nil, 18
	for _, other in ipairs(Players:GetPlayers()) do
		if other ~= player then
			local ost = states[other.UserId]
			if ost and ost.stallIndex and #ost.display > 0 then
				local floor = stallFloor(ost.stallIndex)
				if floor then
					local d = (hrp.Position - floor.Position).Magnitude
					if d < bestDist then
						bestDist = d
						best = other
					end
				end
			end
		end
	end
	if not best then
		notify(player, "Need another player's stocked stall nearby.")
		return
	end
	local ost = states[best.UserId]
	local kind = table.remove(ost.display, 1)
	st.carried = kind
	attachCarry(player, kind)
	refreshDisplay(ost.stallIndex, ost.display)
	refreshBuyers()
	notify(player, "Stole " .. kind .. " from " .. best.DisplayName)
	notify(best, player.DisplayName .. " robbed your stall!")
	sound(player, "pick")
	sync(player)
	sync(best)
end)

Remotes.get("Rebirth").OnServerEvent:Connect(function(player)
	local st = states[player.UserId]
	if not st then
		return
	end
	if st.coins < Config.RebirthCost then
		notify(player, "Need " .. Config.RebirthCost .. " coins. Sell more, then P at the bell.")
		return
	end
	st.coins = 0
	st.rebirths += 1
	st.display = {}
	st.carried = nil
	attachCarry(player, nil)
	if st.stallIndex then
		refreshDisplay(st.stallIndex, st.display)
	end
	refreshBuyers()
	notify(player, "Rebirth " .. st.rebirths .. " — payout x" .. string.format("%.2f", 1 + st.rebirths * 0.25))
	sync(player)
end)

local function onPlayer(p)
	if states[p.UserId] then
		return
	end
	states[p.UserId] = {
		coins = 0,
		rebirths = 0,
		carried = nil,
		display = {},
		stallIndex = nil,
	}
	assignStall(p)
	sync(p)
	local function hook(char)
		task.wait(0.15)
		local st = states[p.UserId]
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if hrp and st and st.stallIndex then
			local floor = stallFloor(st.stallIndex)
			if floor then
				hrp.CFrame = floor.CFrame + Vector3.new(0, 5, 0)
			end
		end
		notify(p, "DAY: E pier  F your stall  Q sell")
	end
	p.CharacterAdded:Connect(hook)
	if p.Character then
		task.spawn(hook, p.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in ipairs(Players:GetPlayers()) do
	onPlayer(p)
end
Players.PlayerRemoving:Connect(function(p)
	local st = states[p.UserId]
	if st and st.stallIndex then
		stallOwner[st.stallIndex] = nil
		setSign(stallFloor(st.stallIndex), "Empty stall")
		refreshDisplay(st.stallIndex, {})
		setBuyer(st.stallIndex, false)
	end
	states[p.UserId] = nil
end)

setPierVisual()
setNight(false)

task.spawn(function()
	while true do
		phase = "Day"
		setNight(false)
		refreshBuyers()
		Remotes.get("Phase"):FireAllClients("Day")
		for _, p in ipairs(Players:GetPlayers()) do
			notify(p, "DAY — E harvest, F stock, Q sell.")
			sync(p)
		end
		task.wait(Config.DaySeconds)

		phase = "Bell"
		Remotes.get("Phase"):FireAllClients("Bell")
		local bell = harbor and harbor:FindFirstChild("Bell")
		if bell and bell:IsA("BasePart") then
			local orig = bell.Color
			for _ = 1, 6 do
				bell.Color = Color3.fromRGB(255, 255, 140)
				task.wait(0.15)
				bell.Color = orig
				task.wait(0.15)
			end
		end
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "bell")
			notify(p, "THE BELL — night raid incoming.")
		end
		task.wait(Config.BellSeconds)

		phase = "Night"
		nightIndex += 1
		setNight(true)
		refreshBuyers()
		Remotes.get("Phase"):FireAllClients("Night")
		for _, p in ipairs(Players:GetPlayers()) do
			sound(p, "night")
			notify(p, "NIGHT — R at another stall to steal.")
			sync(p)
		end
		task.wait(Config.NightSeconds)
	end
end)

print("[Last Bell] Gameplay ready")
