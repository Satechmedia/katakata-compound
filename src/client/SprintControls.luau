-- SprintControls: hold Shift (or the touch Sprint button, or click the left stick) to sprint.
-- Walking is Roblox's default character controller: WASD, arrow keys, thumbstick, jump.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")

local SprintControls = {}

local sprintHeld = false

-- Sets the humanoid's speed and eases the field of view for a feeling of pace.
function SprintControls.applySprintSpeed(deltaTime)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local camera = workspace.CurrentCamera
	if humanoid and camera then
		local sprinting = sprintHeld or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		humanoid.WalkSpeed = sprinting and 28 or 16
		camera.FieldOfView += ((sprinting and 82 or 70) - camera.FieldOfView) * math.min(1, deltaTime * 8)
	end
end

-- Bound with ContextActionService and backed by IsKeyDown, so the camera scripts cannot eat the key.
function SprintControls.bindSprint()
	ContextActionService:BindAction("KatakataSprint", function(_, state)
		sprintHeld = state == Enum.UserInputState.Begin
		return Enum.ContextActionResult.Pass
	end, true, Enum.KeyCode.LeftShift, Enum.KeyCode.RightShift, Enum.KeyCode.ButtonL3)
	ContextActionService:SetTitle("KatakataSprint", "Sprint")
	RunService.RenderStepped:Connect(SprintControls.applySprintSpeed)
end

return SprintControls
