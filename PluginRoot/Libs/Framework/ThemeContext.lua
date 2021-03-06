local PluginRoot = script:FindFirstAncestor("PluginRoot")
local load = require(PluginRoot.Loader).load

local Roact = load("Roact")
local Oyrc = load("Oyrc")

local e = Roact.createElement

local ThemeContext = Roact.createContext()

local ThemeController = Roact.Component:extend("ThemeController")

function ThemeController:init()
	self.state = {
		theme = self.props.theme,
	}
end

function ThemeController:didMount()
	self.unsubscribe = self.state.theme:subscribe(function()
		self:setState({})
	end)
end

function ThemeController:render()
	return e(ThemeContext.Provider, {
		value = { colors = self.state.theme:getColors() },
	}, self.props[Roact.Children])
end

function ThemeController:willUnmount()
	self.unsubscribe()
end

local function withController(props, children)
	return e(ThemeController, props, children)
end

local function withConsumer(render)
	return e(ThemeContext.Consumer, {
		render = function(theme)
			return render(theme)
		end
	})
end

local function connect(component, mapValueToProps)
	local newComponent = Roact.PureComponent:extend("ThemeContextConnected" .. tostring(component))

	function newComponent:render()
		return withConsumer(function(theme)
			local props = self.props
			props = Oyrc.Dictionary.join(props, mapValueToProps(theme))
			return e(component, props)
		end)
	end

	return newComponent
end

return {
	withController = withController,
	withConsumer = withConsumer,
	connect = connect,
}
