-- PlayerLedger: the one place player state lives: Gist, Come-Ups, Lane Pass, carried Katakata,
-- yard pads, pad locks, Gate Bars. Modules change a ledger; the client reads its attributes.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared").KatakataCatalog)

local PlayerLedger = {}

local ledgers = {} -- [Player] = ledger
local notifyRemote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Notify")

-- A newcomer's ledger. An entry is { id = creatureId, mutation = mutationId }.
function PlayerLedger.openLedger(player)
	ledgers[player] = { gist = Catalog.STARTING_GIST, comeUps = 0, lanePass = 1, gateBars = 0, carried = nil, pads = {}, lockedPads = {}, plotIndex = 0 }
	return ledgers[player]
end

function PlayerLedger.getLedger(player)
	return ledgers[player]
end

-- (hustle + every stashed Katakata) x Come-Up multiplier.
function PlayerLedger.gistPerSecond(ledger)
	local total = Catalog.HUSTLE_RATE
	for _, stashed in pairs(ledger.pads) do
		total += Catalog.gistRate(stashed.id, stashed.mutation)
	end
	return total * Catalog.comeUpMultiplier(ledger.comeUps)
end

function PlayerLedger.count(list)
	local count = 0
	for _ in pairs(list) do
		count += 1
	end
	return count
end

-- Copies the ledger onto the Player as attributes for the HUD.
function PlayerLedger.publishLedger(player)
	local ledger = ledgers[player]
	if not ledger then
		return
	end
	local carried = ledger.carried
	local published = {
		Gist = math.floor(ledger.gist),
		GistPerSecond = PlayerLedger.gistPerSecond(ledger),
		Multiplier = Catalog.comeUpMultiplier(ledger.comeUps),
		ComeUpCost = Catalog.comeUpCost(ledger.comeUps),
		LanePass = ledger.lanePass,
		NextLanePassCost = Catalog.nextLanePassCost(ledger.lanePass) or 0,
		GateBars = ledger.gateBars,
		PadLocks = PlayerLedger.count(ledger.lockedPads),
		StashedCount = PlayerLedger.count(ledger.pads),
		PlotIndex = ledger.plotIndex,
		CarriedName = carried and Catalog.displayName(carried.id, carried.mutation) or "",
		CarriedRate = carried and Catalog.gistRate(carried.id, carried.mutation) or 0,
	}
	for name, value in pairs(published) do
		player:SetAttribute(name, value)
	end
end

-- A HUD toast; tone is "good", "bad" or "info".
function PlayerLedger.notify(player, text, tone)
	notifyRemote:FireClient(player, text, tone or "info")
end

-- Restores a saved ledger when the experience has data stores.
function PlayerLedger.loadSavedLedger(player)
	local ok, saved = pcall(function()
		return DataStoreService:GetDataStore("KatakataLedgerV1"):GetAsync("player_" .. player.UserId)
	end)
	local ledger = ledgers[player]
	if not ledger then
		return
	end
	ledger.saveAllowed = ok
	if ok and type(saved) == "table" then
		ledger.gist = math.max(ledger.gist, tonumber(saved.gist) or 0)
		ledger.comeUps = tonumber(saved.comeUps) or 0
		ledger.lanePass = math.clamp(tonumber(saved.lanePass) or 1, 1, #Catalog.RARITIES)
		ledger.gateBars = tonumber(saved.gateBars) or 0
		for key, entry in pairs(type(saved.pads) == "table" and saved.pads or {}) do
			if Catalog.creatureById(entry.id) then
				ledger.pads[tonumber(key)] = { id = entry.id, mutation = entry.mutation }
				ledger.lockedPads[tonumber(key)] = entry.locked or nil
			end
		end
	end
end

function PlayerLedger.saveLedger(player)
	local ledger = ledgers[player]
	if not ledger or not ledger.saveAllowed then
		return
	end
	local pads = {}
	for padIndex, entry in pairs(ledger.pads) do
		pads[tostring(padIndex)] = { id = entry.id, mutation = entry.mutation, locked = ledger.lockedPads[padIndex] }
	end
	local carried = ledger.carried -- what is in hand is refunded
	local gist = ledger.gist + (carried and Catalog.bagPrice(carried.id, carried.mutation) or 0)
	local data = { gist = math.floor(gist), comeUps = ledger.comeUps, lanePass = ledger.lanePass, gateBars = ledger.gateBars, pads = pads }
	pcall(function()
		DataStoreService:GetDataStore("KatakataLedgerV1"):SetAsync("player_" .. player.UserId, data)
	end)
end

function PlayerLedger.closeLedger(player)
	ledgers[player] = nil
end

return PlayerLedger
