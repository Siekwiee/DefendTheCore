-- ECS World - Fixed version with proper entity management and system notifications
local World = {}

function World:new()
    local world = {}
    setmetatable(world, self)
    self.__index = self

    world.entities = {}
    world.systems = {}
    world.nextEntityId = 1
    
    return world
end

function World:addEntity(entity)
    if not entity then
        error("Cannot add nil entity to world")
    end
    
    -- Assign unique ID
    entity.id = self.nextEntityId
    self.nextEntityId = self.nextEntityId + 1
    
    -- Add to entities list
    table.insert(self.entities, entity)
    entity.world = self
    
    -- Register entity with appropriate systems
    self:registerEntityWithSystems(entity)
    
    return entity
end

function World:removeEntity(entity)
    if not entity then
        return
    end
    
    -- Unregister entity from all systems
    for _, system in pairs(self.systems) do
        if system.removeEntity then
            system:removeEntity(entity)
        end
    end
    
    -- Remove entity from world
    for i, e in ipairs(self.entities) do
        if e.id == entity.id then
            table.remove(self.entities, i)
            break
        end
    end
    
    -- Clean up entity reference
    entity.world = nil
end

function World:addSystem(system)
    if not system then
        error("Cannot add nil system to world")
    end
    
    table.insert(self.systems, system)
    system.world = self
    
    -- Call system initialization if available
    if system.init then
        system:init()
    end
    
    -- Register all existing entities with the new system
    for _, entity in ipairs(self.entities) do
        self:tryRegisterEntityWithSystem(entity, system)
    end
    
    -- Sort systems by priority
    self:sortSystems()
    
    return system
end

function World:removeSystem(system)
    for i, s in ipairs(self.systems) do
        if s == system then
            -- Call cleanup if available
            if s.destroy then
                s:destroy()
            end
            table.remove(self.systems, i)
            system.world = nil
            break
        end
    end
end

function World:update(dt)
    -- Update all active systems
    for _, system in pairs(self.systems) do
        if system.active ~= false and system.update then
            system:update(dt)
        end
    end
end

function World:draw()
    -- Draw all active systems that have draw methods
    for _, system in pairs(self.systems) do
        if system.active ~= false and system.draw then
            system:draw()
        end
    end
end

-- Register entity with all appropriate systems
function World:registerEntityWithSystems(entity)
    for _, system in pairs(self.systems) do
        self:tryRegisterEntityWithSystem(entity, system)
    end
end

-- Try to register an entity with a specific system
function World:tryRegisterEntityWithSystem(entity, system)
    if not entity or not system then
        return false
    end
    
    -- Check if system has matching requirements
    if system.matches then
        if system:matches(entity) and system.addEntity then
            system:addEntity(entity)
            return true
        end
    elseif system.shouldProcess then
        -- Fallback for systems using old shouldProcess method
        if system:shouldProcess(entity) and system.addEntity then
            system:addEntity(entity)
            return true
        end
    elseif system.addEntity then
        -- Systems without filtering - add all entities
        system:addEntity(entity)
        return true
    end
    
    return false
end

-- Called when a component is added to an entity
function World:onEntityComponentAdded(entity, componentName)
    -- Re-evaluate entity with all systems
    for _, system in pairs(self.systems) do
        if system.matches and system:matches(entity) then
            -- Entity now matches system requirements
            if not system.entities or not system.entities[entity.id] then
                if system.addEntity then
                    system:addEntity(entity)
                end
            end
        end
    end
end

-- Called when a component is removed from an entity
function World:onEntityComponentRemoved(entity, componentName)
    -- Re-evaluate entity with all systems
    for _, system in pairs(self.systems) do
        if system.matches and not system:matches(entity) then
            -- Entity no longer matches system requirements
            if system.entities and system.entities[entity.id] then
                if system.removeEntity then
                    system:removeEntity(entity)
                end
            end
        end
    end
end

-- Sort systems by priority (lower priority runs first)
function World:sortSystems()
    table.sort(self.systems, function(a, b)
        local priorityA = a.priority or 0
        local priorityB = b.priority or 0
        return priorityA < priorityB
    end)
end

-- Get entity by ID
function World:getEntity(id)
    for _, entity in ipairs(self.entities) do
        if entity.id == id then
            return entity
        end
    end
    return nil
end

-- Get all entities with specific component(s)
function World:getEntitiesWith(...)
    local componentNames = {...}
    local matchingEntities = {}
    
    for _, entity in ipairs(self.entities) do
        if entity:hasAllComponents(componentNames) then
            table.insert(matchingEntities, entity)
        end
    end
    
    return matchingEntities
end

-- Get all entities with any of the specified components
function World:getEntitiesWithAny(...)
    local componentNames = {...}
    local matchingEntities = {}
    
    for _, entity in ipairs(self.entities) do
        if entity:hasAnyComponent(componentNames) then
            table.insert(matchingEntities, entity)
        end
    end
    
    return matchingEntities
end

function World:destroy()
    print("Destroying world...")
    
    -- Clean up all systems
    for _, system in pairs(self.systems) do
        if system.destroy then
            system:destroy()
        end
    end
    
    -- Clear all entities
    for _, entity in ipairs(self.entities) do
        entity.world = nil
    end
    
    -- Clear references
    self.entities = {}
    self.systems = {}
    self.nextEntityId = 1
end

return World 