local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local Roact = load("Roact")
local t = load("t")
local Oyrc = load("Oyrc")
local ThemeContext = load("Framework/ThemeContext")

local e = Roact.createElement

-- TODO: Use a constants module for this.
local HEADER_HEIGHT = 32
local BOLD_FONT = Enum.Font.SourceSansBold
local TITLE_TEXT_SIZE = 18

local TitledSection = Roact.PureComponent:extend("TitledSection")

TitledSection.defaultProps = {
	title = "DEFAULT TITLE",
	width = UDim.new(1, 0),
	position = UDim2.new(),
	layoutOrder = 0,
}

local ITitledSection = t.interface({
	title = t.string,
	width = t.UDim,
	position = t.UDim2,
	layoutOrder = t.integer,
})

TitledSection.validateProps = function(props)
    return ITitledSection(props)
end

function TitledSection:init()
	self.contentHeight, self.updateContentHeight = Roact.createBinding(0)
end

function TitledSection:render()
	local props = self.props
	local title = props.title
	local width = props.width
	local position = props.position
	local layoutOrder = props.layoutOrder

	return ThemeContext.withConsumer(function(theme)
		local colors = theme.colors

		local children = props[Roact.Children] ~= nil and Oyrc.Dictionary.join(props[Roact.Children], {
			TitledSectionUIListLayout = e("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 4),
				[Roact.Change.AbsoluteContentSize] = function(rbx)
					local contentHeight = rbx.AbsoluteContentSize.Y
					self.updateContentHeight(contentHeight)
				end,
			}),

			TitledSectionUIPadding = e("UIPadding", {
				PaddingTop = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft = UDim.new(0, 4),
			})
		}) or nil

		return e("Frame", {
			BackgroundTransparency = 1,
			Position = position,
			Size = self.contentHeight:map(function(height)
				return UDim2.new(width, UDim.new(0, height + HEADER_HEIGHT + 8))
			end),
			LayoutOrder = layoutOrder,
		}, {
			Header = e("Frame", {
				Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
				BackgroundColor3 = colors.TitledSectionTitleBackground.Default,
				BorderSizePixel = 0,
			}, {
				TitleText = e("TextLabel", {
					BackgroundTransparency = 1,
					Text = title,
					Position = UDim2.new(0, 8, 0, 0),
					Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
					Font = BOLD_FONT,
					TextSize = TITLE_TEXT_SIZE,
					TextXAlignment = Enum.TextXAlignment.Left,
					TextColor3 = colors.MainText.Default,
					TextTruncate = Enum.TextTruncate.AtEnd,
				}),
			}),

			Content = e("Frame", {
				BackgroundColor3 = colors.TitledSectionContentBackground.Default,
				Size = UDim2.new(1, 0, 1, -HEADER_HEIGHT),
				Position = UDim2.new(0, 0, 0, HEADER_HEIGHT),
				BorderSizePixel = 0,
			}, children)
		})
	end)
end

return TitledSection
