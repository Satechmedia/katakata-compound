-- Collector: bagging a Katakata and carrying it. A player holds at most one; it rides above
-- their head until it is stashed, sold or snatched.

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local KatakataModel = require(Shared.KatakataModel)
local Make = require(Shared.Make)
local PlayerLedger = require(script.Parent.PlayerLedger)
local GistEconomy = require(script.Parent.GistEconomy)

local Collector = {}

-- Buys a roaming creature; true when it is now in hand.
function Collector.bagCreature(player, creatureId, mutationId)
	local ledger = PlayerLedger.getLedger(player)
	local creature = Catalog.creatureById(creatureId)
	local price = Catalog.bagPrice(creatureId, mutationId)
	if not ledger then
		return false
	elseif ledger.carried then
		PlayerLedger.notify(player, "Hands full! Stash what you carry first.", "bad")
	elseif creature.tier > ledger.lanePass then
		PlayerLedger.notify(player, "You need the " .. Catalog.RARITIES[creature.tier].id .. " Lane Pass (yard board).", "bad")
	elseif not GistEconomy.trySpendGist(player, price) then
		PlayerLedger.notify(player, creature.name .. " costs " .. Catalog.formatGist(price) .. " Gist.", "bad")
	else
		Collector.carryCreature(player, { id = creatureId, mutation = mutationId })
		PlayerLedger.notify(player, "Bagged " .. Catalog.displayName(creatureId, mutationId) .. "! Run it home.", "good")
		return true
	end
	return false
end

-- Puts an entry in the player's hands (nil empties them).
function Collector.carryCreature(player, entry)
	local ledger = PlayerLedger.getLedger(player)
	if ledger then
		ledger.carried = entry
		Collector.refreshCarriedModel(player)
		PlayerLedger.publishLedger(player)
	end
end

-- Empties the player's hands; returns what they held.
function Collector.takeCarried(player)
	local ledger = PlayerLedger.getLedger(player)
	local entry = ledger and ledger.carried
	if entry then
		Collector.carryCreature(player, nil)
	end
	return entry
end

-- The Snatch Wave got them: the carried Katakata is gone.
function Collector.loseCarriedToSnatchers(player)
	local entry = Collector.takeCarried(player)
	if entry then
		PlayerLedger.notify(player, "SNATCHED! The wave took " .. Catalog.displayName(entry.id, entry.mutation) .. ".", "bad")
	end
end

-- Bulk Buyer: sells the carried Katakata for half price.
function Collector.sellCarried(player)
	local entry = Collector.takeCarried(player)
	if entry then
		local value = Catalog.sellValue(entry.id, entry.mutation)
		GistEconomy.earnGist(player, value)
		PlayerLedger.notify(player, "Sold " .. Catalog.displayName(entry.id, entry.mutation) .. " for " .. Catalog.formatGist(value) .. " Gist.", "good")
	else
		PlayerLedger.notify(player, "Carry a Katakata here to sell.")
	end
end

-- Rebuilds the model above the character to match the ledger.
function Collector.refreshCarriedModel(player)
	local character = player.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local old = character and character:FindFirstChild("CarriedKatakata")
	if old then
		old:Destroy()
	end
	local carried = PlayerLedger.getLedger(player) and PlayerLedger.getLedger(player).carried
	if carried and rootPart then
		local model = KatakataModel.buildKatakata(carried.id, carried.mutation, 0.55)
		model.Name = "CarriedKatakata"
		KatakataModel.attachLabel(model, carried.id, carried.mutation, "CARRIED").Size = UDim2.fromScale(9.5, 3.9)
		model.PrimaryPart.Anchored = false
		model:PivotTo(rootPart.CFrame * CFrame.new(0, 4.2 + model:GetAttribute("GroundOffset"), 0))
		Make.new("WeldConstraint", { Part0 = rootPart, Part1 = model.PrimaryPart }, model.PrimaryPart)
		model.Parent = character
	end
end

return Collector
