---@class Object
Object = {}
Object.__index = Object

function Object:init()
end

-- Create a new class that inherits from the current object
function Object:extend()
    local cls = {}
    for k, v in pairs(self) do
        cls[k] = v
    end
    cls.__index = cls
    setmetatable(cls, self)
    return cls
end

-- Check if the object is an instance of the given class
function Object:is(T)
    local mt = getmetatable(self)
    while mt do 
        if mt == T then
            return true
        end
        mt = getmetatable(mt)
    end
    return false
end

-- Create a new instance of the object: MyObject(initialization_parameters, ...) calls the init method
function Object:__call(...)
    local obj = setmetatable({}, self)
    obj:init(...)
    return obj
end
