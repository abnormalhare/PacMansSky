Vector = class(nil,"Vector")

function Vector:init(x,y)
    self.x = x or 0
    self.y = y or 0
end

function Vector:__add(v)
    local ret = Vector(self.x+v.x, self.y+v.y)
    return ret;
end

function Vector:__sub(v)
    local ret = Vector(self.x-v.x, self.y-v.y)
    return ret;
end

function Vector:__mul(v)
    local ret = Vector(self.x, self.y)
    if type(v)=="number" then
        ret.x = ret.x * v;
        ret.y = ret.y * v;
    elseif type(v)=="table" then
        ret.x = ret.x * v.x;
        ret.y = ret.y * v.y;
    end
    return ret;
end

function Vector:__div(v)
    if type(v)=="number" then
        return self:__mul(1/v)
    elseif type(v)=="table" then
        local div = Vector(1/v.x, 1/v.y)
        return self:__mul(div)
    end
end

function Vector:length()
    return math.sqrt(self.x*self.x + self.y*self.y);
end

function Vector:dot(v)
    return self.x*v.x + self.y*v.y
end

function Vector:normalized()
    return self/self:length();
end