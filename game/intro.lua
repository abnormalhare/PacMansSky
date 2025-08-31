Intro = {
  state = 0,
  counter = 0,
  sf = nil,
  planet = nil,
  customSeed = false,
  seedNumbers = {},
  seedCursor = 1,
  hasCrashed = false
}

function intro_init()
    Intro.planet = nil
    game_init() --im creating fake planets in intro and they need Game object to be properly initiated. kinda cringe, ngl

    Intro.state = 0
    Intro.counter=0
    Intro.hasCrashed = false

    Intro.customSeed = false
    Intro.seedNumbers = {0,0,0,0,0,0,0,0}
    Intro.seedCursor = 1
end

function intro_update(dt)
    Intro.counter = Intro.counter+dt
    if Input.isKeyTyped("return") and Intro.state ~=2 and Intro.state ~= 0
    and (not Intro.customSeed or (Intro.state==1 and Intro.counter>2)) then
        Intro.state = 2
        Intro.counter = 0
    end

    if Intro.state==0 and Intro.counter>10 then
        Intro.state=1 
        Intro.counter=0
    end
    if Intro.customSeed and Intro.state==1 and Intro.counter>1.5 then
        Intro.state = 1.5
        Intro.counter = 0
    end
    if Intro.state==1 then
        if Intro.counter>1.5 then
            if not Intro.planet or Intro.planet.pos>1 then
                local id = Intro.planet and Intro.planet.id+1 or 1
                if id<4 then
                    local angle = id * math.pi
                    Intro.planet = {
                    id = id, pos=0,
                    x = id==3 and 0 or math.cos(angle),
                    y = id==3 and 0 or math.sin(angle),
                    planet = Planet(id==3 and 1 or love.math.random(2,100),0,0)
                    }
                    Intro.planet.planet.camera.drawPos.x = Intro.planet.planet.size;
                    Intro.planet.planet.camera.drawPos.zoom = 3
                    Intro.planet.planet.camera.x = Intro.planet.planet.size;
                    Intro.planet.planet.camera.zoom = 3
                    Intro.planet.planet:refreshPlanet()
                end
            end
            Intro.planet.pos = Intro.planet.pos+dt/2
            Intro.planet.planet:cameraUpdate()
        end
        if Intro.counter>8 then 
            Intro.state=2 
            Intro.counter=0
        end
    end
    if Intro.state==1.5 then
        if Intro.seedCursor<=8 then
            for i=0,9 do if Input.isKeyTyped(""..i) or Input.isKeyTyped("kp"..i) then
                Intro.seedNumbers[Intro.seedCursor] = i
                Intro.seedCursor = Intro.seedCursor+1
                break
            end end
        end
        if Intro.seedCursor>1 and Input.isKeyTyped("backspace") then
            Intro.seedCursor = Intro.seedCursor-1
        end
        if Intro.seedCursor>8 and Input.isKeyTyped("return") then
            local seed = 0;
            for i=1,8 do
                seed = seed + Intro.seedNumbers[i] * math.pow(10, 8-i)
            end
            _SEED = seed
            Intro.state = 1.6
            Intro.counter = 0
        end
    end
    if Intro.state==1.6 and Intro.counter>1 then
        Intro.state = 1
        Intro.counter = 1.5
        Intro.customSeed = false
    end
    if Intro.state==2 then
        if not Intro.hasCrashed then
            res.sounds.crash:play()
            Intro.hasCrashed = true
        end
        if Intro.counter>2 then
            setGamestate("game")
            if _SEED>0 then Game.seed = _SEED end
            Game.activePlanet = Planet(1)
            Game.spacecam.x = Game.activePlanet.x;
            Game.spacecam.y = Game.activePlanet.y;
            Game.spacecam:force();
            Game.activePlanet.camera:force();
            Game.activePlanet.camera.drawPos.zoom = 0.1;

            Game.activePlanet.camera.x = Game.activePlanet.size/2.0
            Game.activePlanet.camera.y = Game.activePlanet.size/2.0
            Game.activePlanet.camera.drawPos.x = Game.activePlanet.camera.x
            Game.activePlanet.camera.drawPos.y = Game.activePlanet.camera.y

            Game.state = "planet"
        end
    end
