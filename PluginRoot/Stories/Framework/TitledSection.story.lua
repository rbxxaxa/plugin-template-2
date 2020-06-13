local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local Roact = load("Roact")
local TitledSection = load("Framework/TitledSection")

local e = Roact.createElement

return function(target)
	local section = e(TitledSection, {
		title = "TEST TITLE SECTION",
		position = UDim2.new(0, 20, 0, 20),
		width = UDim.new(0, 200),
	}, {
		Text1 = e("TextLabel", {
			Text = "Text1",
			Size = UDim2.fromOffset(100, 100),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
			TextColor3 = Color3.new(1, 1, 1),
			LayoutOrder = 1,
		}),
		Text2 = e("TextLabel", {
			Text = "Text2",
			Size = UDim2.fromOffset(100, 100),
			TextStrokeColor3 = Color3.new(0, 0, 0),
			TextStrokeTransparency = 0,
			TextColor3 = Color3.new(1, 1, 1),
			LayoutOrder = 2,
		}),
	})
	local handle = Roact.mount(section, target)

	return function()
		Roact.unmount(handle)
	end
end
