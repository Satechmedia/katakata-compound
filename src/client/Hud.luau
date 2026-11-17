-- Hud: the ScreenGui over the 3D world: title screen, Gist wallet, Snatch Wave timer, carried
-- Katakata, objective line, toasts and the Come-Up confirmation. It only shows what the server
-- publishes (Player and Workspace attributes). Nothing sits top-left, where Roblox's menu lives.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local MarketMap = require(Shared.MarketMap)
local Make = require(Shared.Make)

local Hud = {}

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local format, S = Catalog.formatGist, UDim2.fromScale
local GOLD, GREEN, RED, WHITE = Color3.fromRGB(255, 210, 70), Color3.fromRGB(110, 240, 130), Color3.fromRGB(255, 80, 60), Color3.new(1, 1, 1)
local gui, play, title, confirm, done
local text = {} -- the labels the refresh loop rewrites

-- Builds every panel once and starts the refresh loop.
function Hud.buildHud()
	gui = Make.new("ScreenGui", { Name = "KatakataHud", ResetOnSpawn = false, IgnoreGuiInset = true }, player:WaitForChild("PlayerGui"))
	play = Make.new("Frame", { Name = "PlayPanels", Size = S(1, 1), BackgroundTransparency = 1, Visible = false }, gui)

	local wallet = Hud.panel(play, "Wallet", GOLD, 1, 0, 0.985, 0.03, 0.27, 0.25)
	text.gist = Make.label(wallet, "Gist", "", GOLD, S(0.04, 0.03), S(0.92, 0.36))
	text.rate = Make.label(wallet, "GistPerSecond", "", GREEN, S(0.04, 0.39), S(0.92, 0.22))
	text.multiplier = Make.label(wallet, "ComeUpMultiplier", "", WHITE, S(0.04, 0.61), S(0.92, 0.18))
	text.defences = Make.label(wallet, "Defences", "", Color3.fromRGB(150, 215, 255), S(0.04, 0.79), S(0.92, 0.17))
	text.wavePanel = Hud.panel(play, "WaveTimer", RED, 0.5, 0, 0.5, 0.03, 0.36, 0.1)
	text.wave = Make.label(text.wavePanel, "WaveText", "", WHITE, S(0.03, 0.1), S(0.94, 0.8))
	text.toast = Make.label(play, "Toast", "", WHITE, S(0.2, 0.15), S(0.6, 0.06))
	text.objective = Make.label(Hud.panel(play, "Objective", WHITE, 0.5, 1, 0.5, 0.885, 0.62, 0.07), "ObjectiveText", "", WHITE, S(0.02, 0.12), S(0.96, 0.76))
	text.carried = Make.label(Hud.panel(play, "Carried", GOLD, 0.5, 1, 0.5, 0.975, 0.5, 0.08), "CarriedText", "", WHITE, S(0.02, 0.12), S(0.96, 0.76))
	Make.label(Hud.panel(play, "Controls", WHITE, 0, 1, 0.015, 0.975, 0.215, 0.08), "ControlsText", "WASD MOVE | SHIFT SPRINT | E BAG / STASH", WHITE, S(0.04, 0.1), S(0.92, 0.8))
	text.comeUp = Hud.button(play, "ComeUpButton", "COME-UP [R]", 1, 1, 0.985, 0.975, 0.215, 0.11, Hud.openComeUpConfirm)

	-- Start screen: the name over the live 3D market; Enter or a click starts.
	title = Make.new("Frame", { Name = "TitleScreen", Size = S(1, 1), BackgroundColor3 = Color3.fromRGB(24, 12, 32), BackgroundTransparency = 0.35 }, gui)
	Make.label(title, "Title", "KATAKATA COMPOUND", GOLD, S(0.1, 0.17), S(0.8, 0.19))
	Make.label(title, "Subtitle", "THE LOUDEST STREET MARKET IN EKO SHORE", Color3.fromRGB(255, 150, 90), S(0.2, 0.36), S(0.6, 0.06))
	Make.label(title, "Step1", "1. BAG ABSURD KATAKATAS IN THE MARKET LANES  [E]", WHITE, S(0.15, 0.47), S(0.7, 0.055))
	Make.label(title, "Step2", "2. STASH THEM ON YOUR YARD PADS: GIST EVERY SECOND", WHITE, S(0.15, 0.535), S(0.7, 0.055))
	Make.label(title, "Step3", "3. BE HOME BEFORE THE SNATCH WAVE, THEN COME-UP", WHITE, S(0.15, 0.6), S(0.7, 0.055))
	Hud.button(title, "PlayButton", "PLAY  [ENTER]", 0.5, 0, 0.5, 0.72, 0.3, 0.12, Hud.startPlaying)

	-- Come-Up confirmation, and the rebirth screen shown once the server has done it.
	confirm = Hud.panel(gui, "ComeUpConfirm", GOLD, 0.5, 0.5, 0.5, 0.5, 0.5, 0.44)
	Make.label(confirm, "Heading", "COME-UP?", GOLD, S(0.05, 0.05), S(0.9, 0.24))
	Make.label(confirm, "Body", "", WHITE, S(0.05, 0.31), S(0.9, 0.34))
	Hud.button(confirm, "YesButton", "YES, COME-UP!", 0, 1, 0.06, 0.94, 0.42, 0.22, function()
		confirm.Visible = false
		remotes.RequestComeUp:FireServer()
	end)
	Hud.button(confirm, "NoButton", "NOT YET", 1, 1, 0.94, 0.94, 0.42, 0.22, function()
		confirm.Visible = false
	end)
	done = Hud.panel(gui, "ComeUpDone", GOLD, 0.5, 0.5, 0.5, 0.5, 0.56, 0.46)
	Make.label(done, "Heading", "YOU CAME UP!", GOLD, S(0.05, 0.05), S(0.9, 0.28))
	Make.label(done, "Body", "", WHITE, S(0.05, 0.35), S(0.9, 0.32))
	Hud.button(done, "BackButton", "BACK TO THE HUSTLE", 0.5, 1, 0.5, 0.94, 0.5, 0.2, function()
		done.Visible = false
	end)
	confirm.Visible, done.Visible = false, false

	remotes:WaitForChild("Notify").OnClientEvent:Connect(Hud.showToast)
	remotes:WaitForChild("ComeUpEvent").OnClientEvent:Connect(function(stage, multiplier)
		if stage == "Done" then
			Hud.showComeUpDone(multiplier)
		else
			Hud.openComeUpConfirm()
		end
	end)
	-- ContextActionService, so Roblox's camera scripts cannot swallow the keys.
	ContextActionService:BindAction("KatakataKeys", function(_, state, input)
		if state == Enum.UserInputState.Begin then
			if input.KeyCode == Enum.KeyCode.R then
				Hud.openComeUpConfirm()
			else
				Hud.startPlaying()
			end
		end
		return Enum.ContextActionResult.Pass
	end, false, Enum.KeyCode.R, Enum.KeyCode.Return, Enum.KeyCode.KeypadEnter)

	task.spawn(function()
		while true do
			Hud.refreshWallet()
			Hud.refreshWaveTimer()
			Hud.refreshObjective()
			task.wait(0.15)
		end
	end)
