-- BaseYard: each player's compound yard. Claims a plot, stashes the carried Katakata on a pad
-- (where it earns Gist every second), swaps it, locks pads and keeps pads and signs in step.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local KatakataModel = require(Shared.KatakataModel)
local Make = require(Shared.Make)
local PlayerLedger = require(script.Parent.PlayerLedger)
local Collector = require(script.Parent.Collector)

local BaseYard = {}

local plots = {} -- from WorldBuilder.buildCompound
local CLAIM_ORDER = { 3, 4, 2, 5, 1, 6 } -- middle first

-- The pad prompt: stash what you carry, swap it, or pick a stashed one back up.
function BaseYard.placeOnPad(player, padIndex)
	local ledger = PlayerLedger.getLedger(player)
	local stashed, carried = ledger.pads[padIndex], ledger.carried
	if not carried and not stashed then
		PlayerLedger.notify(player, "Empty pad. Bring a Katakata from the market.")
		return
	end
	ledger.pads[padIndex] = carried
	Collector.carryCreature(player, stashed)
	BaseYard.renderPad(player, padIndex)
	PlayerLedger.publishLedger(player)
	if carried then
		local rate = Catalog.gistRate(carried.id, carried.mutation) * Catalog.comeUpMultiplier(ledger.comeUps)
		PlayerLedger.notify(player, Catalog.displayName(carried.id, carried.mutation) .. " stashed: +" .. Catalog.formatGist(rate) .. " Gist/s", "good")
	end
end

-- Gives the player a free compound and spawn; nil when all are taken.
function BaseYard.claimYard(player)
	for _, plotIndex in ipairs(CLAIM_ORDER) do
		local plot = plots[plotIndex]
		if not plot.owner then
			plot.owner = player
			PlayerLedger.getLedger(player).plotIndex = plotIndex
			player.RespawnLocation = plot.spawn
			return plot
		end
	end
	return nil
end

function BaseYard.plotOf(player)
	local ledger = PlayerLedger.getLedger(player)
	return ledger and plots[ledger.plotIndex]
end

-- The owner left: empty pads, VACANT sign.
function BaseYard.releaseYard(player)
	local plot = BaseYard.plotOf(player)
	local ledger = PlayerLedger.getLedger(player)
	if plot then
		ledger.pads, ledger.lockedPads = {}, {}
		BaseYard.renderYard(player)
		plot.owner = nil
		for _, label in ipairs(plot.signs) do
			label.Text = "VACANT COMPOUND"
		end
	end
end

-- Locks an unlocked pad, a stashed one first; returns its index.
function BaseYard.lockNextPad(player)
	local ledger = PlayerLedger.getLedger(player)
	local choice = nil
	for padIndex = #BaseYard.plotOf(player).pads, 1, -1 do
		if not ledger.lockedPads[padIndex] and (ledger.pads[padIndex] or not (choice and ledger.pads[choice])) then
			choice = padIndex
		end
	end
	if choice then
		ledger.lockedPads[choice] = true
		BaseYard.renderPad(player, choice)
	end
	return choice
end

