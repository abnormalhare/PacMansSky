-- pacman (planet player character)

Pacman = class(nil,"Pacman")

function Pacman:init(planet)
    self.planet = planet
    self.texture = res.images.pacman
    self.x,self.y = 0.5,0.5
    self.velX,self.velY = 0,0
    self.quads = {}
    for y=0,6 do for x=0,1 do
        table.insert(self.quads,love.graphics.newQuad(x*15,y*15,15,15,self.texture:getDimensions()))
    end end
    self.rotation = 0
    self.wantedDir = {x=1,y=0}
    self.speed = 6
    self.eatSound = res.sounds["retro-eat1"]
    self.ghostEatSound = res.sounds["retro-eatghost"]
    self.ghostCombo = 0
end

function Pacman:update(dt)
    self.x = self.x+self.velX*dt
    self.y = self.y+self.velY*dt

    --managing input
    if Input.isKeyTyped("left") then self.wantedDir = {x=-1,y=0} end
    if Input.isKeyTyped("right") then self.wantedDir = {x=1,y=0} end
    if Input.isKeyTyped("down") then self.wantedDir = {x=0,y=1} end
    if Input.isKeyTyped("up") then self.wantedDir = {x=0,y=-1} end

    --system of walking
    if self.planet:isBlockPassable(self.x+self.wantedDir.x+1,self.y+self.wantedDir.y+1) then
        self.rotation = math.deg(math.atan2(self.wantedDir.y,self.wantedDir.x))
        if self.rotation<0 then self.rotation = self.rotation+360 end
    end

    -- setting velocity
    self.velX = (self.rotation==0 and 1 or (self.rotation==180 and -1 or 0)) *self.speed
    self.velY = (self.rotation==90 and 1 or (self.rotation==270 and -1 or 0)) *self.speed

    -- wall hit detection
    local rotrad = math.rad(self.rotation)
    if not self.planet:isBlockPassable(self.x+math.cos(rotrad)*0.51+1,self.y+math.sin(rotrad)*0.51+1) then
        self.velX,self.velY = 0,0
        self.x,self.y = math.floor(self.x)+0.5,math.floor(self.y)+0.5
    end

    -- fixing the position of the player to the center of the tiles line
    if self.velX~=0 and self.velY==0 then 
        local dir = math.floor(self.y)+0.5
        if math.abs(dir-self.y)<0.1 then self.y = dir
        else self.velY = ((dir-self.y)>0 and 1 or -1)*self.speed end
    end
    if self.velX==0 and self.velY~=0 then 
        local dir = math.floor(self.x)+0.5
        if math.abs(dir-self.x)<0.1 then self.x = dir
        else self.velX = ((dir-self.x)>0 and 1 or -1)*self.speed end
    end
  
    -- colliding with ghosts
    for k,v in pairs(self.planet.entities) do
        if v:instanceof(Ghost) and not v.escaping then
            if math.floor(v.x)==math.floor(self.x) and math.floor(v.y)==math.floor(self.y) then
                if v.isAmogus then
                    self.planet.state = "death"
                elseif self.planet.state == "frightened" then
                    v.escaping=true
                    self.planet.state = "eating"
                    self.ghostEatSound:play()
                    v.x,v.y = self.x,self.y
                    --only going with powers of two to the fourth ghost
                    if self.ghostCombo < 16 then
                        self.ghostCombo = self.ghostCombo*2
                    else self.ghostCombo = self.ghostCombo+ 16 end
                    Game.points = Game.points + (self.ghostCombo)*100
                    Game.spacman:addFuelPellet(25)
                elseif self.planet.state ~= "eating" then
                    self.planet.state = "death"
                end
            end
        end
    end

    -- Interacting with map blocks
    local blockX, blockY = self.x+1, self.y+1
    local standBlock = self.planet:getBlock(blockX, blockY)
    if standBlock==Planet.tiles.PELLET then
        self.planet:setBlock(blockX, blockY,0)
        Game.points = Game.points+10
        Game.spacman:addFuelPellet(1)
        self.eatSound:play()
        if self.eatSound==res.sounds["retro-eat1"] then self.eatSound = res.sounds["retro-eat2"]
        else self.eatSound = res.sounds["retro-eat1"] end
    elseif standBlock==Planet.tiles.POWER then
        self.planet:setBlock(blockX, blockY,0)
        self.planet.state = "frightened"
        self.ghostCombo = 1
        Game.points = Game.points+100
        self.planet.stateCounter.frightened=0
    elseif standBlock==Planet.tiles.CHERRY then
        self.planet:collectCherry(blockX,blockY)
        Game.points = Game.points+500
    elseif standBlock==Planet.tiles.LAUNCHER then
        Game.state="starting"
        self.planet.state = "finished"
        self.planet.stateCounter.finished = 5
        self.planet.stateCounter.finished = 0
        self.x,self.y = math.floor(self.x)+0.5,math.floor(self.y)+0.5
        res.sounds.eject:play()
    end
end

