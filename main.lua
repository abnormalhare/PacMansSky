
--[[
    Greetings, random person.
    If you're reading this, you've managed to reach the source code of this game.
    I have no idea what are your intentions, but here are a couple of notes, in
    case you actually want to do something about it.
    
    I've started developing this code in 2017, and in the span of 4 years, I've
    been working on it sporadically (maybe once a year). Because of that, this
    is a complete mess, full of random, ugly and undocumented code, made by
    different versions of me, being at different stage of skill level, and NEVER
    being motivated enough to refactor the whole thing.

    If you really want to mess with it, be advised that you may lose your sanity,
    or at best, you may lose a faith that I'm a decent programmer.

    If you're planning to do anything with this code, make sure you credit me, but
    also make sure to let people know that they shouldn't judge my skills by it.
    I'm both proud and ashamed of it.

    ~Krzyhau, September 2021
]]


_loopCalls = {}

_SCORE = 0;
_TIME = 0;
_SEED = 0;

_RUNTIME = 0;

function addLoopCall(func)
    _loopCalls[func] = true
end

function removeLoopCall(func)
    _loopCalls[func]=nil
end


function love.load()
    --require("slam")
    require("queue")

    require("class")
    require("input")
    require("utils")
    require("vector")
    require("particles")

    require("game/shaders")
    require("game/game")
    require("game/menu")
    require("game/intro")
    require("game/death")
    require("game/win")
    
    require("game/planet")
    require("game/pacman")
    require("game/ghost")


    gametitle = "Pac-Man's Sky"
    windowWidth = 1280
    windowHeight = 720
    windowMode = {msaa=0}
    gamestate = 0
    --[[
    love.window.setTitle(gametitle)
    love.window.setMode(windowWidth,windowHeight,windowMode)

    love.filesystem.setIdentity(gametitle)
    if not love.filesystem.exists(love.filesystem.getSaveDirectory()) then
        love.filesystem.createDirectory(love.filesystem.getSaveDirectory())
    end]]--

    --I don't need saving planets to a file now
    --SAVE = table.load("SAVE") or {}
    SAVE = {}
    --CONFIG = table.load("CONFIG") or {}
    CONFIG = {}

    love.graphics.setDefaultFilter("nearest", "nearest")
    res = {}
    res.images = {}
    local imagenames = love.filesystem.getDirectoryItems("graphics/")
    for i=1,#imagenames do
        local dotpos = imagenames[i]:find("%.") or imagenames[i]:len()
        local name = imagenames[i]:sub(1,dotpos-1)
        res.images[name]=love.graphics.newImage("graphics/"..imagenames[i])
    end

    res.sounds = {}
    local soundnames = love.filesystem.getDirectoryItems("sounds/")
    local soundlongone={} --to kurde jakies cos nie wiem czemu tego nie uzupelnilem
    for i=1,#soundnames do
        local dotpos = soundnames[i]:find("%.")
        local name = soundnames[i]:sub(1,dotpos-1)
        res.sounds[name]=love.audio.newSource("sounds/"..soundnames[i], (soundlongone[i] and "stream" or "static"))
        if name:sub(1,5)=="retro" then res.sounds[name]:setVolume(0.6) end
    end
    love.audio.setVolume(0.2)

    res.fonts = {}
    res.fonts.default = love.graphics.newImageFont("fonts/default.png", " ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890.,!?-+/():;*=[]{}'%<>",1)
    res.fonts.default:setLineHeight(1.5)
    love.graphics.setFont(res.fonts.default)

    setGamestate("menu")
end

function love.update(dt)
    _RUNTIME = _RUNTIME+dt
    for k,v in pairs(_loopCalls) do k(dt) end
    if _G[gamestate.."_update"] then
        _G[gamestate.."_update"](dt)
    end
end

function love.draw()
	if _G[gamestate.."_draw"] then
		_G[gamestate.."_draw"]()
	end
end

function love.keypressed(key)
	if _G[gamestate.."_keypressed"] then
		_G[gamestate.."_keypressed"](key)
	end
end

function love.keyreleased(key)
	if _G[gamestate.."_keyreleased"] then
		_G[gamestate.."_keyreleased"](key)
	end
end

function setGamestate(gs)
    --reset all sounds
    for k,sound in pairs(res.sounds) do
        sound:stop()
    end

    if gs=="!q" then
        love.event.quit()
    end
    gamestate = gs
    if _G[gamestate.."_init"] then
        _G[gamestate.."_init"]()
    end
end