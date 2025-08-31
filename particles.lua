ParticleSystem = class(null, "ParticleSystem")

function ParticleSystem:init()
    self.particles = {}
end

function ParticleSystem:addParticle(particle)
    table.insert(self.particles,particle)
end

function ParticleSystem:addRocketParticle(spacman,smoke,addAng)
    local speed=spacman.speed*(love.math.random()*0.1)
    local rotRad = math.rad(spacman.rotation-90 + (smoke and 0 or (love.math.random()*40-20)))

    local particle = {
        x=spacman.x-math.cos(rotRad)*0.04,
        y=spacman.y-math.sin(rotRad)*0.04,
        rotation=love.math.random()*360,
        rotSpeed=love.math.random(3,12),
        lifetime=0,
        deadtime=love.math.random()*0.5+0.2
    }

    if smoke then
        particle.colorStart={200,200,200,128}
        particle.colorEnd={255,255,255,0}
        particle.sizeStart=1
        particle.sizeEnd=1.5
        rotRad = rotRad + math.rad(addAng)
    end

    particle.velX = -math.cos(rotRad)*speed+spacman.velX/2
    particle.velY = -math.sin(rotRad)*speed+spacman.velY/2

    if not smoke then
        particle.colorStart={255,0,0,128}
        particle.colorEnd={255,255,50,0}
        particle.sizeStart=0.5
        particle.sizeEnd=3
    else
        
    end

    self:addParticle(particle)
end

function ParticleSystem:update(dt)
    for i=#self.particles,1,-1 do
        local p = self.particles[i]
        p.rotation = p.rotation+p.rotSpeed
        if p.rotation>180 then 
            p.rotation = p.rotation - 360 
        elseif p.rotation<180 then 
            p.rotation = p.rotation + 360 
        end
        p.x,p.y = p.x+p.velX,p.y+p.velY
        p.lifetime = p.lifetime+dt
        if p.lifetime>p.deadtime then 
            table.remove(self.particles,i) 
        end
    end
end

function ParticleSystem:draw(dt)
    for i,v in ipairs(self.particles) do
        love.graphics.push()
        love.graphics.translate(v.x,v.y)
        local lt = (v.lifetime/v.deadtime)
        love.graphics.scale(v.sizeStart+(v.sizeEnd-v.sizeStart)*lt);
        local r = v.colorStart[1]+(v.colorEnd[1]-v.colorStart[1])*lt;
        local g = v.colorStart[2]+(v.colorEnd[2]-v.colorStart[2])*lt;
        local b = v.colorStart[3]+(v.colorEnd[3]-v.colorStart[3])*lt;
        local a = v.colorStart[4]+(v.colorEnd[4]-v.colorStart[4])*lt;
        love.graphics.setColorOld(r,g,b,a)
        love.graphics.rotate(math.rad(v.rotation))
        love.graphics.rectangle("fill",-0.012,-0.008,0.024,0.016)
        love.graphics.rectangle("fill",-0.008,-0.012,0.016,0.024)
        love.graphics.pop()
    end
end