function Pacman:draw()
    local quad = 4
    if self.spacemode then 
        quad=2
    elseif self.planet.state=="start1" or self.planet.state=="start2" then 
        quad=1
    elseif self.planet.state=="death" then
        local ds = self.planet.stateCounter.death
        if ds>1 then 
            if self.rotation~=270 then self.rotation=270 end
            quad=3
        end
        if ds>1.5 and ds<3.2 then
            quad = 5+math.floor(((ds-1.5)/1.7)*10)
        end
        if ds>3.2 then
            if self.rotation~=0 then self.rotation=0 end
            return
        end
    elseif self.velX~=0 or self.velY~=0 then
        local id = 1+math.floor(Game.time*16)%4
        if id>1 and id<4 then quad = 6-id
        else quad=id end
    end
    love.graphics.draw(self.texture,self.quads[quad],self.x*8,self.y*8,math.rad(self.rotation),1,1,7.5,7.5)
    if self.planet.state == "eating" then
        local score = ((self.ghostCombo)*100).."!"
        local w,h = Game.guifont:getWidth(score),Game.guifont:getHeight()
        love.graphics.setFont(Game.guifont)
        love.graphics.setColorOld(0,255,222)
        love.graphics.printf(score,self.x*8,self.y*8,1000,"left",0,1,1,w/2,h/2+8)
    end
    if self.planet.state == "start2" then
        local text = "READY!"
        local w,h = Game.guifont:getWidth(text),Game.guifont:getHeight()
        love.graphics.setFont(Game.guifont)
        love.graphics.setColorOld(237,155,0)
        love.graphics.printf(text,self.planet.size*4-20,(self.planet.size)*4+24,1000,"left",0,2,2)
    end
end





-- spacman (spaceship player character)

Spacman = class(nil,"Spacman")

function Spacman:init()
    self.x,self.y = 0,0
    self.velX,self.velY = 0,0
    self.rotation = 90
    self.drawRot = 90
    self.rotspeed = 125
    self.weakness=50
    self.texture = res.images.spaceman
    self.speed=0.025
    self.particles = {}
    self.rocketsound = res.sounds.rocket
    self.rocketsound:pause()
    self.rocketsound:setLooping(true)
    self.blocked = false
    self.fuel = 0
    self.noFuelTime = 0

    self.particles = ParticleSystem();
end

function Spacman:update(dt)
    if self.rotation<-180 then self.rotation=self.rotation+360; self.drawRot=self.drawRot+360 end
    if self.rotation>180 then self.rotation=self.rotation-360; self.drawRot=self.drawRot-360 end
    self.drawRot = self.drawRot+(self.rotation-self.drawRot)/10
    local velAngle = math.atan2(self.velY,self.velX)
    local targetVector = {x=math.cos(velAngle)*self.speed/10,y=math.sin(velAngle)*self.speed/20}
    if math.abs(self.velX)<math.abs(targetVector.x) then targetVector.x=self.velX end
    if math.abs(self.velY)<math.abs(targetVector.y) then targetVector.y=self.velY end
    self.rocketsound:pause()
    if not self.blocked and Game.state=="space" then
        local particleSet = false
        if Input.isKeyPressed("up") then
            love.audio.play(self.rocketsound)
            local rotRad = math.rad(self.drawRot-90)
            targetVector = {x=math.cos(rotRad)*self.speed,y=math.sin(rotRad)*self.speed}
            for i=1,4 do
                local speed=self.speed*(love.math.random()*0.1)
                rotRad = math.rad(self.rotation-90+love.math.random()*40-20)
                self.particles:addRocketParticle(self,false,0)
                particleSet = true
            end
            self:useFuel(0.03*dt)
            Game.points = Game.points + 1
        elseif Input.isKeyPressed("down") then
            local rotRad = math.rad(self.drawRot-90)
            targetVector = {x=-math.cos(rotRad)*self.speed/4,y=-math.sin(rotRad)*self.speed/4}
            self:useFuel(0.01*dt)
            if not particleSet then self.particles:addRocketParticle(self,true,180) end
        end
        if Input.isKeyPressed("left") then
            self.rotation = self.rotation-self.rotspeed*dt
            self:useFuel(0.003*dt)
            if not particleSet then self.particles:addRocketParticle(self,true,90) end
        end
        if Input.isKeyPressed("right") then
            self.rotation = self.rotation+self.rotspeed*dt
            self:useFuel(0.003*dt)
            if not particleSet then self.particles:addRocketParticle(self,true,-90) end
        end
    end

    self.velX = self.velX+(targetVector.x-self.velX)/(self.weakness)
    self.velY = self.velY+(targetVector.y-self.velY)/(self.weakness)
    self.x = self.x+self.velX
    self.y = self.y+self.velY

    self.particles:update(dt);

    if self.fuel <= 0 then
        self.noFuelTime = self.noFuelTime + dt
        self.blocked = true
    else
        self.noFuelTime = 0
        if not Game.isWinning then self.blocked = false end
    end
end

function Spacman:draw()
    self.particles:draw();

    local colorScale = 1 + math.pow(Game.winningStateTimer*0.4, 5);
    if self.noFuelTime > 1 then
        colorScale = 0.2
    elseif self.noFuelTime > 0 then
        local randomizer = love.math.newRandomGenerator(math.floor(self.noFuelTime*5))
        colorScale = 0.2 + randomizer:random()*0.8;
    end

    love.graphics.setColorOld(255*colorScale,255*colorScale,255*colorScale)
    love.graphics.draw(self.texture,self.x,self.y,math.rad(self.drawRot),0.003,0.003,10.5,20.5)
    love.graphics.setColorOld(255,255,255)

    if Game.isWinning and Game.winningStateTimer>3.0 then
        local state = (Game.winningStateTimer-3.0)/0.6;
        local alpha = 0.5 + (state * 0.5)*255
        local scale = math.pow((state-0.1)*2,7);
        love.graphics.setColorOld(255*colorScale,255*colorScale,255*colorScale, alpha)
        love.graphics.draw(self.texture,self.x,self.y,math.rad(self.drawRot),0.003*scale,0.003*scale,10.5,20.5)
    end
    love.graphics.setColorOld(255,255,255)
end

function Spacman:addFuelPellet(value)
    self.fuel = math.min(1, self.fuel + 0.002*value)
end

function Spacman:useFuel(value)
    self.fuel = math.max(0, self.fuel-value)
end
