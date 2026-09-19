--!strict
-- Last Bell — Loading Screen
-- Hides the empty pre-spawn view behind a black screen with the
-- game title until the server signals the harbor is built and this
-- player's character is about to load in.

local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 1000
gui.Parent = player:WaitForChild("PlayerGui")

local backdrop = Instance.new("Frame")
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.BackgroundColor3 = Color3.new(0, 0, 0)
backdrop.BorderSizePixel = 0
backdrop.Parent = gui

local title = Instance.new("TextLabel")
title.Size = UDim2.fromScale(0.8, 0.2)
title.Position = UDim2.fromScale(0.1, 0.4)
title.BackgroundTransparency = 1
title.Text = "LAST BELL"
title.TextColor3 = Color3.fromRGB(220, 190, 120)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = backdrop

local sub = Instance.new("TextLabel")
sub.Size = UDim2.fromScale(0.8, 0.08)
sub.Position = UDim2.fromScale(0.1, 0.6)
sub.BackgroundTransparency = 1
sub.Text = "the tide is coming in..."
sub.TextColor3 = Color3.fromRGB(140, 140, 150)
sub.Font = Enum.Font.Gotham
sub.TextScaled = true
sub.Parent = backdrop

local dismissed = false
local function dismiss()
	if dismissed then
		return
	end
	dismissed = true
	local tween = TweenService:Create(backdrop, TweenInfo.new(1.2), { BackgroundTransparency = 1 })
	local titleTween = TweenService:Create(title, TweenInfo.new(1.2), { TextTransparency = 1 })
	local subTween = TweenService:Create(sub, TweenInfo.new(1.2), { TextTransparency = 1 })
	tween:Play()
	titleTween:Play()
	subTween:Play()
	tween.Completed:Wait()
	gui:Destroy()
end

local worldReady = RS:WaitForChild("WorldReady", 15)
if worldReady and worldReady:IsA("RemoteEvent") then
	worldReady.OnClientEvent:Once(dismiss)
else
	-- fallback so nobody gets stuck on a black screen if the remote
	-- is missing for some reason
	task.delay(4, dismiss)
end