end

function Hud.startPlaying()
	title.Visible = false
	play.Visible = true
end

-- Gist, Gist per second, Come-Up multiplier, Lane Pass, defences and the carried Katakata.
function Hud.refreshWallet()
	local gist, cost = player:GetAttribute("Gist") or 0, player:GetAttribute("ComeUpCost") or 0
	local carried = player:GetAttribute("CarriedName") or ""
	text.gist.Text = format(gist) .. " GIST"
	text.rate.Text = "+" .. format(player:GetAttribute("GistPerSecond") or 0) .. " GIST/SEC"
	text.multiplier.Text = "COME-UP x" .. (player:GetAttribute("Multiplier") or 1) .. "  |  " .. string.upper(Catalog.RARITIES[player:GetAttribute("LanePass") or 1].id) .. " PASS"
	text.defences.Text = "PAD LOCKS " .. (player:GetAttribute("PadLocks") or 0) .. "  |  GATE BARS " .. (player:GetAttribute("GateBars") or 0)
	text.comeUp.Text = "COME-UP [R]\n" .. format(cost) .. " GIST"
	text.comeUp.BackgroundColor3 = gist >= cost and Color3.fromRGB(255, 112, 67) or Color3.fromRGB(90, 70, 80)
	text.carried.Text = carried == "" and "HANDS EMPTY" or "CARRYING: " .. string.upper(carried) .. "  (+" .. format(player:GetAttribute("CarriedRate") or 0) .. "/S)"
	text.carried.TextColor3 = carried == "" and WHITE or GOLD
end

