
DeathScreen = {
    timer = 0,
    restarting = false,
    restartingTimer = 0,
    preserveSeed = false,
    customSeed = false,
    sadSong = nil
}

function death_init()
    DeathScreen.sadSong = res.sounds.dead;
    DeathScreen.sadSong:play();
    DeathScreen.restarting = false
    DeathScreen.timer = 0
    DeathScreen.restartingTimer = 0
    DeathScreen.preserveSeed = false
    DeathScreen.customSeed = false
end

function death_update(dt)

    if not restarting and Input.isKeyPressed('r') then
        DeathScreen.restarting = true
        if Input.isKeyPressed("rctrl") or Input.isKeyPressed("lctrl") then
            DeathScreen.customSeed = true
        elseif Input.isKeyPressed('lshift') or Input.isKeyPressed('rshift') then
            DeathScreen.preserveSeed = true
        end
    end

    if DeathScreen.restarting then
        local volume = DeathScreen.sadSong:getVolume()
        if volume>0 then
            DeathScreen.sadSong:setVolume(math.max(volume-1*dt,0))
        end
        DeathScreen.restartingTimer = DeathScreen.restartingTimer+dt
        if DeathScreen.restartingTimer>1 or DeathScreen.timer<1 then
            if not DeathScreen.preserveSeed then _SEED = 0 end
            setGamestate("intro")
            if DeathScreen.customSeed then
                Intro.state = 1
                Intro.customSeed = true
            else
                Intro.state = DeathScreen.timer<2 and 2 or 1
            end
            DeathScreen.sadSong:stop()
        end
    end

    DeathScreen.timer = DeathScreen.timer + dt;
end


function death_draw()
    love.graphics.setColorOld(255,255,255);
    love.graphics.draw(res.images.grief_ded,660,250,0,5,5);
    love.graphics.draw(res.images.grief_sad_face,880,200,0,5,5);

    love.graphics.setFont(res.fonts.default)
    love.graphics.printf("GAME OVER",0,60,windowWidth/20.0,"center",0,20)

    love.graphics.setColorOld(160,160,160);
    love.graphics.printf("TIME OF DEATH:",0,300,80,"center",0,8)
    love.graphics.setColorOld(255,255,255);
    love.graphics.printf(timeFormat(_TIME),0,350,80,"center",0,8)

    love.graphics.setColorOld(160,160,160);
    love.graphics.printf("SEED:",65,430,80,"left",0,8)

    love.graphics.setColorOld(255,255,255);
    love.graphics.printf(decimalFormat(_SEED,"xxxxxxxx"),245,430,80,"left",0,8)

    love.graphics.setColorOld(255,255,255);
    love.graphics.printf("PRESS R TO RESTART",0,windowHeight-100,windowWidth/8.0,"center",0,8)
    love.graphics.setColorOld(160,160,160);
    love.graphics.printf("SHIFT+R FOR SAME SEED, CTRL+R FOR CUSTOM SEED",-6,windowHeight-50,windowWidth/4.0,"center",0,4)
    love.graphics.setColorOld(0,0,0,math.max(0,255-DeathScreen.timer*100));
    love.graphics.rectangle("fill", 0,0, windowWidth, windowHeight);

    love.graphics.setColorOld(0,0,0,DeathScreen.restartingTimer*255);
    love.graphics.rectangle("fill", 0,0, windowWidth, windowHeight);
end