Win = {
    timer = 0,
    music = nil,
    particles = ParticleSystem()
}


function win_init()
    Win.music = res.sounds.win;
    Win.music:play()
    Win.timer = 0
end


function win_update(dt)

    for i=1,6 do
        Win.particles:addRocketParticle({x=0.04,y=0,speed=0.2,velX=0,velY=0,rotation=90},false,0)
    end
    Win.particles:update(dt);
    Win.timer = Win.timer + dt;

    --restart
    if Win.timer > 1 and Input.isKeyTyped("r") then

        if Input.isKeyPressed("rctrl") or Input.isKeyPressed("lctrl") then
            setGamestate("intro")
            Intro.state = 1
            Intro.customSeed = true
        else
            if not (Input.isKeyPressed('lshift') or Input.isKeyPressed('rshift')) then
                _SEED = 0
            end
            setGamestate("intro")
            Intro.state = 2
        end
    end
end


function win_draw()

    local epicAnim = math.max(Win.timer-20.4,0);


    if epicAnim < 1.6 then
        -- epic spacey shader
        SHADER_WARP:send("time",Win.timer)

        love.graphics.setColorOld(128,128,128)
        love.graphics.setShader(SHADER_WARP)
        love.graphics.draw(
            res.images.spaceman,0,0,0,
            windowWidth/res.images.spaceman:getWidth(),
            windowHeight/res.images.spaceman:getHeight()
        )
        love.graphics.setShader()
        
        --fuckman
        love.graphics.setColorOld(255,255,255)

        local rand = love.math.newRandomGenerator(69);
        local xOff,yOff = 0,0
        xOff = xOff + 800*(epicAnim*epicAnim*epicAnim - epicAnim*epicAnim)

        love.graphics.push()
        love.graphics.translate(windowWidth/5 + xOff, windowHeight*0.53 + yOff)
        love.graphics.scale(2048,2048)
        Win.particles:draw()
        love.graphics.pop()

        for i=0,5 do
            xOff = xOff + math.sin(Win.timer*rand:random()*40+rand:random()*40)*rand:random()*4
            yOff = yOff + math.sin(Win.timer*rand:random()*40+rand:random()*40)*rand:random()*4
        end

        love.graphics.push()
        love.graphics.translate(windowWidth/5 + xOff, windowHeight*0.53 + yOff)
        love.graphics.setColorOld(255,255,255)
        love.graphics.draw(
            res.images.spaceman, 0,0, math.pi/2,4,6,
            res.images.spaceman:getWidth()/2,res.images.spaceman:getHeight()
        )
        love.graphics.pop()
    end

    --text
    love.graphics.setColorOld(255,255,255)
    love.graphics.setFont(res.fonts.default) 
    love.graphics.printf("GAME COMPLETED!",20,100,windowWidth/15.0,"center",0,15)   

    local textXPos = windowWidth/2
    local textAlign = "left"
    if epicAnim >= 1.6 then
        textXPos = 0
        textAlign = "center"
    end
    love.graphics.printf("TIME: "..timeFormat(_TIME),textXPos,280,windowWidth/7,textAlign,0,7)   
    love.graphics.printf("SCORE: "..decimalFormat(_SCORE,"xxxxxxx"),textXPos,330,windowWidth/7,textAlign,0,7)   
    love.graphics.printf("SEED: "..decimalFormat(_SEED,"xxxxxxxx"),textXPos,400,windowWidth/7,textAlign,0,7)  

    love.graphics.setColorOld(255,255,255)

    --more text
    love.graphics.setColorOld(200,200,200)
    love.graphics.printf("R - RESTART (RANDOM SEED)",0,windowHeight-116,windowWidth/4,"center",0,4)
    love.graphics.printf("SHIFT+R - RESTART (CURRENT SEED)",0,windowHeight-84,windowWidth/4,"center",0,4)
    love.graphics.printf("CTRL+R - RESTART (CUSTOM SEED)",0,windowHeight-52,windowWidth/4,"center",0,4)

    --blinding rectangle aaa
    local blindA = 255 * math.pow(1-math.max(Win.timer-0.5,0)*0.2,3)

    local blindB = 255 * math.min(
        math.pow(math.max(epicAnim-0.6,0),3),
        math.pow(1-math.max(epicAnim-1.6,0)*0.2,3)
    );

    love.graphics.setColorOld(255,255,255,math.max(blindA,blindB))
    love.graphics.rectangle("fill",0,0,windowWidth,windowHeight)
end