-- A snatcher raid: one Katakata on an unlocked pad is taken and returned (or nil).
function BaseYard.snatchFromUnlockedPad(player)
	local ledger = PlayerLedger.getLedger(player)
	local exposed = {}
	for padIndex in pairs(ledger.pads) do
		if not ledger.lockedPads[padIndex] then
			table.insert(exposed, padIndex)
		end
	end
	local padIndex = exposed[math.random(math.max(1, #exposed))]
	local entry = ledger.pads[padIndex]
	if entry then
		ledger.pads[padIndex] = nil
		BaseYard.renderPad(player, padIndex)
		PlayerLedger.publishLedger(player)
	end
	return entry
end

-- Come-Up: pads and locks are wiped.
function BaseYard.clearYard(player)
	local ledger = PlayerLedger.getLedger(player)
	ledger.pads, ledger.lockedPads = {}, {}
	BaseYard.renderYard(player)
end

function BaseYard.renderYard(player)
	for padIndex in ipairs(BaseYard.plotOf(player).pads) do
		BaseYard.renderPad(player, padIndex)
	end
	BaseYard.refreshYardSigns(player)
end

-- Rebuilds one pad from the ledger: creature, label, colour, plate, prompt.
function BaseYard.renderPad(player, padIndex)
	local ledger = PlayerLedger.getLedger(player)
	local plot = BaseYard.plotOf(player)
	local pad, stashed, locked = plot.pads[padIndex], ledger.pads[padIndex], ledger.lockedPads[padIndex]
	if plot.stashedModels[padIndex] then
		plot.stashedModels[padIndex]:Destroy()
		plot.stashedModels[padIndex] = nil
	end
	pad.Color = stashed and Catalog.RARITIES[Catalog.creatureById(stashed.id).tier].color:Lerp(Color3.new(), 0.35) or Color3.fromHex("3B4252")
	pad.PadTrim.Color = locked and Color3.fromRGB(90, 200, 255) or Color3.fromRGB(255, 213, 79)
	pad.PadPrompt.ActionText = stashed and "Pick up / Swap" or "Stash Katakata"
	plot.padLabels[padIndex].Text = stashed and "" or "PAD " .. padIndex .. (locked and " - LOCKED" or " - EMPTY")
	pad:SetAttribute("StashedRate", stashed and Catalog.gistRate(stashed.id, stashed.mutation) * Catalog.comeUpMultiplier(ledger.comeUps) or 0)
	if stashed then
		local model = KatakataModel.buildKatakata(stashed.id, stashed.mutation, 0.85)
		KatakataModel.attachLabel(model, stashed.id, stashed.mutation, locked and "LOCKED" or nil)
		model:PivotTo(CFrame.new(pad.Position + Vector3.new(0, 0.4 + model:GetAttribute("GroundOffset"), 0)) * CFrame.Angles(0, math.pi, 0))
		model.Parent = plot.model
		plot.stashedModels[padIndex] = model
	end
end

-- Gate sign and station signs: owner's name and current prices.
function BaseYard.refreshYardSigns(player)
	local ledger = PlayerLedger.getLedger(player)
	local plot = BaseYard.plotOf(player)
	local format, nextRarity = Catalog.formatGist, Catalog.RARITIES[ledger.lanePass + 1]
	local locks = PlayerLedger.count(ledger.lockedPads)
	local details = {
		lanePass = nextRarity and string.upper(nextRarity.id) .. " PASS: " .. format(nextRarity.passCost) .. " GIST" or "ALL LANES OPEN",
		padLock = locks < #plot.pads and "LOCK A PAD: " .. format(Catalog.padLockCost(locks)) .. " GIST" or "ALL PADS LOCKED",
		gateBar = "HAVE " .. ledger.gateBars .. "  |  +1: " .. format(Catalog.gateBarCost(ledger.lanePass)) .. " GIST",
		comeUp = "x" .. Catalog.comeUpMultiplier(ledger.comeUps + 1) .. " GIST: " .. format(Catalog.comeUpCost(ledger.comeUps)),
	}
	for key, text in pairs(details) do
		plot.stations[key].StationSign.Plate.Detail.Text = text
	end
	for _, label in ipairs(plot.signs) do
		label.Text = string.upper(player.DisplayName) .. "'S COMPOUND"
	end
end

-- A ProximityPrompt on every pad; only its owner's press counts.
function BaseYard.setupYards(worldPlots)
	plots = worldPlots
	for _, plot in ipairs(plots) do
		for padIndex, pad in ipairs(plot.pads) do
			local prompt = Make.new("ProximityPrompt", { Name = "PadPrompt", ObjectText = "Pad " .. padIndex, ActionText = "Stash Katakata", MaxActivationDistance = 8, RequiresLineOfSight = false }, pad)
			prompt.Triggered:Connect(function(player)
				if plot.owner == player then
					BaseYard.placeOnPad(player, padIndex)
				else
					PlayerLedger.notify(player, "Not your compound.", "bad")
				end
			end)
		end
	end
end

return BaseYard
