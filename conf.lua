function love.conf(t)
    t.identity = "PACMANSKY"
    t.window.title = "Pac Man's Sky"
    t.version = "11.3" 
    t.window.width = 1280
    t.window.height = 720
    t.window.msaa = 0

    t.modules.audio = true
    t.modules.data = false
    t.modules.event = true
    t.modules.font = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.joystick = false
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = true 
    t.modules.system = false
    t.modules.thread = false
    t.modules.timer = true
    t.modules.touch = false
    t.modules.video = true
    t.modules.window = true
end