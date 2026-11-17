-- KatakataSpawner: keeps the lanes full of roaming Katakatas; rarer ones roam deeper zones.
-- Each wanders, wears its label, rolls a mutation and offers a "Bag it" prompt on E.

local RunService = game:GetService("RunService")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local KatakataModel = require(Shared.KatakataModel)
local MarketMap = require(Shared.MarketMap)
local Make = require(Shared.Make)
local Collector = require(script.Parent.Collector)

local KatakataSpawner = {}

local ROAMERS_PER_TIER = { 5, 4, 4, 3, 3, 2 }
local roamers = {} -- [Model] = { id, mutation, model, tier, lane, position, target, speed, hover }
local marketFolder = Make.new("Folder", { Name = "RoamingKatakatas" }, workspace)

-- Spawns one roaming Katakata of a tier in that tier's lane zone.
function KatakataSpawner.spawnKatakata(tier)
	local choices = Catalog.creaturesOfTier(tier)
	local creature = choices[math.random(#choices)]
	local mutationId = Catalog.rollMutation(0)
	local price = Catalog.formatGist(Catalog.bagPrice(creature.id, mutationId))
	local position, lane = MarketMap.randomLanePoint(tier)
	local model = KatakataModel.buildKatakata(creature.id, mutationId)
	KatakataModel.attachLabel(model, creature.id, mutationId, price .. " GIST")
	local roamer = { id = creature.id, mutation = mutationId, model = model, tier = tier, lane = lane, position = position, target = position }
	roamer.speed = 4 + tier * 1.3 + math.random() * 2
	roamer.hover = model:GetAttribute("GroundOffset") + 0.5

	local prompt = Make.new("ProximityPrompt", { Name = "BagPrompt", HoldDuration = 0.2, MaxActivationDistance = 13, RequiresLineOfSight = false }, model.PrimaryPart)
	prompt.ObjectText = Catalog.displayName(creature.id, mutationId)
	prompt.ActionText = "Bag it (" .. price .. " Gist)"
	prompt.Triggered:Connect(function(player)
		KatakataSpawner.onBagPrompt(player, roamer)
	end)

	model:PivotTo(CFrame.new(position + Vector3.new(0, roamer.hover, 0)))
	model.Parent = marketFolder
	roamers[model] = roamer
end

-- E on a roamer: the Collector decides; a bagged one is replaced later.
function KatakataSpawner.onBagPrompt(player, roamer)
	if roamers[roamer.model] and Collector.bagCreature(player, roamer.id, roamer.mutation) then
		roamers[roamer.model] = nil
		roamer.model:Destroy()
		task.delay(5, KatakataSpawner.spawnKatakata, roamer.tier)
	end
end

-- Moves every roamer a step: pick a point, waddle, bob, wiggle.
function KatakataSpawner.wanderRoamers(deltaTime)
	local now = os.clock()
	for model, roamer in pairs(roamers) do
		local offset = roamer.target - roamer.position
		if offset.Magnitude < 1 then
			roamer.target = MarketMap.randomLanePoint(roamer.tier, roamer.lane)
		else
			roamer.position += offset.Unit * math.min(offset.Magnitude, roamer.speed * deltaTime)
			roamer.facing = CFrame.lookAt(Vector3.zero, offset).Rotation
		end
		local bob = math.abs(math.sin(now * 4 + roamer.speed)) * 0.9
		local wiggle = CFrame.Angles(0, 0, math.sin(now * 6 + roamer.speed) * 0.12)
		model.PrimaryPart.CFrame = CFrame.new(roamer.position + Vector3.new(0, roamer.hover + bob, 0)) * (roamer.facing or CFrame.new()) * wiggle
	end
end

-- After a Snatch Wave the market restocks with fresh rolls.
function KatakataSpawner.reshuffleMarket()
	for model, roamer in pairs(table.clone(roamers)) do
		roamers[model] = nil
		model:Destroy()
		KatakataSpawner.spawnKatakata(roamer.tier)
	end
end

function KatakataSpawner.startSpawning()
	for tier, count in ipairs(ROAMERS_PER_TIER) do
		for _ = 1, count do
			KatakataSpawner.spawnKatakata(tier)
		end
	end
	RunService.Heartbeat:Connect(KatakataSpawner.wanderRoamers)
end

return KatakataSpawner
