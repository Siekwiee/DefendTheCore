-- Base class for all systems in the ECS - Fixed version with improved entity management
---@class System
local System = {}
System.__index = System

-- Constructor for System
function System.new(class, world)
    class = class or System
    local self = setmetatable({}, class)
    self.world = world                -- Reference to the world
    self.entities = {}                -- Entities managed by this system (indexed by ID)
    self.active = true                -- Whether the system is active
    self.priority = 0                 -- Default priority (lower runs first)
    
    -- Component filters
    self.requiredComponents = {}      -- Components that entities must have (ALL)
    self.anyComponents = {}           -- At least one of these components required (ANY)
    self.excludedComponents = {}      -- Components that entities must not have (NONE)
    
    return self
end

-- Set which components are required for entities (ALL must be present)
function System:requireAll(...)
    self.requiredComponents = {...}
    return self
end

-- Set which components are required for entities (ANY one must be present)
function System:requireAny(...)
    self.anyComponents = {...}
    return self
end

-- Set which components must NOT be present
function System:excludeAll(...)
    self.excludedComponents = {...}
    return self
end

-- Check if an entity matches this system's requirements
function System:matches(entity)
    if not entity or not entity.isActive or not entity:isActive() then
        return false
    end
    
    -- Check required components (all must be present)
    for _, componentName in ipairs(self.requiredComponents) do
        if not entity:hasComponent(componentName) then
            return false
        end
    end
    
    -- Check any components (at least one must be present)
    if #self.anyComponents > 0 then
        local hasAny = false
        for _, componentName in ipairs(self.anyComponents) do
            if entity:hasComponent(componentName) then
                hasAny = true
                break
            end
        end
        if not hasAny then
            return false
        end
    end
    
    -- Check excluded components (none must be present)
    for _, componentName in ipairs(self.excludedComponents) do
        if entity:hasComponent(componentName) then
            return false
        end
    end
    
    return true
end

-- Add an entity to this system
function System:addEntity(entity)
    if not entity or not entity.id then
        return false
    end
    
    -- Only add if entity matches requirements and isn't already added
    if self:matches(entity) and not self.entities[entity.id] then
        self.entities[entity.id] = entity
        
        -- Call hook for subclasses
        if self.onEntityAdded then
            self:onEntityAdded(entity)
        end
        
        return true
    end
    return false
end

-- Remove an entity from this system
function System:removeEntity(entity)
    if not entity or not entity.id or not self.entities[entity.id] then
        return false
    end
    
    -- Call hook for subclasses
    if self.onEntityRemoved then
        self:onEntityRemoved(entity)
    end
    
    self.entities[entity.id] = nil
    return true
end

-- Get all entities in this system as a table (for iteration)
function System:getEntities()
    local entityList = {}
    for _, entity in pairs(self.entities) do
        table.insert(entityList, entity)
    end
    return entityList
end

-- Get entity count
function System:getEntityCount()
    local count = 0
    for _ in pairs(self.entities) do
        count = count + 1
    end
    return count
end

-- Check if system has a specific entity
function System:hasEntity(entity)
    return entity and entity.id and self.entities[entity.id] ~= nil
end

-- Enable the system
function System:enable()
    self.active = true
end

-- Disable the system
function System:disable()
    self.active = false
end

-- Set priority of the system (lower values run first)
function System:setPriority(priority)
    self.priority = priority or 0
    
    -- Re-sort systems in world if attached
    if self.world and self.world.sortSystems then
        self.world:sortSystems()
    end
end

-- Lifecycle methods (to be overridden by subclasses)

-- Initialize the system
function System:init()
    -- Default implementation does nothing
end

-- Update the system - process all entities
function System:update(dt)
    if not self.active then
        return
    end
    
    -- Default implementation does nothing
    -- Subclasses should override this and process their entities
end

-- Draw entities managed by this system
function System:draw()
    if not self.active then
        return
    end
    
    -- Default implementation does nothing
    -- Subclasses should override this if they need to draw
end

-- Called when the system is added to the world
function System:onAdded(world)
    -- Default implementation does nothing
end

-- Called when the system is removed from the world
function System:onRemoved()
    -- Default implementation does nothing
end

-- Clean up system resources
function System:destroy()
    -- Clear all entities
    self.entities = {}
    
    -- Clear world reference
    self.world = nil
end

-- Extension mechanism to create new system types
function System:extend(name)
    local subclass = {}
    subclass.name = name
    subclass.__index = subclass
    setmetatable(subclass, self)
    self.__index = self
    return subclass
end

-- Backward compatibility method
function System:shouldProcess(entity)
    -- Delegate to the new matches method
    return self:matches(entity)
end

return System