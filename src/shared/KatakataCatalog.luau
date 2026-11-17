-- KatakataCatalog: the cast and every price: six rarities, five mutations, sixteen Katakatas.

local Catalog = {}

Catalog.STARTING_GIST = 20
Catalog.HUSTLE_RATE = 1 -- everybody earns this, so nobody is stuck broke

-- The ladder: the index is the tier, and the Lane Pass needed to bag that rarity.
Catalog.RARITIES = {
	{ id = "Common", color = Color3.fromRGB(240, 240, 240), passCost = 0, scale = 0.8 },
	{ id = "Uncommon", color = Color3.fromRGB(110, 230, 120), passCost = 150, scale = 0.9 },
	{ id = "Rare", color = Color3.fromRGB(90, 170, 255), passCost = 2000, scale = 1 },
	{ id = "Epic", color = Color3.fromRGB(200, 120, 255), passCost = 15000, scale = 1.15 },
	{ id = "Legendary", color = Color3.fromRGB(255, 190, 60), passCost = 120000, scale = 1.35 },
	{ id = "Mythic", color = Color3.fromRGB(255, 80, 110), passCost = 1000000, scale = 1.6 },
}

-- Mutations multiply Gist per second; weight is the chance.
Catalog.MUTATIONS = {
	{ id = "None", multiplier = 1, weight = 70, color = Color3.fromRGB(255, 255, 255) },
	{ id = "Gold", multiplier = 2, weight = 14, color = Color3.fromRGB(255, 205, 50) },
	{ id = "Spicy", multiplier = 3, weight = 9, color = Color3.fromRGB(255, 80, 40) },
	{ id = "Neon", multiplier = 5, weight = 5, color = Color3.fromRGB(60, 255, 170) },
	{ id = "Rainbow", multiplier = 10, weight = 2, color = Color3.fromRGB(255, 120, 255) },
}

Catalog.CREATURES = {}
local creatures, mutations = {}, {}
for _, mutation in ipairs(Catalog.MUTATIONS) do
	mutations[mutation.id] = mutation
end

-- eyes = { height, spread, size }. look = "Shape size offset RRGGBB flags; ..." body first, facing -Z.
-- flags: neon / glass / field (material), t.5 (transparency), r0,0,90 (rotation), plain (never tinted).
local function addKatakata(tier, name, price, gistPerSecond, eyes, look, effect)
	local creature = { id = string.gsub(name, "%W", ""), name = name, tier = tier, price = price, rate = gistPerSecond, eyes = eyes, look = look, effect = effect }
	creatures[creature.id] = creature
	table.insert(Catalog.CREATURES, creature)
end

