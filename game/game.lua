function game_init()
    SAVE = {};

    Game = {}
    Game.galaxy = {}
    Game.galaxy.minDistance = 4
    Game.galaxy.maxDistance = 16
    function Game.galaxy.getPlanetInChunk(cx,cy)
        local randomizer = love.math.newRandomGenerator(Game.seed+(42*cx+cy))
        local px = cx*Game.galaxy.maxDistance+Game.galaxy.minDistance/2+randomizer:random(Game.galaxy.maxDistance-Game.galaxy.minDistance)
        local py = cy*Game.galaxy.maxDistance+Game.galaxy.minDistance/2+randomizer:random(Game.galaxy.maxDistance-Game.galaxy.minDistance)
        local id = Game.seed+(42*px + py)
        if cx == 0 and cy == 0 then id = 1 end
        return {x=px,y=py,id=id}
    end
    Game.galaxy.temp_pc = {}
    function Game.galaxy.getPlanetsInArea(x1,y1,x2,y2)
        local planets = {}
        local md = Game.galaxy.maxDistance
        for x=math.floor(x1/md),math.ceil(x2/md) do for y=math.floor(y1/md),math.ceil(y2/md) do
            planets[x..","..y] = Game.galaxy.getPlanetInChunk(x,y)
            if not Game.galaxy.temp_pc[x..","..y] then
                Game.galaxy.temp_pc[x..","..y] = Planet.getParams(planets[x..","..y].id)
                Game.galaxy.temp_pc[x..","..y].new = true
            else
                Game.galaxy.temp_pc[x..","..y].new = true
            end
        end end
        for k,v in pairs(Game.galaxy.temp_pc) do
            if not v.new then
                Game.galaxy.temp_pc[k] = nil
            else
                v.new = false
            end
        end
        return planets
    end

    function Game.removeActivePlanet()
        if Game.activePlanet then Game.activePlanet:unloadSounds() end
        Game.activePlanet = nil
    end
    
    Game.seed = _SEED
    if Game.seed == 0 then Game.seed = love.math.random(10000000, 99999999) end
    print("Seed: "..Game.seed)
    Game.tilesets = {res.images.retro_tileset,res.images.retro_tileset2,res.images.retro_tileset3}
    Game.ambients = {res.sounds.spaceambient1}
    if Game.lowFuelSound then Game.lowFuelSound:stop() end
    Game.lowFuelSound = res.sounds.lowfuel;
    Game.lowFuelSound:setLooping(true);
    Game.launchFuelUse = 0.1
    Game.removeActivePlanet()
    Game.points = 0
    Game.lives = 3
    Game.cherries = 0
    Game.requiredCherries = 10
    Game.state = "space"
    Game.stateCounter=0
    Game.isDying = false
    Game.isReallyDying = false
    Game.isWinning = false
    Game.winningStateTimer = 0
    Game.time = 0
    Game.onFirstPlanet = true

    Game.paused = false
    Game.pausedSounds = {}

    Game.guifont = res.fonts.default
    Game.spaceEnts = {}
    Game.spacman = Spacman()
    table.insert(Game.spaceEnts,Game.spacman)
    Game.spacecam = {
        x=0,y=0,rot=0,
        drawPos={x=0,y=0,rot=0,difX=0,difY=0},
        smoothness = 5,
        force = function(self)
            self.drawPos.x = self.x;
            self.drawPos.y = self.y;
            self.drawPos.rot = self.rot;
        end,
        update = function(self,dt)
            self.drawPos.x = self.drawPos.x+(self.x-self.drawPos.x)/self.smoothness
            self.drawPos.y = self.drawPos.y+(self.y-self.drawPos.y)/self.smoothness
            if self.rot<-180 then self.rot=self.rot+360; self.drawPos.rot=self.drawPos.rot+360 end
            if self.rot>180 then self.rot=self.rot-360; self.drawPos.rot=self.drawPos.rot-360 end
            if math.abs(self.rot+360-self.drawPos.rot)<math.abs(self.rot-self.drawPos.rot) then self.drawPos.rot = self.drawPos.rot-360 end
            if math.abs(self.rot-360-self.drawPos.rot)<math.abs(self.rot-self.drawPos.rot) then self.drawPos.rot = self.drawPos.rot+360 end
            self.drawPos.rot = self.drawPos.rot+(self.rot-self.drawPos.rot)/self.smoothness
        end
    }
