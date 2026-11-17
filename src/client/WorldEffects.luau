-- WorldEffects: presentation only. "+Gist" pops over the player's own stashed Katakatas each
-- second, a YOUR GATE beacon, colour-cycling Rainbow mutations, and the dusty sky and camera shake
-- of a Snatch Wave. The server never depends on any of it.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Shared = game:GetService("ReplicatedStorage"):WaitForChild("Shared")
local Catalog = require(Shared.KatakataCatalog)
local KatakataModel = require(Shared.KatakataModel)
local Make = require(Shared.Make)

local WorldEffects = {}

local player = Players.LocalPlayer
local homeBeacon = nil
local waveMood = 0 -- 0 calm .. 1 full dust

-- Floats "+N GIST" above every stashed Katakata in the player's own yard: money ticking at its rate.
function WorldEffects.popPadIncome()
	local compounds = workspace:FindFirstChild("Compounds")
	local compound = compounds and compounds:FindFirstChild("Compound" .. (player:GetAttribute("PlotIndex") or 0))
	for _, pad in ipairs(compound and compound.Pads:GetChildren() or {}) do
		local rate = pad:GetAttribute("StashedRate") or 0
		if rate > 0 then
			local pop = Make.billboard(pad, "GistPop", 7, 2, 3)
			pop.AlwaysOnTop = true
			local label = Make.label(pop, "PopText", "+" .. Catalog.formatGist(rate) .. " GIST", Color3.fromRGB(120, 255, 140))
			local rise = TweenInfo.new(0.9)
			TweenService:Create(pop, rise, { StudsOffsetWorldSpace = Vector3.new(0, 6.5, 0) }):Play()
			TweenService:Create(label, rise, { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			Debris:AddItem(pop, 1)
		end
	end
	-- A sign that shows through walls over the player's own gate, so the dash home has a target.
	local lintel = compound and compound:FindFirstChild("GateLintel")
	if lintel and not homeBeacon then
		homeBeacon = Make.billboard(lintel, "HomeBeacon", 0, 0, 6, math.huge)
		homeBeacon.Size = UDim2.fromOffset(190, 46)
		homeBeacon.AlwaysOnTop = true
		homeBeacon.Parent = player.PlayerGui
		Make.label(Make.panel(homeBeacon, "Plate", Color3.fromRGB(255, 210, 70)), "BeaconText", "YOUR GATE", Color3.fromRGB(255, 210, 70))
	end
end

-- Rainbow mutations cycle through the hues, each part offset so the creature shimmers.
function WorldEffects.cycleRainbowParts()
	for _, part in ipairs(CollectionService:GetTagged(KatakataModel.RAINBOW_TAG)) do
		part.Color = Color3.fromHSV((os.clock() * 0.35 + (part:GetAttribute("HueOffset") or 0)) % 1, 0.85, 1)
	end
end

-- While a wave sweeps, the air turns to dust and the camera shakes as the wall closes in.
function WorldEffects.updateWaveMood(deltaTime)
	local sweeping = workspace:GetAttribute("WaveState") == "Sweeping"
	waveMood += ((sweeping and 1 or 0) - waveMood) * math.min(1, deltaTime * 2)
	local tint = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if tint and atmosphere then
		tint.TintColor = Color3.fromRGB(255, 236, 214):Lerp(Color3.fromRGB(255, 176, 110), waveMood)
		atmosphere.Density = 0.3 + 0.2 * waveMood
		atmosphere.Haze = 1.6 + 2.4 * waveMood
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid and rootPart then
		local gap = math.abs(rootPart.Position.Z - (workspace:GetAttribute("WaveFrontZ") or -999))
		local shake = sweeping and math.clamp(1 - gap / 70, 0, 1) * 0.35 or 0
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * shake, (math.random() - 0.5) * shake, 0)
	end
end

function WorldEffects.startEffects()
	RunService.RenderStepped:Connect(function(deltaTime)
		WorldEffects.cycleRainbowParts()
		WorldEffects.updateWaveMood(deltaTime)
	end)
	task.spawn(function()
		while task.wait(1) do
			WorldEffects.popPadIncome()
		end
	end)
end

return WorldEffects
