-- WorldBuilder: builds Eko Shore from coloured parts: six walled compounds (gate, yard, stash
-- pads, house, stations) and the street market (plaza, rarity lanes, stalls, lanterns, palms).

local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local MarketMap = require(Shared.MarketMap)
local Make = require(Shared.Make)

local WorldBuilder = {}

local V3, part = Vector3.new, Make.part
local GROUND, GATE_Z, DEPTH, WIDTH = MarketMap.GROUND_Y, MarketMap.GATE_Z, MarketMap.YARD_DEPTH, MarketMap.HALF_WIDTH * 2 + 16
local COMPOUND_COLORS = { "F4C095", "A8D5BA", "F7E08B", "E8A0A0", "9CC4E4", "D7B8F3" }
local BRIGHT_COLORS = { "E53935", "FB8C00", "FDD835", "43A047", "1E88E5", "8E24AA", "00ACC1", "F06292" }
local GOLD = Color3.fromRGB(255, 210, 80)

-- One compound: walls, gate with name sign, yard, pads, house, spawn, stations.
function WorldBuilder.buildCompound(plotIndex, parent)
	local x, midZ, backZ = MarketMap.plotCenterX(plotIndex), GATE_Z + DEPTH / 2, GATE_Z + DEPTH
	local wallColor = COMPOUND_COLORS[plotIndex]
	local compound = Make.new("Model", { Name = "Compound" .. plotIndex }, parent)
	part(compound, "YardFloor", V3(44, 0.2, DEPTH), V3(x, GROUND - 0.1, midZ), "B9694A", "Pavement")

	-- Front wall, gate posts, lanterns, name sign, lit windows.
	for side = -1, 1, 2 do
		part(compound, "GateWall", V3(15, 12, 2), V3(x + side * 14.5, 6, GATE_Z), wallColor, "Concrete")
		part(compound, "Window", V3(3.6, 3, 0.4), V3(x + side * 8, GROUND + 6.4, backZ - 12.1), "FFD27F", "Neon")
		part(compound, "GatePost", V3(2, 15, 2.8), V3(x + side * 8, 7.5, GATE_Z), "5D4037", "Wood")
		WorldBuilder.buildLantern(compound, V3(x + side * 8, 16.4, GATE_Z), true)
	end
	local lintel = part(compound, "GateLintel", V3(18, 3, 2.8), V3(x, 15, GATE_Z), "3E2723", "Wood")
	local signs = { WorldBuilder.paintSign(lintel, "Front", "VACANT COMPOUND", GOLD), WorldBuilder.paintSign(lintel, "Back", "VACANT COMPOUND", GOLD) }

	-- Side and back walls, then the house.
	for side = -1, plotIndex == MarketMap.PLOT_COUNT and 1 or -1, 2 do
		part(compound, "SideWall", V3(2, 12, DEPTH), V3(x + side * 22, 6, midZ), "E9D8B4", "Concrete")
	end
	part(compound, "BackWall", V3(44, 12, 2), V3(x, 6, backZ), "E9D8B4", "Concrete")
	part(compound, "House", V3(26, 11, 10), V3(x, GROUND + 5.5, backZ - 7), wallColor, "Concrete")
	part(compound, "Roof", V3(29, 1.4, 13), V3(x, GROUND + 11.7, backZ - 7), "8D3B2B", "Slate")
	part(compound, "Door", V3(4, 7, 0.4), V3(x, GROUND + 3.5, backZ - 12.1), "4E342E", "Wood")
	part(compound, "WaterTank", V3(4, 4.4, 4.4), CFrame.new(x + 8, GROUND + 14.6, backZ - 7) * CFrame.Angles(0, 0, math.pi / 2), "263238").Shape = Enum.PartType.Cylinder

	-- Eight stash pads with state plates.
	local padsFolder = Make.new("Folder", { Name = "Pads" }, compound)
	local pads, padLabels = {}, {}
	for padIndex = 1, MarketMap.PADS_PER_YARD do
		local pad = part(padsFolder, "Pad" .. padIndex, V3(7, 0.6, 7), MarketMap.padPosition(plotIndex, padIndex) + V3(0, 0.3, 0), "3B4252")
		part(pad, "PadTrim", V3(7.6, 0.2, 7.6), pad.Position - V3(0, 0.2, 0), "FFD54F", "Neon").CanCollide = false
		pad:SetAttribute("StashedRate", 0)
		pads[padIndex] = pad
		padLabels[padIndex] = Make.label(Make.billboard(pad, "PlateGui", 6.5, 1.5, 1.6, 60), "PlateText", "PAD " .. padIndex .. " - EMPTY", Color3.new(1, 1, 1))
	end

	-- The middle plot reuses the SpawnLocation of default.project.json.
	local spawn = plotIndex == 3 and workspace:FindFirstChild("YardSpawn")
		or Make.new("SpawnLocation", { Name = "YardSpawn" .. plotIndex, Anchored = true, Size = V3(6, 1, 6), Neutral = true, Duration = 0, Color = GOLD, Material = Enum.Material.Neon, Transparency = 0.4 }, compound)
	spawn.Position = MarketMap.yardSpawnPosition(plotIndex)

	-- Next-tier shop, pad lock, gate defence, Come-Up drum.
	local stations = {}
	for index, spec in ipairs({ { "lanePass", "LANE PASS BOARD", "1E88E5" }, { "padLock", "PAD LOCK", "9E9E9E" }, { "gateBar", "GATE BAR", "6D4C41" }, { "comeUp", "COME-UP DRUM", "FF7043" } }) do
		stations[spec[1]] = WorldBuilder.buildStation(compound, spec[2], V3(x + (index % 2 * -30 + 15), GROUND, GATE_Z + (index > 2 and 47 or 8)), spec[3])
	end
	return { model = compound, pads = pads, padLabels = padLabels, signs = signs, spawn = spawn, stations = stations, stashedModels = {}, owner = nil }
