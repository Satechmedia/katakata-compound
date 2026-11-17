-- MarketMap: the layout both sides agree on. The compound wall runs along GATE_Z: larger Z is
-- inside a compound (safe), smaller Z is the market, cut into six rarity lane zones.

local MarketMap = {}

MarketMap.GATE_Z = 20
MarketMap.WAVE_START_Z = -250 -- where a Snatch Wave rises
MarketMap.WAVE_STOP_Z = 16 -- where it breaks against the compound wall
MarketMap.PLOT_COUNT = 6
MarketMap.PLOT_WIDTH = 44
MarketMap.YARD_DEPTH = 72
MarketMap.PADS_PER_YARD = 8
MarketMap.ZONE_START_Z = -10 -- the gate plaza lies between the wall and the first zone
MarketMap.ZONE_DEPTH = 38
MarketMap.HALF_WIDTH = 132
MarketMap.GROUND_Y = 0.2

-- True behind the compound wall, where the Snatch Wave cannot reach.
function MarketMap.isInsideCompound(position)
	return position.Z > MarketMap.GATE_Z
end

-- X of the middle of a compound, its gate and its lane.
function MarketMap.plotCenterX(plotIndex)
	return (plotIndex - (MarketMap.PLOT_COUNT + 1) / 2) * MarketMap.PLOT_WIDTH
end

-- Ground position of a stash pad: two rows of four behind the gate.
function MarketMap.padPosition(plotIndex, padIndex)
	local column, row = (padIndex - 1) % 4, math.floor((padIndex - 1) / 4)
	return Vector3.new(MarketMap.plotCenterX(plotIndex) + (column - 1.5) * 9, MarketMap.GROUND_Y, MarketMap.GATE_Z + 19 + row * 14)
end

function MarketMap.yardSpawnPosition(plotIndex)
	return Vector3.new(MarketMap.plotCenterX(plotIndex), MarketMap.GROUND_Y + 0.5, MarketMap.GATE_Z + 44)
end

-- The Z span where a rarity tier roams; nearZ is the gate side.
function MarketMap.laneZone(tier)
	local nearZ = MarketMap.ZONE_START_Z - (tier - 1) * MarketMap.ZONE_DEPTH
	return nearZ, nearZ - MarketMap.ZONE_DEPTH
end

-- A random walkable point in one lane of a tier's zone.
function MarketMap.randomLanePoint(tier, laneIndex)
	local lane = laneIndex or math.random(1, MarketMap.PLOT_COUNT)
	local nearZ, farZ = MarketMap.laneZone(tier)
	local x = MarketMap.plotCenterX(lane) + (math.random() - 0.5) * 20
	return Vector3.new(x, MarketMap.GROUND_Y, farZ + 4 + math.random() * (MarketMap.ZONE_DEPTH - 8)), lane
end

return MarketMap
