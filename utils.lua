--[[
	A bunch of random helper functions I've stolen from the internet and made myself
]]--

Utils = {}

Utils.base64numbers = {A=0,B=1,C=2,D=3,E=4,F=5,G=6,H=7,I=8,J=9,K=10,L=11,M=12,N=13,O=14,P=15,Q=16,R=17,S=18,T=19,U=20,V=21,W=22,X=23,Y=24,Z=25,a=26,b=27,c=28,d=29,e=30,f=31,g=32,h=33,i=34,j=35,k=36,l=37,m=38,n=39,o=40,p=41,q=42,r=43,s=44,t=45,u=46,v=47,w=48,x=49,y=50,z=51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["+"]=62,["/"]=63}
Utils.base64chars = {"A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z","a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z","0","1","2","3","4","5","6","7","8","9","+","/"}

function bitsToBase64(bits)
  local baseText = ""

  local currentChar = 0
  local bitCount = 0
  for i,v in ipairs(bits) do
    currentChar = currentChar*2 + v
    bitCount = bitCount + 1
    if bitCount>=6 then
      baseText = baseText..Utils.base64chars[currentChar+1]
      currentChar = 0
      bitCount = 0
    end
  end
  baseText = baseText..Utils.base64chars[currentChar+1]

  return baseText
end



function base64ToBits(baseText)
  local chars = {}
  for c in baseText:gmatch"." do table.insert(chars,c) end

  local bits = {}

  for i,c in ipairs(chars) do
    local charBits = {}
    local byte = Utils.base64numbers[c]
    for i=0,5 do
      local bit = byte%2
      table.insert(charBits,bit)
      byte = (byte-bit)/2
    end
    for i=0,5 do
      table.insert(bits, charBits[6-i])
    end
  end
  return bits
end

--number to string with decimal format
--format example: xx.xxx
--"x" give number in specific position relative to dot
--"o" give all numbers from beggining to position relative to dot
--if there is not dot, dot position equals (length of f) + 1
function decimalFormat(number,f)
  local dot = f:find("%.") or f:len()+1
  local snumber = tostring(number)
  local sdot = snumber:find("%.") or snumber:len()+1
  local output = ""
  for i=1,f:len() do
    if i~=dot then
      local pos = sdot+(i-dot)
      local fchar = f:sub(i,i)
      local char = "0"
      if fchar=="x" then
        char = (pos>snumber:len() or pos<=0) and "0" or snumber:sub(pos,pos)
      elseif fchar=="o" then
        char = (pos>snumber:len() or pos<=0) and "0" or snumber:sub(1,pos)
      end
      output = output..char
    else output=output.."." end
  end
  return output
end


--converts number into a nice time text
function timeFormat(number)
	local minutes = math.floor(number/60.0);
	local seconds = number%60;

	if minutes >= 10 then
		return minutes .. ":" .. decimalFormat(seconds,"xx.xx")
	else
		return minutes .. ":" .. decimalFormat(seconds,"xx.xxx")
	end
end



-- Converts HSV to RGB. (input and output range: 0 - 255)
function HSV(h, s, v)
    if s <= 0 then return v,v,v end
    h, s, v = h/256*6, s/255, v/255
    local c = v*s
    local x = (1-math.abs((h%2)-1))*c
    local m,r,g,b = (v-c), 0,0,0
    if h < 1     then r,g,b = c,x,0
    elseif h < 2 then r,g,b = x,c,0
    elseif h < 3 then r,g,b = 0,c,x
    elseif h < 4 then r,g,b = 0,x,c
    elseif h < 5 then r,g,b = x,0,c
    else              r,g,b = c,0,x
    end return (r+m)*255,(g+m)*255,(b+m)*255
end


-- hack! fix 11.0 conversion of setColor
function love.graphics.setColorOld(r,g,b,a)
	if type(r) == "table" then
		a = r[4] or 255
		b = r[3] or 0
		g = r[2] or 0
		r = r[1] or 0
	end

	a = a or 255
	love.graphics.setColor(r/255.0,g/255.0,b/255.0,a/255)
end

function love.graphics.getColorOld()
	local r,g,b,a = love.graphics.getColor()
	return r*255,g*255,b*255,a*255
end