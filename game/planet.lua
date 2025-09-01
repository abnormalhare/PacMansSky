Planet = class(nil,"Planet")
Planet.tiles = {
    AIR = 0,
    PELLET = 1,
    POWER = 2,
    CHERRY = 3,
    WALL_R = 4,
    WALL_B = 5,
    WALL_L = 6,
    WALL_T = 7,
    CORNER_RU = 8,
    CORNER_RD = 9,
    CORNER_LD = 10,
    CORNER_LU = 11,
    GHWALL_R = 12,
    GHWALL_B = 13,
    GHWALL_L = 14,
    GHWALL_T = 15,
    GHCORNER_RU = 16,
    GHCORNER_RD = 17,
    GHCORNER_LD = 18,
    GHCORNER_LU = 19,
    GHGATE_CLOSE = 20,
    GHGATE_OPEN = 21,
    LAUNCHER = 23,
}
Planet.shader = SHADER_PLANET;

function Planet:init(id,x,y)
    self.id = id
    self.x,self.y=x or 0,y or 0
    if id == 1 then
        local pos = Game.galaxy.getPlanetInChunk(0,0);
        self.x,self.y = pos.x,pos.y;
    end

    self.camera = {
        x=0,y=0,zoom=1,disX=0,disY=0,rot=0,
        drawPos={x=0,y=0,zoom=1,disX=0,disY=0},
        smoothness = 5,
        force = function(self)
            self.drawPos={x=self.x,y=self.y,disX=self.disX,disY=self.disY,zoom=self.zoom}
        end
    }
  
    self.state = "start1"
    self.previousState = "start1"
    self.exitUnlocked = false
    self.stateCounter = {
        chase=0,scatter=0,frightened=0,eating=0,start1=0,start2=0,death=0,finished=0
    }
    
    -- setting some sound variables
    self.sounds = {}
    self.sounds.start = res.sounds["retro-start"]
    self.sounds.siren = res.sounds["retro-move"]
    self.sounds.siren:setLooping(true)
    self.sounds.ghost_rush = res.sounds["retro-ghostrush"]
    self.sounds.ghost_rush:setLooping(true)
    self.sounds.ghost_escaping = res.sounds["retro-ghostrunning"]
    self.sounds.ghost_escaping:setLooping(true)
    
    -- pellet counter
    self.pellets = {}
    self.pellets.all = 0
    self.pellets.collected = 0
    self.pellets.percent = 0

    -- collectibles
    self.collectibles = {}
    
    self:generate()

    -- loading save
    self:load()
    
    -- creating canvases for nice planet drawing
    self.canvas = {
        map=love.graphics.newCanvas(self.size*8,self.size*8),
        game=love.graphics.newCanvas(self.size*32,self.size*32),
        refresh=true,
        firstDraw=true,
        refreshBlockList = {}
    } 
    -- some entities management
    self.entities = {}
    
    -- creating player
    local pacman = Pacman(self)
    pacman.x,pacman.y = self.size/2+0.5,self.size/2+8.5
    while(not self:isBlockPassable(pacman.x+2,pacman.y+1)) do 
        pacman.y = pacman.y+1 
    end
    table.insert(self.entities,pacman)
    self.player = pacman

    -- creating ghosts
    local names = {"blinky","pinky","inky","clyde","cringy","kinky","liney","bob"}
    if id == 1 then
        --guarantee the first planet will have 4 ghosts, one of each kind
        for i=1,4 do
            local ghost = Ghost(self,names[i])
            if i==1 then ghost.x,ghost.y = self.size/2+0.5,self.size/2-2.5
            else ghost.x,ghost.y = self.size/2+0.5+3*(i-3),self.size/2+0.5 end
            table.insert(self.entities,ghost)
        end
    else
        --random bullshit for new planets
        local params = Planet.getParams(self.id);
        local size = (params.size-36) / 42.0;

        local minGhosts = math.floor(4+size*10);
        local maxGhosts = math.floor(10+size*30);

        local ghostCount = minGhosts + params.randomizer:random(0, maxGhosts-minGhosts);

        for i=1,ghostCount do
            local ghostID = params.randomizer:random(1, #names);
            local ghost = Ghost(self,names[ghostID])
            if i==1 then ghost.x,ghost.y = self.size/2+0.5,self.size/2-2.5
            else 
                local oX = ((i-2)/(ghostCount-2)) * 7 - 3.5;
                local oY = (i%2-0.5)*1.5;
                ghost.x,ghost.y = self.size/2+0.5+oX,self.size/2+0.5+oY
            end

            --amogus
            if params.randomizer:random(100)==69 then
                ghost.isAmogus = true;
            end

            table.insert(self.entities,ghost)
        end
    end
    
    self.entSpawnPoints = {}
    for k,v in pairs(self.entities) do
        table.insert(self.entSpawnPoints,{x=v.x,y=v.y})
    end
end



function Planet:getBlock(x,y)
    local nx,ny = math.floor(x),math.floor(y)
    if nx<1 then nx = nx+self.size end
    if nx>self.size then nx = nx-self.size end
    if ny<1 then ny = ny+self.size end
    if ny>self.size then ny = ny-self.size end
    return self.map[ny][nx]
end

function Planet:setBlock(x,y,id)
    local nx,ny = math.floor(x),math.floor(y)
    if nx<1 then nx = nx+self.size end
    if nx>self.size then nx = nx-self.size end
    if ny<1 then ny = ny+self.size end
    if ny>self.size then ny = ny-self.size end
    if self.map[ny][nx]==1 and id~=1 then
        self.pellets.collected = self.pellets.collected+1
        
    end
    self.map[ny][nx] = id
    if self.canvas then 
        self.canvas.refresh = true 
        table.insert(self.canvas.refreshBlockList,{x=nx,y=ny})
    end
end

function Planet:isBlockPassable(x,y,ignoreBarrier,isGhost)
    local b = self:getBlock(x,y)
    if b==0 or b==1 or b==2 or b==3 or b==22 or b==23 or (not isGhost and b==21) then return true end
    if ignoreBarrier and (b==20 or b==21) then
        if (self:getBlock(x-1,y)==20 and self:getBlock(x+1,y)==20) 
        or (self:getBlock(x-1,y)==21 and self:getBlock(x+1,y)==21) then 
            return true 
        end
    end
    return false
end

function Planet:cameraUpdate(dt)

    -- updating shader external variables
    -- displacement before updating actual camera variables, because for some reason its bugged when doing after
    Planet.shader:send("displacement",{self.camera.drawPos.disX,self.camera.drawPos.disY})

    --camera follows the player
    if self.state~="start1" and not (self.state=="finished" and self.stateCounter.finished<3.5) then
        self.camera.x,self.camera.y = self.player.x,self.player.y
    end
    --camera adjustment
    if self.camera.x>self.size then 
        self.camera.x=self.camera.x-self.size 
        self.camera.drawPos.x = self.camera.drawPos.x-self.size
        Game.spacecam.drawPos.difX = Game.spacecam.drawPos.difX+self.size
    end
    if self.camera.x<0 then 
        self.camera.x=self.camera.x+self.size 
        self.camera.drawPos.x = self.camera.drawPos.x+self.size
        Game.spacecam.drawPos.difX = Game.spacecam.drawPos.difX-self.size
    end
    if self.camera.y>self.size then 
        self.camera.y=self.camera.y-self.size 
        self.camera.drawPos.y = self.camera.drawPos.y-self.size
        Game.spacecam.drawPos.difY = Game.spacecam.drawPos.difY+self.size
    end
    if self.camera.y<0 then 
        self.camera.y=self.camera.y+self.size 
        self.camera.drawPos.y = self.camera.drawPos.y+self.size
        Game.spacecam.drawPos.difY = Game.spacecam.drawPos.difY-self.size
    end
    self.camera.drawPos.x = self.camera.drawPos.x+(self.camera.x-self.camera.drawPos.x)/self.camera.smoothness
    self.camera.drawPos.y = self.camera.drawPos.y+(self.camera.y-self.camera.drawPos.y)/self.camera.smoothness
    self.camera.drawPos.zoom = self.camera.drawPos.zoom+(self.camera.zoom-self.camera.drawPos.zoom)/self.camera.smoothness
    self.camera.drawPos.disX = self.camera.drawPos.disX+(self.camera.disX-self.camera.drawPos.disX)/self.camera.smoothness
    self.camera.drawPos.disY = self.camera.drawPos.disY+(self.camera.disY-self.camera.drawPos.disY)/self.camera.smoothness   

    -- updating the rest of shader external variables
    Planet.shader:send("cam",{self.camera.drawPos.x/self.size,self.camera.drawPos.y/self.size})
    Planet.shader:send("zoom",self.camera.drawPos.zoom*(64/self.size))
    Planet.shader:send("rot",math.rad(self.camera.rot))
    Planet.shader:send("skyColor",self.skyColor)
end

function Planet:update(dt)
    if self.state=="complete" then
        if #self.entities>1 then
            for i=#self.entities,1,-1 do
                if not self.entities[i]:instanceof(Pacman) then table.remove(self.entities,i) end
            end
        end
        return
    end
    -- entities update
    if self.state=="chase" or self.state=="frightened" or self.state=="scatter" then
        for k,v in pairs(self.entities) do
            -- fixing entities position (looping around)
            if v.x>self.size then v.x=v.x-self.size end
            if v.x<0 then v.x = v.x+self.size end
            if v.y>self.size then v.y=v.y-self.size end
            if v.y<0 then v.y = v.y+self.size end
            -- updating the entity
            v:update(dt)
        end
    end
    
    -- music
    if self.state=="chase" or self.state=="scatter" then
        if not self.sounds.siren:isPlaying() then love.audio.play(self.sounds.siren) end
    elseif self.sounds.siren:isPlaying() then
        love.audio.pause(self.sounds.siren)
    end
    local isSomeoneEscaping = false
    for k,v in pairs(self.entities) do
        if v:instanceof(Ghost) and v.escaping then isSomeoneEscaping=true end
    end
    if self.state=="frightened" or self.state=="eating" then
        if isSomeoneEscaping then
        if not self.sounds.ghost_escaping:isPlaying() then love.audio.play(self.sounds.ghost_escaping) end
        if self.sounds.ghost_rush:isPlaying() then self.sounds.ghost_rush:pause() end
        else
        if self.sounds.ghost_escaping:isPlaying() then self.sounds.ghost_escaping:pause() end
        if not self.sounds.ghost_rush:isPlaying() then love.audio.play(self.sounds.ghost_rush) end
        end
    else
        if self.sounds.ghost_escaping:isPlaying() then self.sounds.ghost_escaping:pause() end
        if self.sounds.ghost_rush:isPlaying() then self.sounds.ghost_rush:pause() end
    end
    
    -- pellet percent counter for sound
    self.pellets.percent = self.pellets.collected/self.pellets.all
    self.sounds.siren:setPitch(1+self.pellets.percent/4)
    if self.pellets.percent == 1 then
        self.state = "complete"
    end

    if Game.spacman.fuel>Game.launchFuelUse*3 then 
        if self.id == 1 and Game.onFirstPlanet then
            if self.state~="finished" and (not self.exitUnlocked) then
                self:setState("finished")
            end
        elseif not self.exitUnlocked then
            self:unlockExit(false)
        end
    end
    
    
    -- state management
    if self.state=="start1" then
        if self.stateCounter.start1==0 then
            self.sounds.start:play()
            self.camera.x,self.camera.y = self.size/2+0.5,self.size/2+0.5
            self.camera.smoothness=10
        end
        self.stateCounter.start1=self.stateCounter.start1+dt
        if self.stateCounter.start1>2 then
            self.stateCounter.start1 = 0
            self:setState("start2" )
            self.camera.smoothness=15
        end
    elseif self.state=="start2" then
        self.player:updateInput()
        self.stateCounter.start2=self.stateCounter.start2+dt
        if self.stateCounter.start2>2.1 then 
            self.stateCounter.start2 = 0
            self.camera.smoothness=5
            self:setState("scatter")
        end
    elseif self.state=="scatter" then
        self.stateCounter.scatter=self.stateCounter.scatter+dt
        if self.stateCounter.scatter>7 then
            self.stateCounter.scatter = 0
            self.stateCounter.chase = 0
            self:setState("chase")
        end 
    elseif self.state=="chase" then
        self.stateCounter.chase=self.stateCounter.chase+dt
        if self.stateCounter.chase>10 then
            self.stateCounter.scatter = 0
            self.stateCounter.chase = 0
            self:setState("scatter")
        end
    elseif self.state=="frightened" then
        if self.stateCounter.frightened == 0 then
            if #self.entities>1 then
                for i=#self.entities,1,-1 do
                    self.entities[i].rotation = (self.entities[i].rotation + 180) % 360
                end
            end
        end
        self.stateCounter.frightened=self.stateCounter.frightened+dt
        if self.stateCounter.frightened>7 then
            self.stateCounter.frightened = 0
            self:setState("chase")
        end
    elseif self.state=="eating" then
        self.stateCounter.eating=self.stateCounter.eating+dt
        if self.stateCounter.eating>1 then
            self.stateCounter.eating = 0
            self:setState("frightened")
        end
    elseif self.state=="death" then
        self.stateCounter.death=self.stateCounter.death+dt
        if self.stateCounter.death>1.5 and self.stateCounter.death<2 then
            res.sounds["retro-rip"]:play()
            self.stateCounter.death=2
            if Game.lives<=0 then Game.isReallyDying = true end
        end

        if Game.isReallyDying then
            Game.spacman.noFuelTime = Game.spacman.noFuelTime + dt * 1.5;
        end

        if self.stateCounter.death>4 and Game.lives>0 then
            Game.lives = Game.lives-1
            for i,v in ipairs(self.entSpawnPoints) do
                self.entities[i].x,self.entities[i].y = v.x,v.y
                if self.entities[i].escaping then self.entities[i].escaping=false end
            end
            self:setState("start2")
            self.player.wantedDir = {x=-1,y=0}
            self.stateCounter.death=0
        end
    elseif self.state=="finished" then
        self.stateCounter.finished=self.stateCounter.finished+dt
        if self.stateCounter.finished>1 and self.stateCounter.finished<3.5 then
            self.camera.x,self.camera.y = self.size/2+0.5,self.size/2+0.5
            self.camera.smoothness=10
        else self.camera.smoothenss=5 end
        if self.stateCounter.finished>2.5 and (not self.exitUnlocked) then
            self:unlockExit(true)
        end
        if self.stateCounter.finished>4 then
            self:setState(self.previousState)
        end
    end
end

-- refreshes map canvas if refresh is needed
function Planet:refreshPlanet()
    if self.canvas.refresh then
        love.graphics.setCanvas(self.canvas.map)
        love.graphics.push()
        love.graphics.origin()

        -- refreshing map canvas
        --love.graphics.clear()
        love.graphics.setColor(1,1,1,1)
        self.canvas.map:setFilter("nearest","nearest")

        local refreshBlock = function(x,y)
            local id = self.map[y][x]
            local quad = love.graphics.newQuad((id%4)*8,math.floor(id/4)*8,8,8,self.tileset:getDimensions())
            love.graphics.draw(self.tileset,quad,(x-1)*8,(y-1)*8)
        end

        if self.canvas.firstDraw then
            for y=1,self.size do for x=1,self.size do
                refreshBlock(x,y)
            end end
            self.canvas.firstDraw = false
            Planet.shader:send("textureSize",{self.canvas.game:getWidth(),self.canvas.game:getHeight()})
        else
            for i,pos in ipairs(self.canvas.refreshBlockList) do
                refreshBlock(pos.x,pos.y)
            end
        end
        
        love.graphics.pop()
        love.graphics.setCanvas()
        self.canvas.refresh = false
        self.canvas.refreshBlockList = {}
    end
end

function Planet:draw()
    local r,g,b,a = love.graphics.getColorOld()
    self:refreshPlanet()
    -- drawing entities
    love.graphics.push()
    love.graphics.reset()
    love.graphics.setCanvas(self.canvas.game)
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.clear()

    love.graphics.scale(4)
    love.graphics.setColorOld(255,255,255,255)
    love.graphics.draw(self.canvas.map,0,0)
    -- drawing entities a few times (borderless world)
    for x=-1,1 do for y=-1,1 do 
        love.graphics.push()
        love.graphics.translate(x*self.size*8,y*self.size*8)
        for k,v in pairs(self.entities) do
            v:draw()
        end
        love.graphics.pop()
    end end
    love.graphics.setColorOld(r,g,b,a)
    love.graphics.setCanvas()
    love.graphics.pop()

    -- drawing planet texture using shader
    love.graphics.push()
    love.graphics.setShader(Planet.shader)
    love.graphics.scale(1/(self.size*32))
    love.graphics.translate(-self.size*16,-self.size*16)
    love.graphics.draw(self.canvas.game,0,0)
    love.graphics.setShader()
    love.graphics.pop()

    -- debug tileset draw

    -- love.graphics.push()
    -- love.graphics.reset()
    -- love.graphics.scale(4)
    -- love.graphics.draw(self.tileset,0,0)
    -- love.graphics.pop()
end


function Planet:setState(state)
    self.previousState = self.state
    self.state = state
end

function Planet.getParams(id)
    local params = {}
    local randomizer = love.math.newRandomGenerator(Game.seed+id)
    params.randomizer = randomizer
    local h = id==1 and 160 or (randomizer:random())*256
    local s = id==1 and 256 or (0.7 + 0.3*randomizer:random())*256
    local v = id==1 and 128 or (0.4 + 0.3*randomizer:random())*256
    local r,g,b = HSV(h,s,v)
    params.skyColor = {r/256,g/256,b/256,1}
    params.size = id==1 and 42 or 36+randomizer:random(7)*6 --min 36 max 76
    params.tilesetID = id==1 and 1 or (id%10000)+1
    return params
end


function Planet:unlockExit(cutscene)
    for i=0,2 do self:setBlock(self.size/2+i,self.size/2-1,21) end
    self.exitUnlocked = true

    local unlockSound = res.sounds["retro-door-open"]
    unlockSound:play()
    if not cutscene then unlockSound:setVolume(0.3) end
end

-- procedurally generates random tileset
function Planet:generateTileset(id)
    if not self.tileset then 
        self.tileset = love.graphics.newCanvas(32,48)
        self.tileset:setFilter("nearest","nearest")
    end
    love.graphics.push()
    love.graphics.reset()
    love.graphics.setColorOld(255,255,255,255)
    
    love.graphics.setCanvas(self.tileset)
    love.graphics.clear(0,0,0,1)
    
    -- generating pellets
    local randomizer = love.math.newRandomGenerator(id)
    local pelletcenter = randomizer:random(1,2)==1
    local pelletsides1 = (not pelletcenter) and true or randomizer:random(1,3)==1
    local pelletsides2 = (not pelletcenter) and true or randomizer:random(1,3)==1

    love.graphics.setColorOld(255,240,220)
    if pelletcenter then 
        love.graphics.rectangle("fill",11,3,2,2) 
    end 
    if pelletsides1 and id~=1 then
        love.graphics.rectangle("fill",10,3,1,2) 
        love.graphics.rectangle("fill",13,3,1,2) 
    end 
    if pelletsides2 and id~=1 then
        love.graphics.rectangle("fill",11,2,2,1)
        love.graphics.rectangle("fill",11,5,2,1)
    end

    -- generating powerup
    love.graphics.setColorOld(200,150,70)
    love.graphics.rectangle("fill",18,0,4,8)
    love.graphics.rectangle("fill",16,2,8,4)
    if randomizer:random(3) > 1 or id==1 then
        love.graphics.rectangle("fill",17,1,6,6)
    end
    if randomizer:random(3)==1 and id~=1 then
        love.graphics.setColorOld(0,0,0)
        love.graphics.rectangle("fill",18,2,4,4)
        love.graphics.setColorOld(200,150,70)
        if randomizer:random(3) > 1 then
            love.graphics.rectangle("fill",19,3,2,2)
        end
    end

    -- generating walls
    local wallR,wallG,wallB = HSV(randomizer:random(0,255), 128 + randomizer:random(0,127), 200);
    if id==1 then wallR,wallG,wallB = 0,0,255 end
    love.graphics.setColorOld(wallR,wallG,wallB)

    local wallEdgeType = randomizer:random(1,3);

    for x=1,4 do for y=1,4 do
        love.graphics.push();
        love.graphics.translate(4+(x-1)*8,12+(y-1)*8)
        love.graphics.rotate(math.rad((x-1)*90))
        if y==1 then
            love.graphics.rectangle("fill",0,-4,1,8)
        end
        if y==2 then
            if wallEdgeType==2 or id==1 then
                love.graphics.rectangle("fill",0,-4,1,2)
                love.graphics.rectangle("fill",1,-2,1,1)
                love.graphics.rectangle("fill",2,-1,2,1)
            elseif wallEdgeType==1 then
                love.graphics.rectangle("fill",0,-4,1,4)
                love.graphics.rectangle("fill",1,-1,3,1)
            else
                love.graphics.rectangle("fill",0,-4,1,1)
                love.graphics.rectangle("fill",1,-3,1,1)
                love.graphics.rectangle("fill",2,-2,1,1)
                love.graphics.rectangle("fill",3,-1,1,1)
            end
        end
        if y==3 then
            love.graphics.rectangle("fill",0,-4,1,8)
            love.graphics.rectangle("fill",3,-4,1,8)
        end
        if y==4 then
            love.graphics.rectangle("fill",0,-4,1,4)
            love.graphics.rectangle("fill",1,-1,3,1)
            love.graphics.rectangle("fill",3,-4,1,1)
        end
        love.graphics.pop();
    end end

    -- ghost house doors
    love.graphics.setColorOld(255,240,220)
    love.graphics.rectangle("fill",0,45,8,2);

    love.graphics.setColorOld(136,0,21)
    love.graphics.rectangle("fill",8,45,1,2);
    love.graphics.rectangle("fill",11,45,2,2);
    love.graphics.rectangle("fill",15,45,1,2);

    -- launcher
    love.graphics.setColorOld(153,213,254)
    love.graphics.rectangle("fill", 16, 40, 8, 8);
    love.graphics.setColorOld(0,0,0)
    love.graphics.rectangle("fill", 17, 41, 6, 6);
    love.graphics.setColorOld(153,213,254)
    love.graphics.rectangle("fill", 18, 42, 4, 4);
    love.graphics.setColorOld(0,0,0)
    love.graphics.rectangle("fill", 19, 43, 2, 2);

    -- launcher 2
    love.graphics.setColorOld(63,72,204)
    love.graphics.rectangle("fill", 24, 40, 8, 8);
    love.graphics.setColorOld(0,0,0)
    love.graphics.rectangle("fill", 25, 41, 6, 6);
    love.graphics.setColorOld(63,72,204)
    love.graphics.rectangle("fill", 26, 42, 4, 4);
    love.graphics.setColorOld(0,0,0)
    love.graphics.rectangle("fill", 27, 43, 2, 2);

    -- cherry
    love.graphics.setColorOld(255,255,255)
    love.graphics.draw(res.images.cherry, 24,0);

    love.graphics.setCanvas()
    love.graphics.pop()
end


-- generates map for a planet
function Planet:generate()
    local params = Planet.getParams(self.id)
    local randomizer = params.randomizer
    self.map = {}
    self.skyColor = params.skyColor
    self.size = params.size
    local size = self.size
    for y=1,size do
        if not self.map[y] then self.map[y] = {} end
        for x=1,size do
        self.map[y][x] = 2
        end
    end
    self:generateTileset(params.tilesetID)
    
    -- generating level
    local celldirs = {
        {x=-1,y=0,dir="left",odir="right"},
        {x=1,y=0,dir="right",odir="left"},
        {x=0,y=-1,dir="up",odir="down"},
        {x=0,y=1,dir="down",odir="up"}
    }
    local cells = {}
    local cell_width,cell_height = size/3,size/3
    for y=1,cell_height do if not cells[y] then cells[y]= {} end end
    
    -- creating the box for ghosts
    cells[cell_height/2][cell_width/2] = {up=false,down=true,left=true,right=true} 
    cells[cell_height/2+1][cell_width/2] = {up=true,down=false,left=true,right=true} 
    cells[cell_height/2][cell_width/2-1] = {up=false,down=true,left=false,right=true} 
    cells[cell_height/2+1][cell_width/2-1] = {up=true,down=false,left=false,right=true} 
    
    -- generating only half of maze, second half will be mirrored version of this one
    for y=1,cell_height do
        for x=1,cell_width/2 do
            if not cells[y][x] then 
                local cur = {x=0,y=0}
                local cellCount = 2+randomizer:random(y*5+x*2+31)%4
                cells[y][x] = {up=false,down=false,left=false,right=false} -- connections between cells
                for i=1,cellCount do
                    local possibleCells = {}
                    if x+cur.x>1 and cur.x>-2 and (not cells[y+cur.y][x+cur.x-1] or cells[y+cur.y][x+cur.x-1].right) then 
                        table.insert(possibleCells,celldirs[1]) end
                    if x+cur.x<cell_width/2 and cur.x<2 and (not cells[y+cur.y][x+cur.x+1] or cells[y+cur.y][x+cur.x+1].left) then 
                        table.insert(possibleCells,celldirs[2]) end
                    if y+cur.y>1 and cur.y>-2 and (not cells[y+cur.y-1][x+cur.x] or cells[y+cur.y-1][x+cur.x].down) then 
                        table.insert(possibleCells,celldirs[3]) end
                    if y+cur.y<cell_height and cur.y<2 and (not cells[y+cur.y+1][x+cur.x] or cells[y+cur.y+1][x+cur.x].up) then 
                        table.insert(possibleCells,celldirs[4]) end
                    if #possibleCells==0 then break end
                    local target = possibleCells[randomizer:random(y*2+x*7+25)%#possibleCells+1]
                    cells[y+cur.y][x+cur.x][target.dir] = true
                    cur.x,cur.y = cur.x+target.x,cur.y+target.y
                    if cells[y+cur.y][x+cur.x] then
                        i = i-1
                    else cells[y+cur.y][x+cur.x] = {up=false,down=false,left=false,right=false} end
                    cells[y+cur.y][x+cur.x][target.odir] = true
                    -- creating rectangular blocks from "U" ones
                    if i==cellCount and ((cur.x==0 and (cur.y==-1 or cur.y==1)) or (cur.y==0 and (cur.x==-1 or cur.x==1))) then
                        local celldir = nil
                        for k,cdir in pairs(celldirs) do
                            if cdir.x==cur.x and cdir.y==cur.y then celldir = cdir ; break end
                        end
                        if celldir then
                            cells[y][x][celldir.dir] = true
                            cells[y+cur.y][x+cur.x][celldir.odir] = true
                        end
                    end
                end
            end
        end
    end
    --[[
    -- connect random walls from end of the map
    for i=1,randomizer:random(990308)%2+2 do
        if i%2==0 then
        local xpos = 1+randomizer:random(size+i+19)%(cw/2)
        if cells[1][xpos] then cells[1][xpos].up = true end
        if cells[ch][xpos] then cells[ch][xpos].down = true end
        end
        local ypos = randomizer:random(size+i+29)%ch+1
        if cells[ypos][1] then cells[ypos][1].left = true end
    end]]--
    
    -- duplicate generated map for second half
    for y=1,cell_height do for x=cell_width/2+1,cell_width do
        local cell = cells[y][cell_width+1-x]
        cells[y][x] = {up=cell.up,down=cell.down,left=cell.right,right=cell.left}
    end end

    -- convert cells to tiles
    for y=1,cell_height do for x=1,cell_width do
        local cx,cy = (x-1)*3+1,(y-1)*3+1
        
        local cell = cells[y][x] or {}
        if not cell.up then for i=0,3 do self.map[cy][math.min(cx+i,size)]=1 end end
        if not cell.left then for i=0,3 do self.map[math.min(cy+i,size)][cx]=1 end end
    end end

    -- flood fill to mark reachable cells
    local reachable = {}
    for y=1,size do reachable[y] = {} end
    local queue = {}
    local startX, startY = math.floor(size/2), math.floor(size/2)
    table.insert(queue, {x=startX, y=startY})
    reachable[startY][startX] = true
    while #queue > 0 do
        local node = table.remove(queue, 1)
        local x, y = node.x, node.y
        for _, dir in ipairs({{0,1},{0,-1},{1,0},{-1,0}}) do
            local nx, ny = x+dir[1], y+dir[2]
            if nx >= 1 and nx <= size and ny >= 1 and ny <= size then
                if not reachable[ny][nx] and self:getBlock(nx,ny) ~= Planet.tiles.WALL_R and self:getBlock(nx,ny) ~= Planet.tiles.WALL_L and self:getBlock(nx,ny) ~= Planet.tiles.WALL_T and self:getBlock(nx,ny) ~= Planet.tiles.WALL_B then
                    reachable[ny][nx] = true
                    table.insert(queue, {x=nx, y=ny})
                end
            end
        end
    end

    -- remove pellets from unreachable cells
    for y=1,size do for x=1,size do
        if self:getBlock(x,y) == Planet.tiles.PELLET and not reachable[y][x] then
            self.map[y][x] = Planet.tiles.AIR
        end
    end end

    -- creating good looking walls
    for y=1,size do for x=1,size do
        if self:getBlock(x,y)==2 then
            local remove = true
            for by=-2,2 do for bx=-2,2 do
                if self:getBlock(x+bx,y+by)~=2 then 
                    remove = false
                    break
                end
            end end
            if remove then for by=-1,1 do for bx=-1,1 do
                self.map[y+by][x+bx] = 0
            end end end
        end
    end end


    -- debug print
    --[[
    local mapStr = "";
    for y=1,size do 
        for x=1,size do
            mapStr = mapStr..(self:getBlock(x,y)==2 and "#" or "-");
        end
        mapStr = mapStr.."\n"
    end
    print(mapStr)
    ]]--


    -- creating good looking walls
    for y=1,size do for x=1,size do
        if self:getBlock(x,y)==2 then
            local id = 3
            local cb = {}
            for by=-1,1 do for bx=-1,1 do
                local bid = self:getBlock(x+bx,y+by)~=1
                table.insert(cb,bid)
            end end
            -- walls 
            if cb[4] and cb[6] and not cb[2] then id = Planet.tiles.WALL_B
            elseif cb[4] and cb[6] and not cb[8] then id = Planet.tiles.WALL_T
            elseif cb[2] and cb[8] and not cb[6] then id = Planet.tiles.WALL_L
            elseif cb[2] and cb[8] and not cb[4] then id = Planet.tiles.WALL_R
            -- corners (inner)
            elseif cb[2] and cb[4] and cb[9] and not cb[1] then id = Planet.tiles.CORNER_LU
            elseif cb[8] and cb[4] and cb[3] and not cb[7] then id = Planet.tiles.CORNER_LD
            elseif cb[8] and cb[6] and cb[1] and not cb[9] then id = Planet.tiles.CORNER_RD
            elseif cb[2] and cb[6] and cb[7] and not cb[3] then id = Planet.tiles.CORNER_RU
            -- corners (outer)
            elseif cb[2] and cb[6] and not cb[7] then id = Planet.tiles.CORNER_RU
            elseif cb[8] and cb[6] and not cb[1] then id = Planet.tiles.CORNER_RD
            elseif cb[8] and cb[4] and not cb[3] then id = Planet.tiles.CORNER_LD
            elseif cb[2] and cb[4] and not cb[9] then id = Planet.tiles.CORNER_LU
            else id = Planet.tiles.PELLET end
            
            self.map[y][x] = id
        end
    end end
    
    -- creating ghost hood
    local cen=size/2+1
    for x=cen-7,cen+7 do for y=cen-4,cen+4 do
        if x>=cen-1 and x<=cen+1 and y==cen-2 then
            self.map[y][x] = Planet.tiles.GHGATE_CLOSE
        elseif x==cen and y==cen then
            self.map[y][x] = Planet.tiles.LAUNCHER
        elseif x==cen-5 then
            if y==cen-2 then
                self.map[y][x] = Planet.tiles.GHCORNER_RD
            elseif y==cen+2 then
                self.map[y][x] = Planet.tiles.GHCORNER_RU
            elseif y>cen-2 and y<cen+2 then
                self.map[y][x] = Planet.tiles.GHWALL_R
            end
        elseif x==cen+5 then
            if y==cen-2 then
                self.map[y][x] = Planet.tiles.GHCORNER_LD
            elseif y==cen+2 then
                self.map[y][x] = Planet.tiles.GHCORNER_LU
            elseif y>cen-2 and y<cen+2 then
                self.map[y][x] = Planet.tiles.GHWALL_L
            end
        elseif x>cen-5 and x<cen+5 then
            if y==cen-2 then
                self.map[y][x] = Planet.tiles.GHWALL_B
            elseif y==cen+2 then
                self.map[y][x] = Planet.tiles.GHWALL_T
            elseif y>cen-2 and y<cen+2 then
                self.map[y][x] = Planet.tiles.AIR
            end
        end
        if self.map[y][x]==Planet.tiles.PELLET then 
            self.map[y][x] = Planet.tiles.AIR
        end
    end end
    
    -- counting pellets and creating collectibles
    for y=1,size do for x=1,size do
        if self:getBlock(x,y)==1 then
            local corner = 0
            for by=-1,1,2 do for bx=-1,1,2 do
                local bid = self:getBlock(x+bx,y+by)
                if bid==8 or bid==9 or bid==10 or bid==11 then
                    corner=corner+1
                end
            end end
            if corner>1 and corner<3 then
                if randomizer:random(self.id==1 and 150 or 250)==1 then 
                    self.map[y][x]=Planet.tiles.POWER
                elseif randomizer:random(400)==1 then 
                    self.map[y][x]=Planet.tiles.CHERRY
                end
            end
            if self.map[y][x]==1 then
                self.pellets.all = self.pellets.all+1 
            end
            table.insert(self.collectibles,{x=x,y=y})
        end
    end end
end

-- saves planet as a bitmask of collected objects
function Planet:save()
    local collectiblesBits = {}
    for i,v in ipairs(self.collectibles) do
        local collected = 0
        if self.map[v.y][v.x] == 0 then collected = 1 end
        table.insert(collectiblesBits,collected)
    end
    if not SAVE.planets then SAVE.planets = {} end
    SAVE.planets[self.id] = bitsToBase64(collectiblesBits)
    print("Saved planet, ID:"..self.id..", data:"..SAVE.planets[self.id])
end

-- loads planet as a bitmask of collected objects (removes collected objects from the map)
function Planet:load()
    if SAVE.planets and SAVE.planets[self.id] then
        local collectiblesBits = base64ToBits(SAVE.planets[self.id])
        for i,v in ipairs(self.collectibles) do
            if collectiblesBits[i]==1 then
                self:setBlock(v.x,v.y,0)
            end
        end
        return true
    end
    return false
end


function Planet:collectCherry(x,y)
    self:setBlock(x, y,0)
    Game.cherries = Game.cherries+1
    res.sounds["retro-cherry"]:play()
    if Game.cherries == Game.requiredCherries then
        res.sounds["cherry-enough"]:play()
    end
end

function Planet:unloadSounds()
    self.sounds.siren:stop()
    self.sounds.ghost_rush:stop()
    self.sounds.ghost_escaping:stop()
end