end

function intro_draw()
    love.graphics.setShader()
    if Intro.state == 0 then
        local t1a = math.min(math.max(Intro.counter-1,0),2)*128
        local t2a = math.min(math.max(Intro.counter-4,0),2)*128
        local ba = math.min(math.max(Intro.counter-7,0),3)*85
        love.graphics.setColorOld(t1a,t1a,t1a)
        love.graphics.printf("''A JOURNEY OF A THOUSAND MILES\nBEGINS WITH A SINGLE STEP",0,250,windowWidth/7,"center",0,7,7)
        love.graphics.setColorOld(t2a,t2a,t2a)
        love.graphics.printf("...OR SOMETHING''",0,350,windowWidth/7,"center",0,7,7)
        love.graphics.setColorOld(0,0,0,ba)
        love.graphics.rectangle("fill",0,0,windowWidth,windowHeight)
    end
    if Intro.state == 1 or Intro.state==1.5 or Intro.state==1.6 then
        -- epic spacey shader
        SHADER_WARP_RADIAL:send("time",_RUNTIME)
        local spaceAlpha = math.min(1,Intro.counter)
        if Intro.state == 1.5 or Intro.state == 1.6 then spaceAlpha = 1 end
        love.graphics.setColorOld(128,128,128,spaceAlpha*255)
        love.graphics.setShader(SHADER_WARP_RADIAL)
        love.graphics.draw(
            res.images.spaceman,0,0,0,
            windowWidth/res.images.spaceman:getWidth(),
            windowHeight/res.images.spaceman:getHeight()
        )
        love.graphics.setShader()

        if Intro.state == 1 then
            if Intro.counter>1.5 then
                local p = Intro.planet.pos
                p = p*p*p*p*p*p*p
                local a = p/math.max(Intro.planet.pos,0.01)
                local x = (0.5+Intro.planet.x*p*1.5)
                local y = (0.5+Intro.planet.y*p*1.5)
                love.graphics.setColorOld(255,255,255,a*255)
                love.graphics.push()
                love.graphics.translate(windowWidth*x,windowHeight*y)
                love.graphics.scale(windowWidth)
                love.graphics.scale(p*3+0.2)
                Intro.planet.planet:draw()
                love.graphics.pop()
            end
            local fade = math.max(0,Intro.counter-6)/2
            fade = fade*fade*fade*fade*fade*255
            love.graphics.setColorOld(255,255,255,fade)
            love.graphics.rectangle("fill",0,0,windowWidth,windowHeight)
        else

            local alpha = math.min(Intro.counter,1)
            if Intro.state==1.6 then alpha = math.max(0, 1-Intro.counter*2) end

            love.graphics.setColorOld(255,255,255,alpha*255)
            love.graphics.printf("ENTER SEED:",10,250,windowWidth/7,"center",0,7)

            for i=1,8 do
                love.graphics.push()
                local xOff = (i-4.5)*60;
                love.graphics.translate(windowWidth/2+xOff,windowHeight/2)

                local c = (Intro.seedCursor==i and math.mod(Intro.counter,1)<0.5) and 255 or 50
                love.graphics.setColorOld(c,c,c,alpha*255)
                love.graphics.rectangle("fill",-25,50,50,4)

                if i<Intro.seedCursor then
                    local numberAlpha = alpha
                    if Intro.state==1.6 then numberAlpha = math.max(0, 1-Intro.counter) end
                    love.graphics.setColorOld(255,255,255,numberAlpha*255)
                    love.graphics.printf(Intro.seedNumbers[i],-20,-20,100,"left",0,10)
                end

                love.graphics.pop()
            end

            if Intro.seedCursor>8 and Intro.state == 1.5 then
                love.graphics.setColorOld(200,200,200)
                love.graphics.printf("PRESS ENTER TO CONFIRM",4,windowHeight/2+80,windowWidth/4,"center",0,4)
            end
        end
    end
end