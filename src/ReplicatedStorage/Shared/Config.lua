--!strict
local Config = {}
Config.MaxStalls = 20
Config.RingRadius = 70
Config.DaySeconds = 50
Config.NightSeconds = 40
Config.BellSeconds = 4
Config.StartingCoins = 0
Config.RebirthCost = 500
Config.GrowSeconds = 6
Config.PierMaxCrates = 6
Config.MaxDisplay = 4
Config.CrateValue = { Wood = 8, Spice = 20, Silk = 45, Relic = 120 }
Config.CrateWeight = { Wood = 50, Spice = 30, Silk = 15, Relic = 5 }
Config.CrateColor = {
	Wood = Color3.fromRGB(160, 110, 60),
	Spice = Color3.fromRGB(220, 90, 50),
	Silk = Color3.fromRGB(180, 140, 255),
	Relic = Color3.fromRGB(255, 210, 70),
}
Config.Sounds = {
	pick = "rbxasset://sounds/electronicpingshort.wav",
	sell = "rbxasset://sounds/switch.wav",
	bell = "rbxasset://sounds/action_get_up.mp3",
	night = "rbxasset://sounds/action_falling.mp3",
}
-- Create these in Creator Dashboard, then paste IDs. 0 = disabled.
Config.Gamepasses = { DoubleCoins = 0, ExtraSlot = 0, FastGrow = 0 }
return Config
