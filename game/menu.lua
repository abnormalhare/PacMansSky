local nextState = nil
local time = 0
local nextStateTime = 0
local customSeed = false

function menu_update(dt)

    if nextState then
        nextStateTime = nextStateTime + dt
        if nextStateTime>2 then 
            setGamestate(nextState) 
            Intro.state = 1
            Intro.counter = 1.5
            Intro.customSeed = customSeed
        end
    end

    if time>3 then
        if Input.isKeyTyped("return") then
            nextState = "intro"
            if Input.isKeyPressed("rctrl") or Input.isKeyPressed("lctrl") then
                customSeed = true
            end
        end
    end

    time = time+dt
end

function menu_draw()
    love.graphics.clear(0,0,0)
    love.graphics.setColorOld(255,255,255)

    -- epic spacey shader
    SHADER_WARP_RADIAL:send("time",_RUNTIME)

    love.graphics.setColorOld(128,128,128,math.min(1,time*0.4)*255)
    love.graphics.setShader(SHADER_WARP_RADIAL)
    love.graphics.draw(
        res.images.spaceman,0,0,0,
        windowWidth/res.images.spaceman:getWidth(),
        windowHeight/res.images.spaceman:getHeight()
    )
    love.graphics.setShader()

    if time>0.8 then
        love.graphics.setColorOld(255,255,255, math.min(1,(time-0.8),math.max(0,1-nextStateTime))*255)
        love.graphics.draw(res.images.logo,windowWidth/2,150,0,5,5,103.5)
    end
    love.graphics.setFont(res.fonts.default)
    if time>1.8 then
        love.graphics.setColorOld(200,200,200, math.min(1,(time-1.8),math.max(0,1-nextStateTime))*255)
        love.graphics.printf("A GAME BY KRZYHAU",0,250,windowWidth/6,"center",0,6)
    end

    if time>3 then
        love.graphics.setColorOld(220,220,220, math.min(1,(time-3),math.max(0,1-nextStateTime))*255)
        love.graphics.printf("PRESS ENTER TO START",0,windowHeight*0.6,windowWidth/8,"center",0,8)

        love.graphics.setColorOld(160,160,160, math.min(1,(time-3),math.max(0,1-nextStateTime))*255)
        love.graphics.printf("CTRL+ENTER TO START WITH CUSTOM SEED",0,windowHeight*0.6+48,windowWidth/4,"center",0,4)
    end
end