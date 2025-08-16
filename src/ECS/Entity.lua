-- Entity class for ECS - Fixed version with proper ID management and component handling
---@class Entity
local Entity = {}
Entity.__index = Entity

function Entity:new()
    local self = setmetatable({}, Entity)
    self:init()
    return self
end

function Entity:init()
    self.id = nil -- Will be set by World when added
    self.components = {}
    self.world = nil -- Reference to the world this entity belongs to
    self.active = true -- Whether the entity is active
    return self
end

-- Add a component to this entity
function Entity:addComponent(component, componentName)
    if not component then
        error("Cannot add nil component to entity")
    end
    
    -- Ensure components table exists
    if not self.components then
        self.components = {}
    end
    
    -- Determine component name
    local name = componentName or component.name or component.type
    
    -- If still no name, try to derive one from the component table
    if not name then
        -- Get the component's class name if it has one
        local metatable = getmetatable(component)
        if metatable and metatable.name then
            name = metatable.name
        else
            -- Fallback to a generic name based on component structure
            if component.draw then
                name = "renderable"
            elseif component.onClick then
                name = "clickable"
            elseif component.x and component.y then
                name = "transform"
            else
                -- Last resort: use memory address
                name = "component_" .. tostring(component):match("table: (0x%x+)")
            end
        end
    end
    
    -- Ensure we have a valid name
    if not name then
        error("Component must have a name, type, or be identifiable")
    end
    
    -- Store component with proper references
    self.components[name] = component
    component.entity = self
    
    -- If component doesn't have a name set, set it now
    if not component.name then
        component.name = name
    end
    
    -- Notify world about component addition if entity is already in world
    if self.world then
        self.world:onEntityComponentAdded(self, name)
    end
    
    return self
end

-- Remove a component from this entity
function Entity:removeComponent(componentName)
    if not self.components or not self.components[componentName] then
        return self
    end
    
    local component = self.components[componentName]
    
    -- Clean up component reference
    if component then
        component.entity = nil
    end
    
    -- Remove from components table
    self.components[componentName] = nil
    
    -- Notify world about component removal if entity is in world
    if self.world then
        self.world:onEntityComponentRemoved(self, componentName)
    end
    
    return self
end

-- Get a specific component
function Entity:getComponent(componentName)
    return self.components and self.components[componentName] or nil
end

-- Check if entity has a specific component
function Entity:hasComponent(componentName)
    return self.components and self.components[componentName] ~= nil
end

-- Get all component names
function Entity:getComponentNames()
    local names = {}
    if self.components then
        for name, _ in pairs(self.components) do
            table.insert(names, name)
        end
    end
    return names
end

-- Check if entity has any of the specified components
function Entity:hasAnyComponent(componentNames)
    for _, name in ipairs(componentNames) do
        if self:hasComponent(name) then
            return true
        end
    end
    return false
end

-- Check if entity has all of the specified components
function Entity:hasAllComponents(componentNames)
    for _, name in ipairs(componentNames) do
        if not self:hasComponent(name) then
            return false
        end
    end
    return true
end

-- Set entity active/inactive
function Entity:setActive(active)
    self.active = active
    return self
end

-- Check if entity is active
function Entity:isActive()
    return self.active
end

-- Destroy the entity (remove from world)
function Entity:destroy()
    if self.world then
        self.world:removeEntity(self)
    end
end

-- Extension mechanism to create new entity types
function Entity:extend(name)
    local subclass = {}
    subclass.name = name
    subclass.__index = subclass
    setmetatable(subclass, self)
    return subclass
end

return Entity 