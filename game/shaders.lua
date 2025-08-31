-- simple shader for moving stars in space
SHADER_SPACE = love.graphics.newShader[[
    extern vec2 pos;
    extern float rot;
    
    float rand(vec2 co){
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }
    
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc)
    {
        vec2 pcn = vec2(tc.x-0.5,tc.y-0.5);
        float alpha = 0.0;
        for(float i=1.0;i<20.0;i++){
            vec2 pcnr = vec2(0.5-(pos.x+100.0)/(i+5.0)+pcn.x*cos(rot)-pcn.y*sin(rot),0.5-(pos.y-50.0)/(i+5.0)+pcn.y*cos(rot)+pcn.x*sin(rot));
            float d = 200.0+i*100.0;
            float r = rand(vec2(floor(pcnr.x*d)/d,floor(pcnr.y*d)/d));
            if(r>0.9992)return vec4(1.0/i,1.0/i,1.0/i,color.w);
        }
    }
]]


-- planet shader - render 2d image as a rotating sphere
SHADER_PLANET = love.graphics.newShader[[
    const float pi = 3.14159265;
    const float pi2 = 2.0 * pi;

    extern vec2 textureSize;
    extern vec2 cam;
    extern vec2 displacement;
    extern vec4 skyColor;
    extern float zoom;
    extern float rot;

    vec4 TexelPixelated(Image texture, vec2 p, vec2 texSize)
    {
        return Texel(texture, vec2((floor(p.x*texSize.x)+0.5)/texSize.x, (floor(p.y*texSize.y)+0.5)/texSize.y));
    }

    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pixel_coords)
    {
        // if(tc.x >= 0) return Texel(texture, tc*2.0-vec2(0.5,0.5));
        
        // creating sphere "coordinates"
        vec2 tcc = vec2(tc.x-0.5,tc.y-0.5);
        vec2 p = 2.0 * zoom * (vec2(tcc.x*cos(rot)-tcc.y*sin(rot), tcc.y*cos(rot)+tcc.x*sin(rot)) - displacement);
        float r = length(p);

        // returning sky if outside of sphere
        vec4 skyColorA = vec4(skyColor.r,skyColor.g,skyColor.b,color.a);
        if (r > 1.0)return mix(skyColorA,vec4(0,0,0,0),min(r-1.0,1.0));

        // mapping sphere coordinates into map coordinates
        vec2 newCoord = mod(asin(r) * p / (pi * r) + cam, 1.0);
        
        vec4 surfaceColor = TexelPixelated(texture, newCoord, textureSize);

        // 3d effects
        if(length(vec3(surfaceColor))<0.05){
            for(float i=0.0;i<10.0;i++){
                vec2 testCoords = newCoord + p*0.001*i;
                vec4 testColor = TexelPixelated(texture, testCoords, textureSize);
                if(length(vec3(testColor))>0.5){
                    surfaceColor = testColor * 0.5;
                    surfaceColor.a = 1.0;
                    break;
                }
            }
        }

        vec4 sphereColor = color * surfaceColor;
        sphereColor = mix(sphereColor, skyColorA, 1.0-surfaceColor.a);
        
        return mix(sphereColor,mix(vec4(0.0,0.0,0.0,color.a),skyColorA,max(0.0,(r-0.95)*10.0)),max(0.0,r-0.5));
    }
]]

-- warp speed star fucking woooooooooooo
SHADER_WARP = love.graphics.newShader[[
    extern float time;
    
    float rand(vec2 co){
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }

    float getLineColor(vec2 pos){
        float rayRange = 0.3;
        float xRange = 0.8 + rand(vec2(pos.y,pos.y))*20.0;
        float zoomTime = time * 1.5 * (1.0+sin(xRange)*0.8);
        float xOffset = zoomTime + rand(vec2(pos.y,pos.y+1.0))*10.0;
        float xDist = abs(mod(pos.x+xOffset,xRange)-rayRange);

        float value = max(0.0,rayRange-xDist)/rayRange;
        return value;
    }

    float getBlurLineColor(vec2 pos){
        float sum = 0.0;
        float steps = 0.0;

        const float radius = 0.2;
        const float step = 0.005;

        float fixY = pos.y - mod(pos.y,step);

        for(float i=0.0;i<radius;i+=step){
            sum += getLineColor(vec2(pos.x,fixY+i)) / (steps+1.0);
            sum += getLineColor(vec2(pos.x,fixY-i)) / (steps+1.0);
            steps++;
        }

        return sum * 0.5;
    }
    
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc)
    {
        float v = getBlurLineColor(tc);
        float yMult = (0.4 + sin(tc.y*3.14159265)*0.8);
        float xMult = max(1.0-tc.x,0.5);
        return color * vec4(pow(v,1.5),pow(v,1.3),v,1.0) * min(xMult,yMult);
    }
]]


-- warp speed radial
SHADER_WARP_RADIAL = love.graphics.newShader[[
    extern float time;
    
    float rand(vec2 co){
        return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
    }

    float getLineColor(vec2 pos){
        float rayRange = 0.02;
        float xRange = 0.8 + rand(vec2(pos.y,pos.y))*10.0;
        float zoomTime = time * 1.5 * (1.0+sin(xRange)*0.4);
        float xOffset = zoomTime + rand(vec2(pos.y,pos.y+1.0))*10.0;
        float xDist = abs(mod(pos.x+xOffset,xRange)-rayRange);

        float value = max(0.0,rayRange-xDist)/rayRange;
        return value;
    }
    
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 pc)
    {
        vec2 tcc = vec2(tc.x-0.5,tc.y-0.5);
        float ang = atan(tcc.y/tcc.x);
        float len = length(tcc);

        vec2 sphereCoords = vec2(
            -pow(len*20.0,0.2),
            ang - mod(ang, 0.015)
        );

        float v = getLineColor(sphereCoords);
        
        return color * vec4(pow(v,1.5),pow(v,1.3),v,1.0) * min(1.0,0.4+len);
    }
]]