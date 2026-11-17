-- Katakata Compound client: input, HUD and presentation. All game state comes from the server.

local Hud = require(script:WaitForChild("Hud"))
local SprintControls = require(script:WaitForChild("SprintControls"))
local WorldEffects = require(script:WaitForChild("WorldEffects"))

Hud.buildHud()
SprintControls.bindSprint()
WorldEffects.startEffects()
