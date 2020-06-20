local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local Roact = load("Roact")
local t = load("t")
local ThemeContext = load("Framework/ThemeContext")
local Constants = load("Framework/Constants")

local e = Roact.createElement

local HEADER_HEIGHT = 32

local TitledSection = Roact.PureComponent:extend("TitledSection")

TitledSection.defaultProps = {
	title = "DEFAULT TITLE",
	width = UDim.new(1, 0),
	position = UDim2.new(),
	layoutOrder = 0,
	anchorPoint = Vector2.new(),
	zIndex = 1,

	[Roact.Children] = nil,
}

local ITitledSection = t.strictInterface({
	title = t.string,
	width = t.UDim,
	position = t.UDim2,
	layoutOrder = t.integer,
	anchorPoint = t.Vector2,
	zIndex = t.integer,

	[Roact.Children] = t.optional(t.table),
})

TitledSection.validateProps = function(props)
    return ITitledSection(props)
end

function TitledSection:init()
	self.contentHeight, self.updateContentHeight = Roact.createBinding(0)
	self.width, self.updateWidth = Roact.createBinding(self.props.width)
	self.size = Roact.joinBindings({
		contentHeight = self.contentHeight,
		width = self.width,
	}):map(function(mapped)
		return UDim2.new(mapped.width, UDim.new(0, mapped.contentHeight + HEADER_HEIGHT + 8))
	end)

	self.onAbsoluteContentSizeChanged = function(rbx)
		local contentHeight = rbx.AbsoluteContentSize.Y
		self.updateContentHeight(contentHeight)
	end
end

function TitledSection:render()
	local props = self.props
	local title = props.title
	local position = props.position
	local layoutOrder = props.layoutOrder
	local anchorPoint = props.anchorPoint
	local zIndex = props.zIndex

	return ThemeContext.withConsumer(function(theme)
		local colors = theme.colors

		return e("Frame", {
			BackgroundTransparency = 1,
			Position = position,
			Size = self.size,
			LayoutOrder = layoutOrder,
			AnchorPoint = anchorPoint,
			ZIndex = zIndex,
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
					Font = Constants.FONT_BOLD,
					TextSize = Constants.TEXT_SIZE_LARGE,
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
			}, {
				Roact.createFragment({
					TitledSectionUIListLayout = e("UIListLayout", {
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 4),
						[Roact.Change.AbsoluteContentSize] = self.onAbsoluteContentSizeChanged,
					}),

					TitledSectionUIPadding = e("UIPadding", {
						PaddingTop = UDim.new(0, 4),
						PaddingRight = UDim.new(0, 4),
						PaddingBottom = UDim.new(0, 4),
						PaddingLeft = UDim.new(0, 4),
					}),

					props[Roact.Children] and Roact.createFragment(props[Roact.Children]) or nil,
				})
			}),
		})
	end)
end

function TitledSection:didUpdate()
	self.updateWidth(self.props.width)
end

return TitledSection