end

-- A market stall: counter, posts, striped awning, goods.
function WorldBuilder.buildMarketStall(parent, x, z)
	local stall = Make.new("Model", { Name = "MarketStall" }, parent)
	local tilt = CFrame.Angles(0, 0, math.rad(math.random(-7, 7)))
	part(stall, "Counter", V3(10, 3, 8), V3(x, GROUND + 1.5, z), "8D6E63", "WoodPlanks")
	part(stall, "Awning", V3(13, 0.5, 11), CFrame.new(x, GROUND + 9.4, z) * tilt, BRIGHT_COLORS[math.random(#BRIGHT_COLORS)], "Fabric")
	for side = -1, 1, 2 do
		part(stall, "Post", V3(0.6, 9, 0.6), V3(x + side * 5.3, GROUND + 4.5, z - 4.3), "5D4037", "Wood")
		part(stall, "Post", V3(0.6, 9, 0.6), V3(x + side * 5.3, GROUND + 4.5, z + 4.3), "5D4037", "Wood")
	end
	for slot = -1, 1 do
		part(stall, "AwningStripe", V3(13.1, 0.56, 1.6), CFrame.new(x, GROUND + 9.4, z + slot * 3.6) * tilt, "FFF8E1", "Fabric")
		local goods = part(stall, "Goods", V3(2.2, 2.2, 2.2), V3(x + slot * 3.1, GROUND + 4, z), BRIGHT_COLORS[math.random(#BRIGHT_COLORS)])
		goods.Shape = math.random() < 0.6 and Enum.PartType.Ball or Enum.PartType.Block
	end
	if math.random() < 0.35 then
		WorldBuilder.buildLantern(stall, V3(x, GROUND + 7.6, z + 5.2), false)
	end
end

-- One rarity zone: tinted ground, a banner over every lane, stalls.
function WorldBuilder.buildLaneZone(parent, tier)
	local rarity = Catalog.RARITIES[tier]
	local nearZ, farZ = MarketMap.laneZone(tier)
	local zone = Make.new("Model", { Name = rarity.id .. "LaneZone" }, parent)
	local ground = part(zone, "LaneGround", V3(WIDTH, 0.2, MarketMap.ZONE_DEPTH), V3(0, GROUND - 0.1, (nearZ + farZ) / 2), "D8B77A", "Sand")
	ground.Color = ground.Color:Lerp(rarity.color, 0.25)
	for lane = 1, MarketMap.PLOT_COUNT do
		local x = MarketMap.plotCenterX(lane)
		local banner = part(zone, "LaneBanner", V3(29, 3.2, 0.6), V3(x, GROUND + 12.4, nearZ), "2A1B3D", "Fabric")
		for _, face in ipairs({ "Front", "Back" }) do
			WorldBuilder.paintSign(banner, face, string.upper(rarity.id) .. " LANE  |  PASS " .. tier, rarity.color)
		end
		for side = -1, 1, 2 do
			part(zone, "BannerPost", V3(1, 14, 1), V3(x + side * 15, GROUND + 7, nearZ), "4E342E", "Wood")
			WorldBuilder.buildLantern(zone, V3(x + side * 15, GROUND + 14.8, nearZ), side == 1 and lane % 2 == tier % 2)
		end
	end
	for stallX = -MarketMap.HALF_WIDTH, MarketMap.HALF_WIDTH, MarketMap.PLOT_WIDTH do
		WorldBuilder.buildMarketStall(zone, stallX, nearZ - 11)
		WorldBuilder.buildMarketStall(zone, stallX, nearZ - 28)
	end
end

-- The plaza between wall and market: big sign, Pepper Pots, Bulk Buyers.
function WorldBuilder.buildGatePlaza(parent)
	local plaza = Make.new("Model", { Name = "GatePlaza" }, parent)
	part(plaza, "PlazaGround", V3(WIDTH, 0.2, 30), V3(0, GROUND - 0.1, GATE_Z - 15), "C9A66B", "Cobblestone")
	part(plaza, "SignPole", V3(1.4, 18, 1.4), V3(0, GROUND + 9, 4), "3E2723", "Wood")
	local board = part(plaza, "MarketSign", V3(30, 6, 0.8), V3(0, GROUND + 17, 4), "2A1B3D", "Wood")
	WorldBuilder.paintSign(board, "Front", "EKO SHORE MARKET", GOLD)
	WorldBuilder.paintSign(board, "Back", "KATAKATA COMPOUND", GOLD)
	WorldBuilder.buildLantern(plaza, V3(0, GROUND + 21, 4), true)
	local world = { pepperPots = {}, bulkBuyers = {} }
	for index, x in ipairs({ -44, 88, 44, -88 }) do
		if index < 3 then
			table.insert(world.pepperPots, WorldBuilder.buildStation(plaza, "PEPPER POT", V3(x, GROUND, 6), "D32F2F"))
		else
			table.insert(world.bulkBuyers, WorldBuilder.buildStation(plaza, "BULK BUYER", V3(x, GROUND, 6), "2E7D32"))
		end
	end
	return world
end

-- Outer walls and palms: the edge of the map.
function WorldBuilder.buildBoundary(parent)
	local boundary = Make.new("Model", { Name = "Boundary" }, parent)
	local edgeX, farZ, backZ = WIDTH / 2 + 1, MarketMap.WAVE_START_Z - 6, GATE_Z + DEPTH
	part(boundary, "FarWall", V3(WIDTH + 4, 16, 2), V3(0, 8, farZ), "CDB38A", "Concrete")
	for side = -1, 1, 2 do
		part(boundary, "MarketWall", V3(2, 16, backZ - farZ), V3(side * edgeX, 8, (backZ + farZ) / 2), "CDB38A", "Concrete")
		part(boundary, "CornerWall", V3(9, 12, 2), V3(side * (edgeX - 4.5), 6, GATE_Z), "E9D8B4", "Concrete")
		for z = -230, 0, 46 do
			local at = CFrame.new(side * (edgeX - 3.5), GROUND, z)
			part(boundary, "PalmTrunk", V3(14, 1.5, 1.5), at * CFrame.new(0, 7, 0) * CFrame.Angles(0, 0, math.pi / 2), "8D6E63", "Wood").Shape = Enum.PartType.Cylinder
			for leaf = 0, 3 do
				part(boundary, "PalmLeaf", V3(11, 0.4, 2.2), at * CFrame.new(0, 14, 0) * CFrame.Angles(0, leaf * math.pi / 4, 0.25), "2E7D32", "Grass").CanCollide = false
			end
		end
	end
end

-- Builds everything; returns the handles gameplay needs.
function WorldBuilder.buildWorld()
	local market = Make.new("Folder", { Name = "EkoShore" }, workspace)
	local compounds = Make.new("Folder", { Name = "Compounds" }, workspace)
	local world = WorldBuilder.buildGatePlaza(market)
	world.plots = {}
	for index = 1, MarketMap.PLOT_COUNT do
		world.plots[index] = WorldBuilder.buildCompound(index, compounds)
		WorldBuilder.buildLaneZone(market, index)
	end
	WorldBuilder.buildBoundary(market)
	return world
end

-- A pedestal with a sign and a ProximityPrompt: a 3D shop counter.
function WorldBuilder.buildStation(parent, title, groundPosition, hex)
	local station = part(parent, title, V3(4, 3.4, 4), groundPosition + V3(0, 1.7, 0), hex)
	part(station, "StationCap", V3(2.4, 2.4, 2.4), groundPosition + V3(0, 4.2, 0), "FFD54F", "Neon").Shape = Enum.PartType.Ball
	local plate = Make.panel(Make.billboard(station, "StationSign", 12, 4, 6.6, 70), "Plate", GOLD)
	Make.label(plate, "Title", title, GOLD, UDim2.fromScale(0.04, 0.06), UDim2.fromScale(0.92, 0.46))
	Make.label(plate, "Detail", "", Color3.new(1, 1, 1), UDim2.fromScale(0.04, 0.52), UDim2.fromScale(0.92, 0.42))
	Make.new("ProximityPrompt", { Name = "StationPrompt", ObjectText = title, ActionText = "Buy", HoldDuration = 0.3, MaxActivationDistance = 11, RequiresLineOfSight = false }, station)
	return station
end

-- A glowing lantern ball; only some carry a real PointLight.
function WorldBuilder.buildLantern(parent, position, lit)
	local lantern = part(parent, "Lantern", V3(1.8, 1.8, 1.8), position, "FFB347", "Neon")
	lantern.Shape = Enum.PartType.Ball
	if lit then
		Make.new("PointLight", { Color = Color3.fromRGB(255, 180, 90), Range = 30, Brightness = 1.4, Shadows = false }, lantern)
	end
end

-- Text painted on one face of a part.
function WorldBuilder.paintSign(signPart, face, text, color)
	local gui = Make.new("SurfaceGui", { Name = face .. "Sign", Face = Enum.NormalId[face], SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud, PixelsPerStud = 30, LightInfluence = 0 }, signPart)
	return Make.label(gui, "SignText", text, color)
end

return WorldBuilder
