-- SnatchWave: the threat. A dust wall of snatchers sweeps the market to the compound wall.
-- Anyone it overtakes outside a gate loses the Katakata in hand; when it lands, players still
-- outside have an unlocked pad raided unless a Gate Bar holds; players at home earn a bonus.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local MarketMap = require(Shared.MarketMap)
local Make = require(Shared.Make)
local PlayerLedger = require(script.Parent.PlayerLedger)
local GistEconomy = require(script.Parent.GistEconomy)
local Collector = require(script.Parent.Collector)
local BaseYard = require(script.Parent.BaseYard)
local KatakataSpawner = require(script.Parent.KatakataSpawner)

local SnatchWave = {}

local CALM_SECONDS = 75
local WAVE_SPEED = 23 -- a sprinting player (28) just outruns it
local BONUS_SECONDS = 15 -- of income for a defended yard

-- One wave from the far wall to the compound wall, snatching as it goes.
function SnatchWave.startSnatchWave()
	local wall = SnatchWave.buildDustWall()
	local frontZ = MarketMap.WAVE_START_Z
	workspace:SetAttribute("WaveState", "Sweeping")
	while frontZ < MarketMap.WAVE_STOP_Z do
		frontZ = math.min(MarketMap.WAVE_STOP_Z, frontZ + WAVE_SPEED * RunService.Heartbeat:Wait())
		wall:PivotTo(CFrame.new(0, 0, frontZ))
		workspace:SetAttribute("WaveFrontZ", math.floor(frontZ / 2) * 2)
		for _, player in ipairs(Players:GetPlayers()) do
			SnatchWave.snatchIfCaught(player, frontZ)
		end
	end
	SnatchWave.raidUnguardedYards()
	KatakataSpawner.reshuffleMarket()
	workspace:SetAttribute("WaveState", "Calm")
	wall:Destroy()
end

-- Overtaken outside the gate: the Katakata in hand is gone.
function SnatchWave.snatchIfCaught(player, frontZ)
	local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if rootPart and rootPart.Position.Z < frontZ + 2 and not MarketMap.isInsideCompound(rootPart.Position) then
		Collector.loseCarriedToSnatchers(player)
	end
end

-- The wave lands. Home: bonus. Still out: a snatcher goes for your yard.
function SnatchWave.raidUnguardedYards()
	for _, player in ipairs(Players:GetPlayers()) do
		local ledger = PlayerLedger.getLedger(player)
		local rootPart = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not ledger or not rootPart then
			continue
		end
		if MarketMap.isInsideCompound(rootPart.Position) then
			local bonus = PlayerLedger.gistPerSecond(ledger) * BONUS_SECONDS
			GistEconomy.earnGist(player, bonus)
			PlayerLedger.notify(player, "Yard defended! +" .. Catalog.formatGist(bonus) .. " Gist bonus.", "good")
		elseif ledger.gateBars > 0 and next(ledger.pads) then
			ledger.gateBars -= 1
			BaseYard.refreshYardSigns(player)
			PlayerLedger.publishLedger(player)
			PlayerLedger.notify(player, "Your Gate Bar held! Snatchers bounced off.", "good")
		else
			local taken = BaseYard.snatchFromUnlockedPad(player)
			if taken then
				PlayerLedger.notify(player, "RAIDED! Snatchers took " .. Catalog.displayName(taken.id, taken.mutation) .. " from an unlocked pad.", "bad")
			end
		end
	end
end

-- The hazard: a wall of dust with a snatcher charging down every lane.
function SnatchWave.buildDustWall()
	local wall = Make.new("Model", { Name = "SnatchWave", WorldPivot = CFrame.new() }, nil)
	local width = MarketMap.HALF_WIDTH * 2 + 14
	local function piece(name, size, x, y, z, hex, material, transparency)
		local part = Make.part(wall, name, size, Vector3.new(x, y, z), hex, material)
		part.Transparency = transparency or 0
		part.CanCollide, part.CanQuery, part.CastShadow = false, false, false
		return part
	end
	piece("DustFront", Vector3.new(width, 44, 6), 0, 22, 0, "D6AA6E", "Sand", 0.35)
	piece("DustCore", Vector3.new(width, 56, 10), 0, 28, -9, "96693C", "Sand", 0.2)
	piece("DustGlow", Vector3.new(width, 3, 1), 0, 1.6, 3.4, "FF5A28", "Neon")
	for lane = 1, MarketMap.PLOT_COUNT do
		local x = MarketMap.plotCenterX(lane)
		local body = piece("SnatcherBody", Vector3.new(3, 6.6, 2), x, 3.3, 6, "46141E")
		local head = piece("SnatcherHead", Vector3.new(2.6, 2.6, 2.6), x, 8, 6, "1E1E23")
		head.Shape = Enum.PartType.Ball
		piece("SnatcherEyes", Vector3.new(1.8, 0.5, 0.4), x, 8.2, 7.2, "FF3C28", "Neon")
		piece("SnatcherArms", Vector3.new(5.2, 1, 4), x, 6.4, 7.5, "46141E")
		piece("SnatcherSack", Vector3.new(3.4, 3.4, 3.4), x, 4.5, 3.6, "A07846").Shape = Enum.PartType.Ball
		Make.new("Smoke", { Color = Color3.fromRGB(220, 180, 120), Opacity = 0.35, Size = 18, RiseVelocity = 6 }, body)
		local tag = Make.billboard(head, "SnatcherTag", 16, 3.4, 9, 220)
		tag.AlwaysOnTop = true
		Make.label(tag, "TagText", "SNATCH WAVE!", Color3.fromRGB(255, 70, 50))
	end
	wall:PivotTo(CFrame.new(0, 0, MarketMap.WAVE_START_Z))
	wall.Parent = workspace
	return wall
end

-- The cycle the HUD timer counts: calm seconds tick down, then a wave runs.
function SnatchWave.startWaveCycle()
	workspace:SetAttribute("WaveState", "Calm")
	task.spawn(function()
		while true do
			for secondsLeft = CALM_SECONDS, 1, -1 do
				workspace:SetAttribute("WaveSecondsLeft", secondsLeft)
				task.wait(1)
			end
			SnatchWave.startSnatchWave()
		end
	end)
end

return SnatchWave
