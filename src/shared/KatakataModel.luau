-- KatakataModel: builds a Katakata from primitive parts, tints it for its mutation and hangs
-- the name / rarity / Gist-per-second label over it.

local CollectionService = game:GetService("CollectionService")

local Catalog = require(script.Parent.KatakataCatalog)
local Make = require(script.Parent.Make)

local KatakataModel = {}

KatakataModel.RAINBOW_TAG = "RainbowKatakataPart"

-- A Model whose anchored PrimaryPart "Root" carries every other part by weld.
function KatakataModel.buildKatakata(creatureId, mutationId, sizeFactor)
	local creature = Catalog.creatureById(creatureId)
	local mutation = Catalog.mutationById(mutationId)
	local scale = Catalog.RARITIES[creature.tier].scale * (sizeFactor or 1)
	local model = Make.new("Model", { Name = creature.name })
	local root, top, bottom, index = nil, -99, 99, 0

	for spec in string.gmatch(creature.look, "[^;]+") do
		index += 1
		local part, plain = KatakataModel.shapePart(spec, scale)
		if not plain then
			KatakataModel.tintForMutation(part, mutation, index)
		end
		top = math.max(top, part.Position.Y + part.Size.Y / 2)
		bottom = math.min(bottom, part.Position.Y - part.Size.Y / 2)
		if root then
			KatakataModel.weldToRoot(root, part)
		else
			root = part
			root.Name = "Root"
		end
		part.Parent = model
	end

	-- Two googly eyes on the front of the body, never tinted.
	local eyeY, spread, size = table.unpack(creature.eyes)
	local frontZ = -root.Size.Z / scale / 2 * (root.Shape == Enum.PartType.Ball and 0.86 or 1)
	for side = -1, 1, 2 do
		local eye = KatakataModel.shapePart(string.format("Ball %g %g,%g,%g FFFFFF", size, side * spread, eyeY, frontZ), scale)
		local pupil = KatakataModel.shapePart(string.format("Ball %g %g,%g,%g 111111", size / 2, side * spread * 0.92, eyeY, frontZ - size * 0.36), scale)
		KatakataModel.weldToRoot(root, eye).Parent = model
		KatakataModel.weldToRoot(root, pupil).Parent = model
	end

	-- Built-in light and fire only.
	if mutation.id ~= "None" or creature.effect == "glow" then
		Make.new("PointLight", { Color = mutation.color, Range = 14, Brightness = 1.6, Shadows = false }, root)
	end
	if mutation.id == "Spicy" or creature.effect == "flame" then
		Make.new("Fire", { Heat = 9, Size = 5, Color = Color3.fromRGB(255, 120, 30) }, root)
	end

	root.Anchored = true
	model.PrimaryPart = root
	model:SetAttribute("CreatureId", creatureId)
	model:SetAttribute("Mutation", mutation.id)
	model:SetAttribute("TopOffset", top)
	model:SetAttribute("GroundOffset", -bottom)
	return model
end

-- The floating label: NAME, RARITY | MUTATION xN, +Gist/s | footer (the price).
function KatakataModel.attachLabel(model, creatureId, mutationId, footer)
	local creature = Catalog.creatureById(creatureId)
	local rarity = Catalog.RARITIES[creature.tier]
	local mutation = Catalog.mutationById(mutationId)
	local mutated = mutation.id ~= "None"
	local accent = mutated and mutation.color or rarity.color

	local billboard = Make.billboard(model.PrimaryPart, "KatakataLabel", 13, 5.4, model:GetAttribute("TopOffset") + 3.4)
	local plate = Make.panel(billboard, "Plate", accent)
	local rarityText = string.upper(rarity.id) .. (mutated and "  |  " .. string.upper(mutation.id) .. " x" .. mutation.multiplier or "")
	local rateText = "+" .. Catalog.formatGist(Catalog.gistRate(creatureId, mutationId)) .. " GIST/S" .. (footer and "  |  " .. footer or "")
	Make.label(plate, "NameLine", string.upper(creature.name), rarity.color, UDim2.fromScale(0.03, 0.04), UDim2.fromScale(0.94, 0.36))
	Make.label(plate, "RarityLine", rarityText, accent, UDim2.fromScale(0.03, 0.4), UDim2.fromScale(0.94, 0.26))
	Make.label(plate, "RateLine", rateText, Color3.fromRGB(255, 232, 120), UDim2.fromScale(0.03, 0.67), UDim2.fromScale(0.94, 0.29))
	return billboard
end

-- One "Shape size offset RRGGBB flags" spec -> one Part, placed relative to the root.
function KatakataModel.shapePart(spec, scale)
	local shape, size, offset, hex, flags = string.match(spec, "(%a+) (%S+) (%S+) (%x+)(.*)")
	local function vector(text)
		local x, y, z = string.match(text, "(.+),(.+),(.+)")
		return Vector3.new(tonumber(x or text), tonumber(y or text), tonumber(z or text))
	end
	local material = string.find(flags, "neon") and "Neon" or string.find(flags, "glass") and "Glass" or string.find(flags, "field") and "ForceField" or nil
	local part = Make.part(nil, shape, vector(size) * scale, vector(offset) * scale, hex, material)
	local turn = string.match(flags, " r(%S+)")
	if turn then
		turn = vector(turn)
		part.CFrame *= CFrame.Angles(math.rad(turn.X), math.rad(turn.Y), math.rad(turn.Z))
	end
	part.Shape = Enum.PartType[shape]
	part.Transparency = tonumber(string.match(flags, " t(%S+)")) or 0
	part.Anchored, part.CanCollide, part.CanTouch, part.CanQuery, part.Massless = false, false, false, false, true
	return part, string.find(flags, "plain") ~= nil
end

-- Gold, Spicy, Neon and Rainbow each repaint the body.
function KatakataModel.tintForMutation(part, mutation, index)
	if mutation.id == "Gold" then
		part.Color = part.Color:Lerp(mutation.color, 0.8)
		part.Material = Enum.Material.Metal
		part.Reflectance = 0.25
	elseif mutation.id == "Spicy" then
		part.Color = part.Color:Lerp(mutation.color, 0.65)
	elseif mutation.id == "Neon" then
		part.Color = part.Color:Lerp(mutation.color, 0.7)
		part.Material = Enum.Material.Neon
	elseif mutation.id == "Rainbow" then
		part.Material = Enum.Material.Neon
		part:SetAttribute("HueOffset", index * 0.17 % 1)
		CollectionService:AddTag(part, KatakataModel.RAINBOW_TAG) -- the client cycles its hue
	end
end

function KatakataModel.weldToRoot(root, part)
	Make.new("WeldConstraint", { Part0 = root, Part1 = part }, part)
	return part
end

return KatakataModel