addKatakata(1, "Puff-Puff Phantom", 10, 1, { 0.5, 0.9, 1 }, "Ball 4 0,0,0 D9963A; Ball 2.2 1.3,1.8,.2 E3A64B; Ball 1.8 -1.3,1.7,.4 C98428; Ball 2.2 0,-1.5,1.4 F1D3A0 t.45")
addKatakata(1, "Sachet Splash", 40, 3, { 0.6, 0.7, 0.9 }, "Block 3,4,1.6 0,0,0 9FE3FF glass t.2; Block 1,.8,.8 0,2.4,0 FFFFFF; Ball 1.1 2.1,1.5,0 4FC3F7; Ball .8 -2,2.1,0 4FC3F7")
addKatakata(1, "Gala Gremlin", 100, 6, { 0.3, 0.9, 0.9 }, "Cylinder 5,2.6,2.6 0,0,0 E8B36B; Ball 2.2 2.5,0,0 C45B4E; Ball 2.2 -2.5,0,0 C45B4E; Block .6,1.5,.6 1,1.7,0 5DBB3F; Block .6,1.5,.6 -1,1.7,0 5DBB3F")
addKatakata(2, "Okada Wiggle", 250, 12, { 0.7, 0.5, 0.8 }, "Block 1.6,2,5 0,0,0 D32F2F; Cylinder .8,2.6,2.6 0,-1.2,-2.2 222222; Cylinder .8,2.6,2.6 0,-1.2,2.2 222222; Block 3.6,.4,.4 0,1.5,-2 9E9E9E; Ball 1 0,.1,-2.8 FFF176 neon plain")
addKatakata(2, "Danfo Honk", 600, 25, { 0.9, 1, 1.1 }, "Block 4,3.6,7 0,0,0 FFC107; Block 4.1,.7,7.1 0,-.4,0 212121 plain; Cylinder 4.8,1.8,1.8 0,-1.9,-2.3 222222; Cylinder 4.8,1.8,1.8 0,-1.9,2.3 222222; Cylinder 1.8,1.1,1.1 0,2.3,-2.4 CFD8DC r0,90,0")
addKatakata(2, "Zobo Zoomer", 1200, 45, { 0.6, 0.55, 0.8 }, "Block 2.4,4.4,2.4 0,0,0 8E1B3A glass t.1; Block 1.3,.8,1.3 0,2.6,0 FFFFFF; Block .3,2.4,.3 .5,3.6,0 66BB6A; Ball 1.3 0,-2.5,1 FF4FA3 neon")
addKatakata(3, "Jollof Drift", 3000, 100, { 0.2, 0.9, 1 }, "Ball 4.4 0,0,0 2B2B2B; Ball 3.7 0,1.3,0 F26B1D; Block 6.2,.5,.8 0,.6,0 1B1B1B; Ball .7 .9,3,-.4 D50000; Ball 1.8 0,-1,2.9 BDBDBD t.5")
addKatakata(3, "Gist Goblin", 6500, 190, { 0.7, 0.9, 1.2 }, "Ball 4 0,0,0 6BCB3C; Block .5,2.4,1.6 2.3,.9,0 58B02E; Block .5,2.4,1.6 -2.3,.9,0 58B02E; Block 2.4,.9,.5 0,-.9,-1.8 7A1420 plain; Block 3,1.8,.4 2.6,3.2,0 FFFFFF plain")
addKatakata(3, "Generator Grumble", 12000, 320, { 0.4, 1.1, 1 }, "Block 5,3,3.4 0,0,0 37607A; Block .6,2.4,.6 2,2.5,0 263238; Ball 1.5 2,4.2,0 9E9E9E t.4; Ball 1 -1.4,1.8,0 E53935; Block 5.6,.5,3.4 0,-1.75,0 212121")
addKatakata(4, "Suya Ember", 30000, 700, { 0.2, 0.6, 0.9 }, "Block 2.6,2.4,2.6 0,0,0 8B3A1E; Block 2.4,2.2,2.4 0,2.7,0 9C4A22; Block 2.4,2.2,2.4 0,-2.7,0 7A2F16; Block 2.9,.5,2.9 0,1.35,0 E1BEE7; Block .4,10,.4 0,.6,0 D7B98A plain", "flame")
addKatakata(4, "Agbero Whistle", 60000, 1250, { 1, 0.7, 0.9 }, "Block 3,4.2,2 0,0,0 2E7D32; Block 3.3,.8,3.6 0,2.5,-.5 FAFAFA; Ball 1.2 0,-.1,-1.5 ECEFF1 neon plain; Block 1,3.2,1 2.1,.9,0 1B5E20; Block 1,3.2,1 -2.1,-.3,0 1B5E20")
addKatakata(4, "Keke Karaoke", 110000, 2100, { 0.4, 0.9, 1 }, "Block 3.6,3.4,5 0,0,0 C0CA33; Block 4,.5,5.4 0,2,0 263238; Cylinder .8,2,2 0,-1.9,-2.2 222222; Cylinder 4.6,2,2 0,-1.9,1.8 222222; Ball 1.6 0,3.2,0 FF4FA3 neon")
addKatakata(5, "Harmattan Howler", 300000, 5000, { 0.9, 1, 1.1 }, "Ball 5 0,0,0 E0C9A0 t.15; Cylinder .6,7.5,7.5 0,-1.6,0 CDB38A r0,0,90 t.3; Cylinder .6,5.2,5.2 0,2.3,0 CDB38A r0,0,90 t.3; Ball 1.8 0,-.8,-2.1 3E2F1C plain")
addKatakata(5, "Afrobeat Echo", 650000, 9500, { 2.6, 1, 0.9 }, "Block 4.6,6.4,3.6 0,0,0 3A1C5C; Ball 2.6 0,.6,-1.3 FF3D9A neon; Ball 1.9 0,-1.9,-1.4 29D9FF neon; Block 5.6,.6,.9 0,3.5,0 FFC400; Ball 8.5 0,0,0 FF7AC8 field t.5 plain")
addKatakata(6, "Last-Bus Leviathan", 3000000, 36000, { 1, 1.3, 1.3 }, "Block 5,4.6,8 0,0,0 1A237E; Block 4.4,4,4.4 0,.5,6.4 283593; Block 3.6,3.2,3.6 0,1.2,10.4 3949AB; Block .5,2.6,3 0,3.5,0 00E5C3 neon; Block 4,1,.5 0,-1.4,-4 FFF176 neon plain")
addKatakata(6, "Eko Eclipse", 8000000, 85000, { 0.6, 1.3, 1.3 }, "Ball 6.5 0,0,0 0B0B14; Cylinder .4,10.5,10.5 0,0,.4 FF9E2C r0,90,0 neon; Ball 1.5 5.4,3.2,0 FFFFFF neon; Ball 1.1 -5.2,-2.4,0 FFC400 neon", "glow")

