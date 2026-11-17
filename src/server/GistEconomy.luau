-- GistEconomy: the money. Every second each stashed Katakata pays its rate, and every
-- purchase goes through trySpendGist.

local Players = game:GetService("Players")
local PlayerLedger = require(script.Parent.PlayerLedger)

local GistEconomy = {}

-- Pays every player one second of income.
function GistEconomy.tickIncome()
	for _, player in ipairs(Players:GetPlayers()) do
		local ledger = PlayerLedger.getLedger(player)
		if ledger then
			GistEconomy.earnGist(player, PlayerLedger.gistPerSecond(ledger))
		end
	end
end

function GistEconomy.earnGist(player, amount)
	local ledger = PlayerLedger.getLedger(player)
	if ledger then
		ledger.gist += math.max(0, amount)
		PlayerLedger.publishLedger(player)
	end
end

-- Takes the cost if the player can afford it; true when the Gist was spent.
function GistEconomy.trySpendGist(player, cost)
	local ledger = PlayerLedger.getLedger(player)
	if not ledger or ledger.gist < cost then
		return false
	end
	ledger.gist -= cost
	PlayerLedger.publishLedger(player)
	return true
end

-- Income every second, an autosave every ninety.
function GistEconomy.startIncomeLoop()
	task.spawn(function()
		for second = 1, math.huge do
			task.wait(1)
			GistEconomy.tickIncome()
			for _, player in ipairs(second % 90 == 0 and Players:GetPlayers() or {}) do
				task.spawn(PlayerLedger.saveLedger, player)
			end
		end
	end)
end

return GistEconomy
