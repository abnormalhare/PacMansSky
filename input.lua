Input = {}
Input.rawkeytyped = {}
Input.keytyped = {}
Input.rawkeyreleased = {}
Input.keyreleased = {}
Input.rawmousetyped = {}
Input.mousetyped = {}
Input.rawmousereleased = {}
Input.mousereleased = {}
Input.rawwheelmovement = 0
Input.wheelmovement = 0

function love.keypressed(key,scancode,isrepeat)
  Input.rawkeytyped[key] = true
end

function love.keyreleased(key)
  Input.rawkeyreleased[key] = true
end

function love.mousepressed(x,y,button,touch)
  Input.rawmousetyped[button] = true
end

function love.mousereleased(x,y,button,touch)
  Input.rawmousereleased[button] = true
end

function Input.isKeyPressed(key)
  return love.keyboard.isDown(key)
end

function Input.isKeyTyped(...)
  for i,key in ipairs({...}) do
    if Input.keytyped[key] then return true end
  end
  return false
end

function Input.isKeyReleased(key)
  return Input.keyreleased[key]
end

function Input.isMousePressed(button,...)
  return love.mouse.isDown(button,...)
end

function Input.isMouseTyped(key)
  return Input.mousetyped[key]
end

function Input.isMouseReleased(key)
  return Input.mousereleased[key]
end

function love.wheelmoved(x,y)
  Input.rawwheelmovement = y
end

function Input.update()
  Input.keytyped = Input.rawkeytyped
  Input.keyreleased = Input.rawkeyreleased
  Input.rawkeytyped = {}
  Input.rawkeyreleased = {}
  Input.mousetyped = Input.rawmousetyped
  Input.mousereleased = Input.rawmousereleased
  Input.rawmousetyped = {}
  Input.rawmousereleased = {}
  
  Input.wheelmovement=Input.rawwheelmovement
  Input.rawwheelmovement = 0
end

function Input.getMousePosition()
  return love.mouse.getX(),love.mouse.getY()
end

function Input.getWheelMovement()
  return Input.wheelmovement
end

addLoopCall(Input.update)