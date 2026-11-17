-- ComeUpRebirth: the rebirth. A Come-Up spends Gist, clears the yard (pads, locks, Lane Pass,
-- Gate Bars, hands) and grants a permanent Gist multiplier.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Catalog = require(ReplicatedStorage:WaitForChild("Shared").KatakataCatalog)
local PlayerLedger = require(script.Parent.PlayerLedger)
local Collector = require(script.Parent.Collector)
local BaseYard = require(script.Parent.BaseYard)

local ComeUpRebirth = {}

local remotes = ReplicatedStorage:WaitForChild("Remotes")

-- Checks the price on the server, then resets the run and raises the multiplier.
function ComeUpRebirth.performComeUp(player)
	local ledger = PlayerLedger.getLedger(player)
	local cost = ledger and Catalog.comeUpCost(ledger.comeUps)
	if not ledger or ledger.gist < cost then
		return false
	end
	ledger.gist, ledger.lanePass, ledger.gateBars = Catalog.STARTING_GIST, 1, 0
	ledger.comeUps += 1
	Collector.takeCarried(player)
	BaseYard.clearYard(player)
	PlayerLedger.publishLedger(player)
	remotes.ComeUpEvent:FireClient(player, "Done", Catalog.comeUpMultiplier(ledger.comeUps))
	task.spawn(PlayerLedger.saveLedger, player)
	return true
end

-- The yard drum opens the confirmation; YES comes back as a request.
function ComeUpRebirth.setupDrums(plots)
	for _, plot in ipairs(plots) do
		local prompt = plot.stations.comeUp.StationPrompt
		prompt.ActionText = "Beat the drum"
		prompt.Triggered:Connect(function(player)
			if plot.owner == player then
				remotes.ComeUpEvent:FireClient(player, "Confirm")
			end
		end)
	end
	remotes.RequestComeUp.OnServerEvent:Connect(ComeUpRebirth.performComeUp)
end

return ComeUpRebirth
