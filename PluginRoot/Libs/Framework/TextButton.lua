local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local Roact = load("Roact")
local t = load("t")
local Button = load("Framework/Button")

local e = Roact.createElement

local FONT = Enum.Font.SourceSans
local TEXT_SIZE = 14

local TextButton = Roact.Component:extend("TextButton")

TextButton.defaultProps = {
	size = UDim2.new(0, 100, 0, 100),
	position = UDim2.new(),
	layoutOrder = 0,
	text = "Default Text",
	mouse1Clicked = nil,
	mouse1Pressed = nil,
}

local ITextButton = t.interface({
	size = t.optional(t.UDim2),
	position = t.optional(t.UDim2),
	layoutOrder = t.integer,
	text = t.string,
	mouse1Clicked = t.optional(t.callback),
	mouse1Pressed = t.optional(t.callback),
})

TextButton.validateProps = function(props)
	return ITextButton(props)
end

function TextButton:init()
	self.buttonState, self.updateButtonState = Roact.createBinding("Default")
end

function TextButton:render()
	local props = self.props
	local size = props.size
	local position = props.position
	local layoutOrder = props.layoutOrder
	local text = props.text
	local mouse1Clicked = props.mouse1Clicked
	local mouse1Pressed = props.mouse1Pressed

	-- TODOL theme me
	local theme = {
		textColor = Color3.new(1, 1, 1),
		buttonColor = {
			Default = Color3.new(0, 0, 0),
			Hovered = Color3.new(0, 1, 0),
			PressedIn = Color3.new(0, 0, 1),
			PressedOut = Color3.new(0, 1, 1),
		},
	}

	-- TODO: make me modal
	return e(Button, {
		size = size,
		position = position,
		layoutOrder = layoutOrder,
		buttonStateChanged = self.updateButtonState,
		mouse1Clicked = mouse1Clicked,
		mouse1Pressed = mouse1Pressed,
	}, {
		Text = e("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = text,
			TextColor3 = theme.textColor,
			Font = FONT,
			BorderSizePixel = 0,
			TextSize = TEXT_SIZE,
			BackgroundColor3 = self.buttonState:map(function(state)
				return theme.buttonColor[state]
			end)
		})
	})
end

return TextButton

