-- UpgradeShop: what Gist buys at the 3D stations: Lane Pass (next rarity tier), Pad Lock and
-- Gate Bar (defences), the Pepper Pot (re-roll a mutation) and the Bulk Buyer (sell).

local Catalog = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared").KatakataCatalog)
local PlayerLedger = require(script.Parent.PlayerLedger)
local GistEconomy = require(script.Parent.GistEconomy)
local Collector = require(script.Parent.Collector)
local BaseYard = require(script.Parent.BaseYard)

local UpgradeShop = {}

-- Charges the player or names the price; true when paid.
function UpgradeShop.charge(player, cost, itemName)
	local paid = GistEconomy.trySpendGist(player, cost)
	if not paid then
		PlayerLedger.notify(player, itemName .. " costs " .. Catalog.formatGist(cost) .. " Gist.", "bad")
	end
	return paid
end

-- Next-tier unlock: bag the next rarity up the ladder.
function UpgradeShop.buyLanePass(player)
	local ledger = PlayerLedger.getLedger(player)
	local rarity = Catalog.RARITIES[ledger.lanePass + 1]
	if not rarity then
		PlayerLedger.notify(player, "Every lane is open. Go hunt a Mythic!")
	elseif UpgradeShop.charge(player, rarity.passCost, "The " .. rarity.id .. " Lane Pass") then
		ledger.lanePass += 1
		PlayerLedger.notify(player, rarity.id .. " Lane unlocked! Rarer Katakatas roam deeper.", "good")
	end
end

-- Pad defence: a locked pad cannot be raided.
function UpgradeShop.buyPadLock(player)
	local locks = PlayerLedger.count(PlayerLedger.getLedger(player).lockedPads)
	if locks >= #BaseYard.plotOf(player).pads then
		PlayerLedger.notify(player, "Every pad is already locked.")
	elseif UpgradeShop.charge(player, Catalog.padLockCost(locks), "A Pad Lock") then
		PlayerLedger.notify(player, "Pad " .. BaseYard.lockNextPad(player) .. " locked against snatchers.", "good")
	end
end

-- Gate defence: one Gate Bar blocks one yard raid.
function UpgradeShop.buyGateBar(player)
	local ledger = PlayerLedger.getLedger(player)
	if UpgradeShop.charge(player, Catalog.gateBarCost(ledger.lanePass), "A Gate Bar") then
		ledger.gateBars += 1
		PlayerLedger.notify(player, "Gate Bar ready (" .. ledger.gateBars .. "): blocks the next yard raid.", "good")
	end
end

-- Mutation upgrade: pay to re-roll the carried Katakata; only a better roll sticks.
function UpgradeShop.rerollMutation(player)
	local ledger = PlayerLedger.getLedger(player)
	local carried = ledger and ledger.carried
	if not carried then
		PlayerLedger.notify(player, "Carry a Katakata here to re-roll its mutation.")
	elseif UpgradeShop.charge(player, Catalog.rerollCost(carried.id), "A dip in the Pepper Pot") then
		local rolled = Catalog.mutationById(Catalog.rollMutation(2 + ledger.comeUps))
		if rolled.multiplier > Catalog.mutationById(carried.mutation).multiplier then
			Collector.carryCreature(player, { id = carried.id, mutation = rolled.id })
			PlayerLedger.notify(player, "MUTATION! It came out " .. rolled.id .. ": x" .. rolled.multiplier .. " Gist.", "good")
		else
			PlayerLedger.notify(player, "Nothing better this time. Dip again!")
		end
	end
end

-- Connects every station prompt; yard stations only answer their owner.
function UpgradeShop.setupStations(world)
	for _, plot in ipairs(world.plots) do
		for key, buy in pairs({ lanePass = UpgradeShop.buyLanePass, padLock = UpgradeShop.buyPadLock, gateBar = UpgradeShop.buyGateBar }) do
			plot.stations[key].StationPrompt.Triggered:Connect(function(player)
				if plot.owner == player then
					buy(player)
					PlayerLedger.publishLedger(player)
					BaseYard.refreshYardSigns(player)
				else
					PlayerLedger.notify(player, "Not your compound.", "bad")
				end
			end)
		end
	end
	for _, pot in ipairs(world.pepperPots) do
		pot.StationSign.Plate.Detail.Text = "RE-ROLL A MUTATION"
		pot.StationPrompt.ActionText = "Dip carried Katakata"
		pot.StationPrompt.Triggered:Connect(UpgradeShop.rerollMutation)
	end
	for _, buyer in ipairs(world.bulkBuyers) do
		buyer.StationSign.Plate.Detail.Text = "SELLS YOURS FOR 50%"
		buyer.StationPrompt.ActionText = "Sell carried Katakata"
		buyer.StationPrompt.Triggered:Connect(Collector.sellCarried)
	end
end

return UpgradeShop
