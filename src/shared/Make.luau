-- Make: one-line constructors for parts, signs and text. No uploaded image, mesh or sound anywhere.

local Make = {}

-- Any instance: properties from a table, parented last.
function Make.new(className, properties, parent)
	local instance = Instance.new(className)
	for key, value in pairs(properties) do
		instance[key] = value
	end
	instance.Parent = parent
	return instance
end

-- An anchored coloured part. at: Vector3 or CFrame; hex: "RRGGBB"; material: a name.
function Make.part(parent, name, size, at, hex, material)
	return Make.new("Part", {
		Name = name,
		Anchored = true,
		Size = size,
		CFrame = typeof(at) == "CFrame" and at or CFrame.new(at),
		Color = Color3.fromHex(hex),
		Material = Enum.Material[material or "SmoothPlastic"],
		TopSurface = Enum.SurfaceType.Smooth,
		BottomSurface = Enum.SurfaceType.Smooth,
	}, parent)
end

-- Bold, scaled, outlined text that survives a scaled-down screenshot.
function Make.label(parent, name, text, color, position, size)
	return Make.new("TextLabel", {
		Name = name,
		Text = text,
		TextColor3 = color,
		Position = position or UDim2.fromScale(0, 0),
		Size = size or UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBlack,
		TextScaled = true,
		TextStrokeTransparency = 0,
	}, parent)
end

-- A dark rounded backing with a coloured outline, for HUD panels and world signs.
function Make.panel(parent, name, strokeColor, properties)
	local panel = Make.new("Frame", { Name = name, Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(24, 12, 32), BackgroundTransparency = 0.25, BorderSizePixel = 0 }, parent)
	for key, value in pairs(properties or {}) do
		panel[key] = value
	end
	Make.new("UICorner", { CornerRadius = UDim.new(0, 12) }, panel)
	Make.new("UIStroke", { Color = strokeColor, Thickness = 3 }, panel)
	return panel
end

-- A camera-facing sign, sized in studs, lift studs above its part.
function Make.billboard(adornee, name, width, height, lift, maxDistance)
	return Make.new("BillboardGui", {
		Name = name,
		Size = UDim2.fromScale(width, height),
		StudsOffsetWorldSpace = Vector3.new(0, lift, 0),
		MaxDistance = maxDistance or 150,
		LightInfluence = 0,
		Adornee = adornee,
	}, adornee)
end

return Make
