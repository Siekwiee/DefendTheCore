-- Base Component class for the Entity Component System
---@class Component
local Component = {}
Component.__index = Component

-- Create a new component instance
function Component:new(componentName, properties)
    local instance = {}
    setmetatable(instance, self)
    
    -- Store the component name for identification
    if componentName then
        instance.name = componentName
    end
    
    -- Copy any provided properties to the instance
    if properties and type(properties) == "table" then
        for k, v in pairs(properties) do
            instance[k] = v
        end
    end
    
    -- Initialize with constructor args
    instance:init(componentName, properties)
    return instance
end

-- Initialization function (to be overridden by child components)
function Component:init()
    -- Default initialization (to be overridden by subclasses)
end

-- Extension mechanism to create new component types
function Component:extend(name)
    local subclass = {}
    for k, v in pairs(self) do
        if k:find("__") ~= 1 then
            subclass[k] = v
        end
    end
    subclass.__index = subclass
    subclass.super = self
    subclass.name = name  -- Store the component type name
    setmetatable(subclass, self)
    return subclass
end

-- Method to update the component (to be overridden)
function Component:update(dt)
    -- Default implementation does nothing
end

-- Method to check if this component is compatible with another
function Component:isCompatibleWith(otherComponent)
    return true -- By default, all components are compatible
end

return Component 