function Catalog.creatureById(creatureId)
	return creatures[creatureId]
end

function Catalog.mutationById(mutationId)
	return mutations[mutationId] or mutations.None
end

-- Gist per second of a creature with its mutation, before the Come-Up multiplier.
function Catalog.gistRate(creatureId, mutationId)
	return creatures[creatureId].rate * Catalog.mutationById(mutationId).multiplier
end

-- Rolls a mutation id; luck thins out the plain result.
function Catalog.rollMutation(luck)
	local weights, total = {}, 0
	for index, mutation in ipairs(Catalog.MUTATIONS) do
		weights[index] = index == 1 and math.max(15, mutation.weight - 12 * luck) or mutation.weight
		total += weights[index]
	end
	local pick = math.random() * total
	for index, mutation in ipairs(Catalog.MUTATIONS) do
		pick -= weights[index]
		if pick <= 0 then
			return mutation.id
		end
	end
	return "None"
end

-- Price to bag a roamer: a mutated one costs more, but less than it earns back.
function Catalog.bagPrice(creatureId, mutationId)
	return math.floor(creatures[creatureId].price * (1 + (Catalog.mutationById(mutationId).multiplier - 1) * 0.4))
end

function Catalog.sellValue(creatureId, mutationId)
	return math.floor(Catalog.bagPrice(creatureId, mutationId) / 2)
end

function Catalog.rerollCost(creatureId)
	return math.max(15, math.floor(creatures[creatureId].price * 0.6))
end

-- Cost of the next Lane Pass, nil at the top.
function Catalog.nextLanePassCost(tier)
	return Catalog.RARITIES[tier + 1] and Catalog.RARITIES[tier + 1].passCost
end

function Catalog.padLockCost(locksOwned)
	return 120 * 3 ^ locksOwned
end

function Catalog.gateBarCost(tier)
	return 80 * 4 ^ (tier - 1)
end

-- Come-Up (rebirth): the price grows, the multiplier is permanent.
function Catalog.comeUpCost(comeUps)
	return 25000 * 6 ^ comeUps
end

function Catalog.comeUpMultiplier(comeUps)
	return 1 + comeUps
end

function Catalog.creaturesOfTier(tier)
	local list = {}
	for _, creature in ipairs(Catalog.CREATURES) do
		if creature.tier == tier then
			table.insert(list, creature)
		end
	end
	return list
end

-- "Okada Wiggle", or "Gold Okada Wiggle" when mutated.
function Catalog.displayName(creatureId, mutationId)
	local mutation = Catalog.mutationById(mutationId)
	return (mutation.id == "None" and "" or mutation.id .. " ") .. creatures[creatureId].name
end

-- 950 -> "950", 1250 -> "1.25K", 3000000 -> "3M".
function Catalog.formatGist(amount)
	local value, index = math.floor(amount or 0), 1
	local suffixes = { "", "K", "M", "B", "T" }
	while value >= 1000 and index < #suffixes do
		value /= 1000
		index += 1
	end
	local text = string.gsub(string.format("%.2f", math.floor(value * 100) / 100), "%.?0+$", "")
	return (index == 1 and tostring(math.floor(amount or 0)) or text) .. suffixes[index]
end

return Catalog