-- Counts down to the next Snatch Wave; flashes red when it is close or sweeping.
function Hud.refreshWaveTimer()
	local sweeping = workspace:GetAttribute("WaveState") == "Sweeping"
	local seconds = workspace:GetAttribute("WaveSecondsLeft") or 0
	local urgent = sweeping or seconds <= 10
	text.wave.Text = sweeping and "SNATCH WAVE! GET BEHIND YOUR GATE!" or string.format("SNATCH WAVE IN %d:%02d", seconds // 60, seconds % 60)
	text.wave.TextColor3 = urgent and GOLD or WHITE
	text.wavePanel.BackgroundColor3 = urgent and os.clock() * 3 % 1 < 0.5 and Color3.fromRGB(170, 20, 20) or Color3.fromRGB(24, 12, 32)
end

-- One short line that always says what to do next.
function Hud.refreshObjective()
	local gist = player:GetAttribute("Gist") or 0
	local carrying = (player:GetAttribute("CarriedName") or "") ~= ""
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local outside = rootPart and not MarketMap.isInsideCompound(rootPart.Position)
	local nextPass = player:GetAttribute("NextLanePassCost") or 0
	local goal = "BAG RARER KATAKATAS TO GROW YOUR GIST/SEC"
	if outside and workspace:GetAttribute("WaveState") == "Sweeping" then
		goal = carrying and "RUN! GET YOUR KATAKATA THROUGH THE GATE!" or "WAVE! GET HOME TO GUARD YOUR YARD!"
	elseif carrying then
		goal = outside and "CARRY IT HOME AND STASH IT ON A PAD [E]" or "STASH IT ON A YARD PAD [E]"
	elseif gist >= (player:GetAttribute("ComeUpCost") or math.huge) then
		goal = "YOU CAN COME-UP! PRESS [R] FOR A PERMANENT MULTIPLIER"
	elseif nextPass > 0 and gist >= nextPass then
		goal = "BUY THE NEXT LANE PASS AT THE BOARD IN YOUR YARD"
	elseif (player:GetAttribute("StashedCount") or 0) == 0 then
		goal = "GO THROUGH YOUR GATE AND BAG A KATAKATA [E]"
	end
	text.objective.Text = "GOAL: " .. goal
end

-- The latest server message, under the wave timer, for a few seconds.
function Hud.showToast(message, tone)
	text.toast.Text = string.upper(message)
	text.toast.TextColor3 = tone == "good" and GREEN or tone == "bad" and RED or WHITE
	task.delay(4.5, function()
		if text.toast.Text == string.upper(message) then
			text.toast.Text = ""
		end
	end)
end

-- "COME-UP?" with the real price and reward; YES asks the server, which checks again.
function Hud.openComeUpConfirm()
	local gist, cost = player:GetAttribute("Gist") or 0, player:GetAttribute("ComeUpCost") or 0
	if play.Visible and not done.Visible then
		confirm.Body.Text = gist >= cost and "SPEND " .. format(cost) .. " GIST. PADS, LOCKS AND LANE PASS RESET.\nYOU KEEP x" .. (player:GetAttribute("Multiplier") + 1) .. " GIST FOREVER."
			or "A COME-UP COSTS " .. format(cost) .. " GIST.\nYOU HAVE " .. format(gist) .. ". KEEP STACKING!"
		confirm.YesButton.Visible = gist >= cost
		confirm.Visible = true
	end
end

function Hud.showComeUpDone(multiplier)
	confirm.Visible = false
	done.Body.Text = "ALL YOUR GIST IS NOW x" .. multiplier .. " FOREVER.\nFRESH YARD. SAME HUSTLE. GO AGAIN!"
	done.Visible = true
end

-- A dark outlined panel placed by anchor, position and size, all in screen scale.
function Hud.panel(parent, name, strokeColor, anchorX, anchorY, x, y, width, height)
	return Make.panel(parent, name, strokeColor, { AnchorPoint = Vector2.new(anchorX, anchorY), Position = S(x, y), Size = S(width, height) })
end

function Hud.button(parent, name, label, anchorX, anchorY, x, y, width, height, onActivated)
	local button = Make.new("TextButton", {
		Name = name,
		Text = label,
		AnchorPoint = Vector2.new(anchorX, anchorY),
		Position = S(x, y),
		Size = S(width, height),
		BackgroundColor3 = Color3.fromRGB(60, 190, 90),
		Font = Enum.Font.GothamBlack,
		TextColor3 = WHITE,
		TextScaled = true,
		TextStrokeTransparency = 0,
	}, parent)
	Make.new("UICorner", { CornerRadius = UDim.new(0, 12) }, button)
	button.Activated:Connect(onActivated)
	return button
end

return Hud
