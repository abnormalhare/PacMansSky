-- simple wrapup for class-like system

function class(base,name)
    local c = {}    -- new class reference
    if type(base) == 'table' then
        -- copying the base class
        for i,v in pairs(base) do
            c[i] = v
        end
        c._base = base
    end
    c.__index = c
    c._name = name

    -- check if given object is a type of given class
    c.instanceof = function(self, class)
    local m = getmetatable(self)
    while m do 
        if m == class then return true end
            m = m._base
        end
        return false
    end

    -- constructor
    local mt = {}
    mt.__call = function(class_tbl, ...)
    local obj = {}
    setmetatable(obj,c)
    if c.init then c.init(obj,...) end
        return obj
    end

    setmetatable(c, mt)
    return c
end

function isClass(object)
    if object._base then return true
    else return false end
end