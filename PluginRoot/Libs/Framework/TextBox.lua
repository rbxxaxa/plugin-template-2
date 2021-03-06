local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local RunService = game:GetService("RunService")

local TextService = game:GetService("TextService")

local Roact = load("Roact")
local t = load("t")
local ButtonDetector = load("Framework/ButtonDetector")
local ThemeContext = load("Framework/ThemeContext")
local Constants = load("Framework/Constants")
local BorderedFrame = load("Framework/BorderedFrame")

local e = Roact.createElement

local TextBox = Roact.PureComponent:extend("TextBox")

TextBox.defaultProps = {
	size = UDim2.new(0, 100, 0, 100),
	position = UDim2.new(),
	layoutOrder = 0,
	anchorPoint = Vector2.new(),
	zIndex = 1,
	inputText = "",
	placeholderText = "",
	disabled = false,
	focused = nil,
	focusLost = nil,
	textXAlignment = "Left",

	theme = nil, -- Injected by ThemeContext.connect
}

local ITextBox = t.strictInterface({
	size = t.optional(t.UDim2),
	position = t.optional(t.UDim2),
	layoutOrder = t.integer,
	anchorPoint = t.Vector2,
	zIndex = t.integer,
	inputText = t.string,
	placeholderText = t.string,
	disabled = t.boolean,
	focused = t.optional(t.callback),
	focusLost = t.optional(t.callback),
	textXAlignment = t.literal("Left", "Center", "Right"),

	theme = t.table,
})

TextBox.validateProps = function(props)
	return ITextBox(props)
end

function TextBox:init()
	self.textBoxRef = Roact.createRef()
	self.clipperRef = Roact.createRef()

	self.focused, self.updateFocused = Roact.createBinding(false)
	self.buttonState, self.updateButtonState = Roact.createBinding("Default")
	self.text, self.updateText = Roact.createBinding(self.props.inputText)
	self.textBoxPosition, self.updateTextBoxPosition = Roact.createBinding(UDim2.new())
	self.disabled, self.updateDisabled = Roact.createBinding(self.props.disabled)
	self.placeholderText, self.updatePlaceholderText = Roact.createBinding(self.props.placeholderText)
	self.appearanceState = Roact.joinBindings({
		disabled = self.disabled,
		buttonState = self.buttonState,
		focused = self.focused,
	}):map(function(joined)
		if joined.disabled then
			return "Disabled"
		elseif joined.focused then
			return "Focused"
		elseif joined.buttonState == "Hovered" then
			return "Hovered"
		else
			return "Default"
		end
	end)
	self.textInTextLabel = Roact.joinBindings({
		placeholderText = self.placeholderText,
		text = self.text,
	}):map(function(joined)
		if joined.text == "" then
			return joined.placeholderText
		else
			return joined.text
		end
	end)
	self.backgroundColor = self.appearanceState:map(function(appearanceState)
		local colors = self.props.theme.colors
		return colors.InputFieldBackground[appearanceState]
	end)
	self.borderColor = self.appearanceState:map(function(appearanceState)
		local colors = self.props.theme.colors
		return colors.InputFieldBorder[appearanceState]
	end)
	self.font = self.text:map(function(text)
		return text == "" and Constants.FONT_ITALIC or Constants.FONT_DEFAULT
	end)
	self.onCursorPositionChanged = function(rbx)
		--[[
			This is delayed by a frame because clipping depends on a bunch of properties
			and these properties might be updated after CursorPosition is updated.

			In my testing, this delay makes no visual difference.
		]]
		RunService.RenderStepped:Wait()
		self:updateClipping()
	end
	self.onFocusLost = function(rbx, _, inputThatCausedLostFocus)
		self.updateFocused(false)
		local text = rbx.Text
		if self.props.focusLost then
			local cause
			if inputThatCausedLostFocus.KeyCode == Enum.KeyCode.Escape then
				cause = "Cancelled"
			elseif inputThatCausedLostFocus.KeyCode == Enum.KeyCode.Return then
				cause = "Submitted"
			else
				cause = "ClickedOut"
			end
			local replacementText = self.props.focusLost(text, cause)
			if replacementText then
				self.updateText(replacementText)
			end
		end
	end
	self.onFocused = function(rbx)
		self.updateFocused(true)
		local text = rbx.Text
		if self.props.focused then
			local replacementText = self.props.focused(text)
			if replacementText then
				self.updateText(replacementText)
			end
		end
		rbx.CursorPosition = #rbx.Text + 1
		rbx.SelectionStart = 1
	end
	self.onTextChanged = function(rbx)
		self.updateText(rbx.Text)
	end
end

