Ghost = class(nil,"Ghost")

function Ghost:init(planet,ghosttype)
    self.planet = planet
    self.type = ghosttype
    self.escaping = false
    self.texture = res.images.retro_ghost
    self.eyetexture = res.images.retro_ghost_eyes
    self.eyeamogustexture = res.images.retro_amogus_eyes
    self.x,self.y = 0.5,0.5
    self.velX,self.velY = 0,0
    self.quads = {}
    for x=0,2 do for y=0,1 do
        table.insert(self.quads,love.graphics.newQuad(x*14,y*14,14,14,self.texture:getDimensions()))
    end end
    for y=0,3 do 
        table.insert(self.quads,love.graphics.newQuad(0,y*8,12,8,self.eyetexture:getDimensions())) 
    end
    self.rotation = 0
    self.speed = 6
    self.lastCross={x=-1,y=-1}
    self.isAmogus = false
end

function Ghost:update(dt)
    self.x = self.x+self.velX*dt
    self.y = self.y+self.velY*dt
    
    --detecting blocks next to a ghost for future calculations and stuff
    if (self.velX~=0 and math.abs(math.floor(self.x)+0.5-self.x)<0.1) or (self.velY~=0 and math.abs(math.floor(self.y)+0.5-self.y)<0.1) then
        local blocks = {
            {x=0,y=-1,rot=270,orot=90},
            {x=0,y=1,rot=90,orot=270},
            {x=-1,y=0,rot=180,orot=0},
            {x=1,y=0,rot=0,orot=180},
            passables={},dirSum=0
        }
        for i=1,4 do
            local bx,by = blocks[i].x,blocks[i].y
            local p = self.planet:isBlockPassable(self.x+bx+1,self.y+by+1,self:canPassThroughBarrier(),true)
            blocks[i].p = p
            if p then 
                table.insert(blocks.passables,i)
                blocks.dirSum = blocks.dirSum+bx+(by*4)
            end
            if #blocks.passables==4 then 
                blocks.dirSum = 42 
            end
        end

        --system of walking
        if blocks.dirSum~=0 and (self.lastCross.x~=math.floor(self.x) or self.lastCross.y~=math.floor(self.y)) then
            if self.planet.state=="frightened" and not self.isAmogus then
                local dir = blocks[blocks.passables[math.random(#blocks.passables)]]
                self.rotation = dir.rot
            else
                --selecting target
                local target = {x=0,y=0}
                local player,blinky = nil,nil
                for i,v in pairs(self.planet.entities) do
                    if v:instanceof(Pacman) then player=v end
                    --sometimes there might be no blinky so inky has to rely on someone else, unfortunately
                    if v:instanceof(Ghost) and (v.type=="blinky" or blinky==nil) then blinky=v end 
                end
                if self:isInGhostHouse() and not self.escaping then
                    target = {x=self.planet.size/2,y=self.planet.size/2-4}
                elseif self.planet.state=="scatter" and self:shouldScatter() then
                    local scpos = self.planet.size/4
                    if self.type=="blinky" then target={x=scpos,y=scpos}
                    elseif self.type=="pinky" then target={x=scpos*3,y=scpos}
                    elseif self.type=="inky" then target={x=scpos,y=scpos*3}
                    elseif self.type=="clyde" then target={x=scpos*3,y=scpos*3}
                    else target={x=scpos*2,y=scpos*2} end
                elseif self.escaping then
                    target = {x=self.planet.size/2,y=self.planet.size/2+1}
                    if self:isInGhostHouse() then self.escaping = false end
                elseif self.type=="blinky" then
                    --tries to follow pacman if not scattering
                    target = {x=math.floor(player.x)+0.5,y=math.floor(player.y)+0.5}
                elseif self.type=="pinky" then
                    --tries to predict where pacman will go if not scattering
                    local rad = math.rad(player.rotation)
                    local dx,dy = math.cos(rad)*4,math.sin(rad)*4
                    target = {x=math.floor(player.x)+0.5+dx,y=math.floor(player.y)+0.5+dy}
                elseif self.type=="inky" then
                    --goes between pacman and first binky or first ghost if not scattering
                    local rad = math.rad(player.rotation)
                    local ox,oy = math.cos(rad)*4,math.sin(rad)*4
                    local dx = (player.x+ox)-blinky.x
                    if math.abs(dx)>math.abs((player.x+self.planet.size+ox)-blinky.x) then dx = (player.x+self.planet.size+ox)-blinky.x end
                    if math.abs(dx)>math.abs((player.x-self.planet.size+ox)-blinky.x) then dx = (player.x-self.planet.size+ox)-blinky.x end
                    local dy = (player.y+oy)-blinky.y
                    if math.abs(dy)>math.abs((player.y+self.planet.size+oy)-blinky.y) then dy = (player.y+self.planet.size+oy)-blinky.y end
                    if math.abs(dy)>math.abs((player.y-self.planet.size+oy)-blinky.y) then dy = (player.y-self.planet.size+oy)-blinky.y end
                    target = {x=blinky.x+dx*2,y=blinky.y+dy*2}
                elseif self.type=="clyde" then
                    --goes to his "home" if too far from pacman or follows pacman if not scattering
                    local rx = math.min(math.abs(player.x-(self.x)),math.abs(player.x-(self.x-self.planet.size)),math.abs(player.x-(self.x+self.planet.size)))
                    local ry = math.min(math.abs(player.y-(self.y)),math.abs(player.y-(self.y-self.planet.size)),math.abs(player.y-(self.y+self.planet.size)))
                    local r = math.sqrt(rx*rx+ry*ry)
                    if r>8 then 
                        target = {x=math.floor(player.x)+0.5,y=math.floor(player.y)+0.5}
                    else
                        local scpos = self.planet.size/4
                        target={x=scpos*3,y=scpos*3} 
                    end 
                elseif self.type=="cringy" then
                    --picks random path
                    local randX = love.math.random(0,self.planet.size);
                    local randY = love.math.random(0,self.planet.size);
                    target = {x=randX,y=randY}
                elseif self.type=="kinky" then
                    --focuses on the point right behind of pacman (what the fuck bro)
                    local rad = math.rad(player.rotation)
                    local dx,dy = math.cos(rad)*3,math.sin(rad)*3
                    target = {x=math.floor(player.x)+0.5-dx,y=math.floor(player.y)+0.5-dy}
                elseif self.type=="liney" then
                    --goes forward whenever possible
                    local rad = math.rad(self.rotation)
                    local dx,dy = math.cos(rad)*4,math.sin(rad)*4
                    target = {x=math.floor(self.x)+0.5+dx,y=math.floor(self.y)+0.5+dy}
                elseif self.type=="bob" then
                    --bob is socially awkward. he avoids everyone :(
                    local closestGhostDist = 9999999
                    local closestGhost = nil
                    local dirX, dirY = 0,0

                    for i,v in pairs(self.planet.entities) do
                        if v~=self then

                            local vX = v.x-self.x
                            local vXp1 = v.x-(self.x-self.planet.size)
                            local vXp2 = v.x-(self.x+self.planet.size)
                            if math.abs(vX) > math.abs(vXp1) then vX = vXp1 end
                            if math.abs(vX) > math.abs(vXp2) then vX = vXp2 end

                            local vY = v.y-self.y
                            local vYp1 = v.y-(self.y-self.planet.size)
                            local vYp2 = v.y-(self.y+self.planet.size)
                            if math.abs(vY) > math.abs(vYp1) then vY = vYp1 end
                            if math.abs(vY) > math.abs(vYp2) then vY = vYp2 end

                            local r = math.sqrt(vX*vX+vY*vY)
                            if r<closestGhostDist then
                                closestGhostDist = r
                                closestGhost = v
                                dirX = vX/r;
                                dirY = vY/r;
                            end
                        end 
                    end

                    target = {x=self.x-dirX, y=self.y-dirY}
                end

                -- determing which way is way better for being a ghost's way
                local dir = {distance=133337,id=blocks.passables[1]}
                for i=1,#blocks.passables do
                    local bl = blocks[blocks.passables[i]]
                    local x = math.min(math.abs(target.x-(self.x+bl.x)),math.abs(target.x-(self.x-self.planet.size+bl.x)),math.abs(target.x-(self.x+self.planet.size+bl.x)))
                    local y = math.min(math.abs(target.y-(self.y+bl.y)),math.abs(target.y-(self.y-self.planet.size+bl.y)),math.abs(target.y-(self.y+self.planet.size+bl.y)))
                    local r = math.sqrt(x*x+y*y)
                    if r<dir.distance and self.rotation~=bl.orot then
                        dir = {distance=r,id=blocks.passables[i]}
                    end
                end
                self.rotation = blocks[dir.id].rot
            end
            self.lastCross = {x=math.floor(self.x),y=math.floor(self.y)}
        end
    end
    
    -- setting velocity
    local sD = self.planet.state=="frightened" and (self.isAmogus and 0.3 or 2) or 1
    if self.escaping then 
        sD = 0.5 
    elseif self.planet:getBlock(self.x+0.5,self.y+0.5)==20 then 
        sD = 3 
    end
    
    self.velX = (self.rotation==0 and 1 or (self.rotation==180 and -1 or 0)) *(self.speed/sD)
    self.velY = (self.rotation==90 and 1 or (self.rotation==270 and -1 or 0)) *(self.speed/sD)
    
    -- fixing the position of the ghost to center of the tiles line
    if self.velX~=0 and self.velY==0 then 
        self.y = math.floor(self.y)+0.5
    end
    if self.velX==0 and self.velY~=0 then 
        self.x = math.floor(self.x)+0.5
    end
end

function Ghost:draw()
    love.graphics.setColorOld(255,255,255)
    if self.planet.state=="death" and self.planet.stateCounter.death>1 then return end
    local quad = ((self.planet.state=="frightened" or self.planet.state=="eating") and 2 or 0)
    if quad==2 and 7-self.planet.stateCounter.frightened<2 then 
        quad = 2+(math.floor((7-self.planet.stateCounter.frightened)*4)%2)*2 
    end
    if self.isAmogus then quad = 0 end
    quad = quad + (math.floor(Game.time*8)%2+1)
    if not self.escaping then
        if quad<3 then
            love.graphics.setColorOld(self:getColor())
        end
        love.graphics.draw(self.texture,self.quads[quad],self.x*8,self.y*8,0,1,1,7,7)
    end
    love.graphics.setColorOld(255,255,255)
    if not (self.planet.state=="frightened" or self.planet.state=="eating") or self.escaping or self.isAmogus then
        local eyequad = self.rotation==180 and 7 or (self.rotation==0 and 8 or (self.rotation==270 and 9 or 10))
        local eyestexture = self.isAmogus and self.eyeamogustexture or self.eyetexture
        love.graphics.draw(eyestexture,self.quads[eyequad],self.x*8,self.y*8,0,1,1,6,6)
    end 
end

function Ghost:isInGhostHouse()
    local cen = self.planet.size/2+0.5
    if self.x>cen-4.6 and self.x<cen+4.6 and self.y>cen-2.6 and self.y<cen+2.6 then 
        return true
    else return false end
end

function Ghost:canPassThroughBarrier()
    if self.escaping then return true end
    if self:isInGhostHouse() then
        for i,v in pairs(self.planet.entities) do if v==self then
            --make it so that all ghosts leave after collecting 60 pellets
            return self.planet.pellets.collected>math.max((i-2) * 60.0/(#self.planet.entities-1),0)
        end end
    end
    return false
end

function Ghost:shouldScatter()
    if self.isAmogus then return false end
    local scatterTypes = {"blinky", "inky", "pinky", "clyde"};
    for _,scatterType in pairs(scatterTypes) do
        if scatterType == self.type then return true end
    end
    return false
end

function Ghost:getColor()
    local colors = {
        blinky = {255,0,0},
        pinky = {255,184,222},
        inky = {0,255,222},
        clyde = {237,155,0},
        cringy = {50,200,50},
        kinky = {128,0,128},
        liney = {0,100,200},
        bob = {69,42,0}
    }
    return colors[self.type] or {255,255,255}
end