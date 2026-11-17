-- Katakata Compound server: builds Eko Shore, starts each system, looks after players.
-- It owns Gist, inventory, pads, waves and Come-Ups.

local Players = game:GetService("Players")

local WorldBuilder = require(script.WorldBuilder)
local PlayerLedger = require(script.PlayerLedger)
local GistEconomy = require(script.GistEconomy)
local Collector = require(script.Collector)
local BaseYard = require(script.BaseYard)
local KatakataSpawner = require(script.KatakataSpawner)
local UpgradeShop = require(script.UpgradeShop)
local ComeUpRebirth = require(script.ComeUpRebirth)
local SnatchWave = require(script.SnatchWave)

-- Opens a ledger, hands over a compound, restores any saved yard.
local function welcomePlayer(player)
	PlayerLedger.openLedger(player)
	if not BaseYard.claimYard(player) then
		player:Kick("Every compound is taken. Try another server!")
		return
	end
	PlayerLedger.publishLedger(player)
	player.CharacterAdded:Connect(function()
		task.defer(Collector.refreshCarriedModel, player)
	end)
	PlayerLedger.loadSavedLedger(player)
	if PlayerLedger.getLedger(player) then
		BaseYard.renderYard(player)
		PlayerLedger.publishLedger(player)
		PlayerLedger.notify(player, "Welcome to Eko Shore! Bag a Katakata and stash it on your pads.")
	end
end

local function farewellPlayer(player)
	if BaseYard.plotOf(player) then
		PlayerLedger.saveLedger(player)
		BaseYard.releaseYard(player)
	end
	PlayerLedger.closeLedger(player)
end

local world = WorldBuilder.buildWorld()
BaseYard.setupYards(world.plots)
UpgradeShop.setupStations(world)
ComeUpRebirth.setupDrums(world.plots)
KatakataSpawner.startSpawning()
GistEconomy.startIncomeLoop()
SnatchWave.startWaveCycle()

Players.PlayerAdded:Connect(welcomePlayer)
Players.PlayerRemoving:Connect(farewellPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(welcomePlayer, player)
end
game:BindToClose(function()
	for _, player in ipairs(Players:GetPlayers()) do
		PlayerLedger.saveLedger(player)
	end
end)