end

function game_update(dt)

    if Input.isKeyTyped("p") then
        Game.paused = not Game.paused

        if Game.paused then
            for k,sound in pairs(res.sounds) do
                if sound:isPlaying() then
                    love.audio.pause(sound)
                    Game.pausedSounds[sound] = true
                end
            end
        else
            for sound in pairs(Game.pausedSounds) do
                if sound:tell()>0 then love.audio.play(sound) end
            end
            Game.pausedSounds = {}
        end

        res.sounds.pause:stop()
        res.sounds.pause:play()
    end

    if Game.paused then 
        --restart
        if Input.isKeyTyped("r") then

            if Input.isKeyPressed("rctrl") or Input.isKeyPressed("lctrl") then
                setGamestate("intro") 
                Intro.state = 1
                Intro.customSeed = true
                res.sounds.pause:play()
            else
                if not (Input.isKeyPressed('lshift') or Input.isKeyPressed('rshift')) then
                    _SEED = 0
                end
                setGamestate("intro")
                Intro.state = 2
            end
        end

        return 
    end


    local player = Game.spacman
    
    local camOffsetMult = (Game.state=="space" and math.min(Game.stateCounter,1) or 1)*13
    Game.spacecam.x = player.x+player.velX*camOffsetMult
    Game.spacecam.y = player.y+player.velY*camOffsetMult
    Game.spacecam.rot = player.drawRot-90
    local pcx,pcy = Game.spacecam.drawPos.difX/8,Game.spacecam.drawPos.difY/8
    if Game.activePlanet then
        local cam = Game.activePlanet.camera.drawPos
        pcx,pcy = pcx+cam.x/8,pcy+(cam.y-(Game.activePlanet.size/2+0.5))/8
    end
    SHADER_SPACE:send("pos",{-Game.spacecam.drawPos.x+pcx,-Game.spacecam.drawPos.y+pcy})
    SHADER_SPACE:send("rot",math.rad(Game.spacecam.drawPos.rot))
    
    Game.stateCounter = Game.stateCounter+dt
    
    if Game.state=="planet" then
        player.x,player.y = Game.activePlanet.x,Game.activePlanet.y
        Game.spacecam.x,Game.spacecam.y = player.x,player.y
        Game.activePlanet:update(dt)
        Game.stateCounter = 0
    elseif Game.state=="space" then
        for k,v in pairs(Game.spaceEnts) do v:update(dt) end
        if not Game.ambients.actual then
            Game.ambients.actual = Game.ambients[love.math.random(#Game.ambients)]
            Game.ambients.actual:play()
            Game.ambients.actual:setLooping(true)
            Game.ambients.actual:setVolume(0)
        else
            local volume = Game.ambients.actual:getVolume()
            if Game.isDying then
                if volume>0 then
                    Game.ambients.actual:setVolume(math.max(volume-0.2*dt,0))
                end
            else
                if volume<1 then
                    Game.ambients.actual:setVolume(math.min(volume+0.1*dt,1))
                end
            end
        end

        if player.fuel < Game.launchFuelUse and player.fuel > 0 then
            if not Game.lowFuelSound:isPlaying() then
                love.audio.play(Game.lowFuelSound)
            end
        elseif Game.lowFuelSound:isPlaying() then
            Game.lowFuelSound:pause()
        end

    elseif Game.state=="landing" then
        player:update(dt)
        local volume = Game.ambients.actual:getVolume()
        if volume>0 then
            Game.ambients.actual:setVolume(math.max(volume-dt,0))
        end
        if Game.stateCounter>1 then
            player.x,player.y = Game.activePlanet.x,Game.activePlanet.y
            player.velX, player.velY = 0,0
            player.rotation,player.drawRot = 90,90
            Game.state="planet"
        end
    elseif Game.state=="starting" then --starting from a planet
        if Game.stateCounter<=5 then --rotation effect
            local pacman = Game.activePlanet.entities[1]
            pacman.rotation = pacman.rotation+(math.max(1,Game.stateCounter)-1)*15
        end
        if Game.stateCounter>4 then -- prepare camera for launch
            Game.activePlanet.camera.x = 0
            Game.activePlanet.camera.y = Game.activePlanet.size/2+0.5
            Game.activePlanet.camera.smoothness=10
            Game.spacecam.x = Game.activePlanet.x+(Game.activePlanet.size/64)/2-0.1
            end
        if Game.stateCounter>5 then --launch
            player.rotation,player.drawRot=90,90
            player.x = Game.activePlanet.x+(Game.activePlanet.size/64)/2-0.1
            player.velX,player.velY = 0.04,0
            player.blocked = false
            player:useFuel(Game.launchFuelUse)
            Game.state="space"
            Game.stateCounter=0
            Game.ambients.actual = nil
            Game.activePlanet:save()
            Game.points = Game.points+100
            Game.onFirstPlanet = false
            --despawn the planet a moment after leaving it, to not see the transition (enemies disappear)
            Queue.add(function() 
                Game.removeActivePlanet()
            end, 0.5)
        end
    end
    
    -- handle dying
    if not Game.isDying and Game.state=="space" and player.fuel <= 0 then
        res.sounds["engine-off"]:play();
        Game.isDying = true
        if not Game.activePlanet then
            Game.isReallyDying = true
        end
    end

    if Game.isReallyDying and player.noFuelTime>5 then
        setGamestate("death");
    end
    
    --handle winning
    if not Game.isWinning and Input.isKeyTyped("space")
    and Game.cherries >= Game.requiredCherries and not Game.isDying and not Game.activePlanet then
        Game.isWinning = true
        res.sounds.warp:play()
        player.blocked = true
    end

    if Game.isWinning then
        player.fuel = math.max(0.001,player.fuel-0.05)


        local speed = math.pow(Game.winningStateTimer*0.2,2);
        local ang = math.rad(player.drawRot-90)
        local targetVector = {x=math.cos(ang)*speed,y=math.sin(ang)*speed}
        player.velX = player.velX+(targetVector.x-player.velX)/(player.weakness)
        player.velY = player.velY+(targetVector.y-player.velY)/(player.weakness)

        local camX = player.x + targetVector.x * 2
        local camY = player.y + targetVector.y * 2

        Game.spacecam.x = Game.spacecam.x + (camX - Game.spacecam.x) * math.min(1, Game.winningStateTimer)
        Game.spacecam.y = Game.spacecam.y + (camY - Game.spacecam.y) * math.min(1, Game.winningStateTimer)

        Game.winningStateTimer = Game.winningStateTimer+dt
        if Game.winningStateTimer>3.6 then
            setGamestate("win")
        end
    end
 
    Game.spacecam:update(dt)

    if not Game.activePlanet then
        local p = Game.galaxy.getPlanetInChunk(math.floor(player.x/Game.galaxy.maxDistance),math.floor(player.y/Game.galaxy.maxDistance))
        local disx,disy = p.x-player.x,p.y-player.y
        local distance = math.sqrt(disx*disx+disy*disy)

        -- allow getting near planets only when not dead and not winning
        if distance<3 and not Game.isReallyDying and not Game.isWinning then
            Game.activePlanet=Planet(p.id, p.x, p.y)
            Game.activePlanet.camera.x = 0
            Game.activePlanet.camera.y = Game.activePlanet.size/2+0.5
            Game.activePlanet.camera:force()
        end
    end
    if Game.activePlanet then
        local cam = Game.activePlanet.camera
        cam.disX,cam.disY = -Game.spacecam.x,-Game.spacecam.y
        cam.drawPos.disX = -Game.spacecam.drawPos.x+Game.activePlanet.x
        cam.drawPos.disY = -Game.spacecam.drawPos.y+Game.activePlanet.y
        cam.rot = Game.spacecam.drawPos.rot
        Game.activePlanet:cameraUpdate()
        local disx,disy = Game.activePlanet.x-player.x,Game.activePlanet.y-player.y
        local distance = math.sqrt(disx*disx+disy*disy)

        -- get rid of planets if got too far with enough fuel
        if distance>3 and Game.spacman.fuel > 0 then
            local cam = Game.activePlanet.camera.drawPos
            --Game.spacecam.drawPos.difX = Game.spacecam.drawPos.difX+cam.x
            --Game.spacecam.drawPos.difY = Game.spacecam.drawPos.difY+cam.y
            Game.removeActivePlanet()
        elseif (Game.state=="space" and Game.stateCounter>2) or Game.state=="landing" then
            local planetRadius = (Game.activePlanet.size/64)/2
            if Game.state=="landing" then
                -- player movement just after landing
                -- local multiplier = math.max((1-math.pow(distance/planetRadius,0.1)),0)
                local multiplier = 0.1;
                player.velX = player.velX-(player.velX)*multiplier
                player.velY = player.velY-(player.velY)*multiplier
            else
                -- gravitational pull
                player.velX = player.velX+(disx/distance-player.velX)/(math.max(1,distance)*(Game.state=="space" and 5000 or 2000))
                player.velY = player.velY+(disy/distance-player.velY)/(math.max(1,distance)*(Game.state=="space" and 5000 or 2000))
            end
            if Game.state=="space" and distance<planetRadius then
                -- switching to landing state if flying straight into the planet. reflect the player otherwise
                if Vector.dot(Vector(player.velX,player.velY):normalized(),Vector(disx,disy):normalized()) > 0.5 then
                    player.blocked = true
                    Game.state="landing"
                    Game.stateCounter=0 
                    Game.isDying = false;
                    Game.lowFuelSound:pause()

                    res.sounds["crash"]:play()
                else
                    local planetNorm = Vector(-disx,-disy):normalized()
                    local velVec = Vector(player.velX, player.velY)
                    local reflectedVel = velVec - planetNorm * (2 * planetNorm:dot(velVec))
                    player.velX = reflectedVel.x
                    player.velY = reflectedVel.y
                end
            end
        end
    end


    --handling timer and external variables
    if not Game.isReallyDying then
        Game.time = Game.time+dt;
    end

    if not Game.isWinning and not Game.isReallyDying then
        _TIME = Game.time;
        _SCORE = Game.points;
        _SEED = Game.seed;
    end
end


function game_draw()
    love.graphics.push()
    love.graphics.translate(windowWidth/2,windowHeight/2)
    --window width equals one space unit
    love.graphics.scale(windowWidth) 
    -- space shader background
    love.graphics.setShader(SHADER_SPACE)
    love.graphics.draw(res.images.spaceman,-0.5,-0.5,0,1/res.images.spaceman:getWidth(),1/res.images.spaceman:getHeight())
    love.graphics.setShader()

    if Game.state~="planet" then
        love.graphics.push()
        love.graphics.rotate(-math.rad(Game.spacecam.drawPos.rot))
        love.graphics.translate(-Game.spacecam.drawPos.x,-Game.spacecam.drawPos.y)
        for k,v in pairs(Game.spaceEnts) do
        v:draw()
        end
        love.graphics.pop()
    end

    -- draw the planet
    if Game.activePlanet then
        Game.activePlanet:draw() 
    end
    love.graphics.pop()

    --[[ ui stuff ]]--

    -- fuel
    local fuelBarWidth = 300;
    love.graphics.setFont(Game.guifont)
    love.graphics.printf("FUEL:",windowWidth/2 - fuelBarWidth - 5,32,(windowWidth/2-32)/6,"right",0,6)
    love.graphics.setLineStyle("rough")
    love.graphics.setLineWidth("5")
    love.graphics.setColorOld(40,100,40,100)
    love.graphics.rectangle("fill",windowWidth-32-fuelBarWidth+2,32,(fuelBarWidth-4),32)
    love.graphics.setColorOld(100,70,0,100)
    love.graphics.rectangle("fill",windowWidth-32-fuelBarWidth+2,32,(fuelBarWidth-4)*(Game.launchFuelUse*3),32)
    love.graphics.setColorOld(100,10,10,100)
    love.graphics.rectangle("fill",windowWidth-32-fuelBarWidth+2,32,(fuelBarWidth-4)*(Game.launchFuelUse),32)
    love.graphics.setColorOld(255,184,175)
    love.graphics.rectangle("fill",windowWidth-32-fuelBarWidth+2,32,(fuelBarWidth-4)*Game.spacman.fuel,32)
    love.graphics.setColorOld(255,255,255)
    love.graphics.rectangle("line",windowWidth-32-fuelBarWidth,32,fuelBarWidth,32)

    --low fuel alert
    if Game.state=="space" and Game.spacman.fuel<Game.launchFuelUse and Game.spacman.fuel>0 then
        local alpha = 120+120*math.sin(Game.lowFuelSound:tell()/Game.lowFuelSound:getDuration() * math.pi);
        love.graphics.setColorOld(255,10,10,alpha)
        love.graphics.printf("LOW FUEL!",windowWidth/2 - 5,74,(windowWidth/2-32)/6,"right",0,6)
    end

    --help text
    if Game.state=="planet" and not Game.activePlanet.sounds.start:isPlaying() then
        local alpha = 180+50*math.sin(_RUNTIME * math.pi);
        love.graphics.setColorOld(255,255,10,alpha)

        local text = "COLLECT MORE FUEL!"
        if Game.spacman.fuel>Game.launchFuelUse*3 then
            text = "ENOUGH FUEL! YOU CAN\nLEAVE THE PLANET!"
        end

        love.graphics.printf(text,windowWidth/2 - 5,74,(windowWidth/2-32)/3,"right",0,3)
    end

    -- score
    love.graphics.setFont(Game.guifont)
    love.graphics.setColorOld(255,255,255)
    love.graphics.printf("SCORE: ",32,32,10000,"left",0,6)
    love.graphics.printf(decimalFormat(Game.points,"xxxxxxx"),32,32,64,"right",0,6)

    --time
    love.graphics.setFont(Game.guifont)
    love.graphics.setColorOld(255,255,255)
    love.graphics.printf("TIME: ",32,80,10000,"left",0,6)
    love.graphics.printf(timeFormat(_TIME),32,80,64,"right",0,6)

    -- lifes
    if Game.state=="planet" or Game.state=="starting" then for i=1,3 do
        if not lifeIcon then lifeIcon = love.graphics.newQuad(15,15,15,15,res.images.pacman:getDimensions()) end
        love.graphics.setColorOld(255,255,255,i<=Game.lives and 255 or 32)
        love.graphics.draw(res.images.pacman,lifeIcon,32+(i-1)*60,windowHeight-150,0,4,4)
    end end

    -- cherry counter
    if not Game.isWinning then
        love.graphics.setFont(Game.guifont)
        love.graphics.setColorOld(255,255,255)
        love.graphics.draw(res.images.cherry,38,windowHeight-82,0,6,6)
        love.graphics.printf(decimalFormat(Game.cherries,"xx").."/"..decimalFormat(Game.requiredCherries,"xx"),100,windowHeight-72,10000,"left",0,6)
    end

    -- cherry alert!
    if Game.cherries >= Game.requiredCherries and not Game.isWinning and not Game.isDying then
        love.graphics.setColorOld(200,(1+math.sin(Game.time*3))*100,0)
        local warpText = "PRESS SPACEBAR TO ACTIVATE WARP!"
        if Game.activePlanet then warpText = "ENOUGH CHERRIES! LEAVE THE PLANET!" end

        love.graphics.printf(warpText,0,windowHeight-32,windowWidth/4,"center",0,4)

        love.graphics.setColorOld(255,255,255)
    end

    -- space radar
    if Game.state=="space" and (not Game.isDying or (Game.spacman.noFuelTime>0.2 and Game.spacman.noFuelTime<0.5)) and not Game.isWinning then
        --love.graphics.setLineStyle("smooth")
        local radarDistance,radarSize = 10,150
        local radarImgSize = (radarSize*2)/res.images.radar_bg:getWidth()
        love.graphics.setColorOld(255,255,255)
        love.graphics.draw(res.images.radar_bg,windowWidth-radarSize*2-32,windowHeight-radarSize*2-32,0,radarImgSize,radarImgSize)
        --love.graphics.setColorOld(0,0,0,222)
        --love.graphics.circle("fill",windowWidth-radarSize-32,windowHeight-radarSize-32,radarSize,64)
        --love.graphics.setLineWidth(4)
        --love.graphics.setColorOld(32,32,32)
        --love.graphics.line(windowWidth-radarSize-32,windowHeight-radarSize*2-32,windowWidth-radarSize-32,windowHeight-32)
        --love.graphics.line(windowWidth-radarSize*2-32,windowHeight-radarSize-32,windowWidth-32,windowHeight-radarSize-32)
        local camx,camy = Game.spacecam.drawPos.x,Game.spacecam.drawPos.y 
        local ppoints = Game.galaxy.getPlanetsInArea(camx-15,camy-15,camx+15,camy+15)

        if not Game.isDying then
            for k,v in pairs(ppoints) do
                local cx,cy = v.x-camx,v.y-camy
                local angle = math.atan2(cy,cx)-math.rad(Game.spacecam.drawPos.rot)
                local pdistance = math.sqrt(cx*cx+cy*cy)
                local scale = Game.galaxy.temp_pc[k].size/57
                local distance = math.min(radarSize-20-scale*2,pdistance*(radarSize/radarDistance))
                local dx,dy = math.cos(angle)*distance,math.sin(angle)*distance
                local color = Game.galaxy.temp_pc[k].skyColor
                love.graphics.setColorOld(color[1]*255 * 2,color[2]*255 * 2,color[3]*255 * 2,255-math.max(0,(pdistance-15)/2)*255)
                local px,py,r = windowWidth-radarSize-32+dx,windowHeight-radarSize-32+dy,radarSize/radarDistance
                love.graphics.push()
                love.graphics.translate(px,py)
                love.graphics.rotate(color[1]+color[2]*2+color[3]*3-math.rad(Game.spacecam.drawPos.rot))
                love.graphics.scale(scale,scale)
                love.graphics.rectangle("fill",-r*0.6,-r,r*1.2,r*2) --środkowy
                love.graphics.rectangle("fill",-r,-r*0.6,r*0.4,r*1.2) --lewy
                love.graphics.rectangle("fill",r*0.6,-r*0.6,r*0.4,r*1.2) --prawy
                love.graphics.pop()
            end
        end
        love.graphics.setLineWidth(10)
        love.graphics.setColorOld(255,255,255)
        --love.graphics.circle("line",windowWidth-radarSize-32,windowHeight-radarSize-32,radarSize,64)
        love.graphics.draw(res.images.radar_fg,windowWidth-radarSize*2-32,windowHeight-radarSize*2-32,0,radarImgSize,radarImgSize)
    end

    --dying fadeout
    if Game.isReallyDying then
        local fadeout = math.min(math.max((Game.spacman.noFuelTime-1)*0.3,0),1)
        love.graphics.setColorOld(0,0,0,fadeout*255);
        love.graphics.rectangle("fill",0,0,windowWidth,windowHeight);
        love.graphics.setColorOld(255,255,255);
    end

    --winning flash
    if Game.isWinning then
        local fadeout = math.min(math.max((Game.winningStateTimer-3.4)/0.2,0),1)
        love.graphics.setColorOld(255,255,255,fadeout*255);
        love.graphics.rectangle("fill",0,0,windowWidth,windowHeight);
        love.graphics.setColorOld(255,255,255);
    end



    --pause screen
    if Game.paused then
        love.graphics.setColorOld(0,0,0,200);
        love.graphics.rectangle("fill",0,0,windowWidth,windowHeight);
        love.graphics.setColorOld(255,255,255)
        love.graphics.printf("PAUSED!",0,windowHeight/2-64,windowWidth/15.0,"center",0,15)

        love.graphics.setColorOld(255,255,255)
        love.graphics.printf("SEED: ".._SEED,-25,windowHeight-158,windowWidth/5,"right",0,5)
        love.graphics.setColorOld(200,200,200)
        love.graphics.printf("R - RESTART (RANDOM SEED)",-25,windowHeight-116,windowWidth/4,"right",0,4)
        love.graphics.printf("SHIFT+R - RESTART (CURRENT SEED)",-25,windowHeight-84,windowWidth/4,"right",0,4)
        love.graphics.printf("CTRL+R - RESTART (CUSTOM SEED)",-25,windowHeight-52,windowWidth/4,"right",0,4)
    end
end