function TextBox:render()
	local props = self.props
	local size = props.size
	local position = props.position
	local layoutOrder = props.layoutOrder
	local anchorPoint = props.anchorPoint
	local zIndex = props.zIndex
	local disabled = props.disabled
	local placeholderText = props.placeholderText
	local textXAlignment = props.textXAlignment
	local theme = self.props.theme

	local colors = theme.colors

	-- TODO: make me modal
	return e(ButtonDetector, {
		size = size,
		position = position,
		layoutOrder = layoutOrder,
		anchorPoint = anchorPoint,
		zIndex = zIndex,
		buttonStateChanged = self.updateButtonState,
		disabled = disabled,
	}, {
		Background = e(BorderedFrame, {
			size = UDim2.new(1, 0, 1, 0),
			backgroundColorBinding = self.backgroundColor,
			borderColorBinding = self.borderColor,
			borderStyle = "Round",
		}),
		-- We fudge some offsets/paddings by -1 so that the cursor will always get rendered in the box.
		Clipper = e("Frame", {
			Size = UDim2.new(1, -14, 1, 0),
			Position = UDim2.new(0, 6, 0, 0),
			BackgroundTransparency = 1,
			ClipsDescendants = true,
			[Roact.Ref] = self.clipperRef,
			ZIndex = 2,
		}, {
			Padding = e("UIPadding", {
				PaddingLeft = UDim.new(0, 1),
				PaddingRight = UDim.new(0, 1),
			}),

			TextLabel = disabled and e("TextLabel", {
				Text = self.textInTextLabel,
				BackgroundTransparency = 1,
				TextWrapped = false,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment[textXAlignment],
				Position = UDim2.new(0, 0, 0, 0),
				TextColor3 = colors.MainText.Disabled,
				Font = self.font,
				TextSize = Constants.TEXT_SIZE_DEFAULT,
			}),

			TextBox = e("TextBox", {
				Text = self.text,
				Visible = disabled == false,
				BackgroundTransparency = 1,
				TextWrapped = false,
				ClearTextOnFocus = false,
				PlaceholderText = placeholderText,
				Size = UDim2.new(1, 0, 1, 0),
				TextXAlignment = Enum.TextXAlignment[textXAlignment],
				Position = self.textBoxPosition,
				TextColor3 = colors.MainText.Default,
				PlaceholderColor3 = colors.DimmedText.Default,
				Font = self.font,
				TextSize = Constants.TEXT_SIZE_DEFAULT,
				[Roact.Change.CursorPosition] = self.onCursorPositionChanged,
				[Roact.Ref] = self.textBoxRef,
				[Roact.Event.FocusLost] = self.onFocusLost,
				[Roact.Event.Focused] = self.onFocused,
				[Roact.Change.Text] = self.onTextChanged,
			}),
		}),
	})
end

function TextBox:didUpdate(prevProps, prevState)
	--[[
		If the text box is disabled, then onTextChange (which calls updateText) will never get called.
		We do that here, otherwise the font of the text will never change.
	]]
	if not self.focused:getValue() then
		self.updateText(self.props.inputText)
	end
	self.updateDisabled(self.props.disabled)
	if self.props.disabled ~= prevProps.disabled then
		if self.props.disabled then
			self.textBoxRef:getValue():ReleaseFocus()
		end
	end
	self.updatePlaceholderText(self.props.placeholderText)
end

function TextBox:updateClipping()
	local clipper = self.clipperRef:getValue()
	local textBox = self.textBoxRef:getValue()

	local newPosition
	if self.props.textXAlignment == "Left" then
		if textBox.CursorPosition < 0 then
			newPosition = UDim2.new(0, 0, 0, 0)
		else
			local textUpToCursor = string.sub(textBox.Text, 1, textBox.CursorPosition-1)
			local textSize = TextService:GetTextSize(textUpToCursor, Constants.TEXT_SIZE_DEFAULT,
				Constants.FONT_DEFAULT, Vector2.new(9999, 9999))
			local clipperLeft = clipper.AbsolutePosition.X
			local clipperRight = clipper.AbsolutePosition.X + clipper.AbsoluteSize.X
			local cursorX = textBox.AbsolutePosition.X + textSize.X

			if cursorX >= clipperLeft and cursorX <= clipperRight - 2 then
				newPosition = self.textBoxPosition:getValue()
			elseif cursorX < clipperLeft then
				newPosition = UDim2.new(0, -textSize.X, 0, 0)
			else
				newPosition = UDim2.new(0, clipper.AbsoluteSize.X - textSize.X - 2, 0, 0)
			end
		end
	else
		-- Clipping not implemented for center- (is it even possible) and right-aligned text.
		-- TODO: Revisit this, possibly.
		newPosition = UDim2.new(0, 0, 0, 0)
	end

	self.updateTextBoxPosition(newPosition)
end

return ThemeContext.connect(TextBox, function(theme)
	return {theme = theme}
end)
