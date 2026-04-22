-- Procedural Consumable Engine v3.0 (Polished Juice & Micro-interactions)

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES & SETTINGS
--------------------------------------------------------------------------------
local PALETTES = {
    metal = { base={0.45, 0.45, 0.5}, dark={0.15, 0.15, 0.18}, highlight={0.8, 0.85, 0.9} },
    gold  = { base={0.9, 0.7, 0.1}, dark={0.5, 0.3, 0.05}, highlight={1.0, 0.9, 0.6} },
    glass = { base={0.8, 0.9, 0.95, 0.3}, dark={0.2, 0.4, 0.5, 0.5}, highlight={1.0, 1.0, 1.0, 0.9} },
    paper = { base={0.8, 0.75, 0.6}, dark={0.5, 0.4, 0.3}, highlight={0.95, 0.9, 0.8} },
    stone = { base={0.3, 0.3, 0.35}, dark={0.1, 0.1, 0.15}, highlight={0.5, 0.5, 0.55} },
    flesh = { base={0.8, 0.3, 0.3}, dark={0.4, 0.1, 0.1}, highlight={0.9, 0.5, 0.5} },
    mats = {
        military = { base={0.35, 0.45, 0.3}, dark={0.15, 0.25, 0.15}, highlight={0.5, 0.6, 0.45}, name="Mil-Spec" },
        med      = { base={0.9, 0.9, 0.95}, dark={0.4, 0.4, 0.5}, highlight={1.0, 1.0, 1.0}, name="Clinical" },
        scav     = { base={0.6, 0.4, 0.2}, dark={0.3, 0.2, 0.1}, highlight={0.7, 0.5, 0.3}, name="Scavenged" }
    },
    liquids = {
        health = { base={0.9, 0.1, 0.1}, highlight={1.0, 0.4, 0.4}, text="+HP" },
        shield = { base={0.1, 0.6, 1.0}, highlight={0.4, 0.8, 1.0}, text="+SHIELD" },
        mana   = { base={0.6, 0.1, 0.9}, highlight={0.8, 0.4, 1.0}, text="+MANA" },
        stamina= { base={0.9, 0.8, 0.1}, highlight={1.0, 1.0, 0.5}, text="+STAM" },
        toxin  = { base={0.3, 0.9, 0.2}, highlight={0.6, 1.0, 0.4}, text="-HP (TOXIC)" }
    },
    ui = { bg={0.04, 0.05, 0.07}, panel={0.08, 0.1, 0.12, 0.95}, text={0.9, 0.9, 0.9} }
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2}, mult = 0.5, glow = 0.0 },
    Common    = { color = {0.6, 0.6, 0.6}, mult = 1.0, glow = 0.0 },
    Uncommon  = { color = {0.3, 0.8, 0.4}, mult = 1.5, glow = 0.1 },
    Rare      = { color = {0.2, 0.6, 1.0}, mult = 2.5, glow = 0.3 },
    Epic      = { color = {0.8, 0.3, 1.0}, mult = 4.0, glow = 0.6 },
    Legendary = { color = {1.0, 0.6, 0.1}, mult = 7.0, glow = 1.0 }
}

local ITEM_ARCHETYPES = {
    MRE        = { w=40, h=48, type="Food", particle="crumb" },
    Can        = { w=32, h=40, type="Food", particle="metal" },
    AlienMeat  = { w=48, h=48, type="Food", particle="splat" },
    EnergyCan  = { w=20, h=40, type="Drink", particle="splash" },
    Canteen    = { w=32, h=36, type="Drink", particle="splash" },
    Medkit     = { w=48, h=32, type="Heal", particle="spark" },
    Injector   = { w=24, h=64, type="Heal", particle="splash" },
    RoundVial  = { w=36, h=48, type="Potion", particle="glass" },
    TriFlask   = { w=32, h=36, type="Potion", particle="glass" },
    Scroll     = { w=48, h=56, type="Spell", particle="magic" },
    RuneStone  = { w=32, h=32, type="Spell", particle="magic" }
}

-- Easing Function
local function lerp(a, b, t) return a + (b - a) * t end

--------------------------------------------------------------------------------
-- 2. THE CANVAS GENERATOR (Strict Pixel-Art)
--------------------------------------------------------------------------------
local function makeCanvas(w, h, drawFunction)
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(c)
    love.graphics.clear(0, 0, 0, 0)
    drawFunction()
    love.graphics.setCanvas()
    return c
end

local function drawComponent(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x-1, y-1, w+2, h+2)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1) -- Top highlight
        love.graphics.rectangle("fill", x, y+1, 1, h-1) -- Left edge highlight
    end
end

local function generateItem(archName, rarityName, liquidKey)
    local arch = ITEM_ARCHETYPES[archName]
    local w, h = arch.w, arch.h
    local rData = RARITIES[rarityName]
    
    local cMetal = PALETTES.metal
    local cLiquid = PALETTES.liquids[liquidKey]
    
    local cMat = PALETTES.mats.scav
    if arch.type == "Heal" then cMat = PALETTES.mats.med end
    if archName == "MRE" or archName == "Canteen" then cMat = PALETTES.mats.military end

    local finalSkinName = cMat.name
    if arch.type == "Potion" then finalSkinName = "Alchemical" end
    if arch.type == "Spell" then finalSkinName = "Arcane" end
    if archName == "AlienMeat" then finalSkinName = "Organic" end

    local img = makeCanvas(w, h, function()
        local cx, cy = math.floor(w / 2), math.floor(h / 2)
        
        if archName == "MRE" then
            love.graphics.setColor(cMat.dark)
            love.graphics.polygon("fill", cx-16, cy-20, cx+16, cy-20, cx+18, cy-16, cx+18, cy+16, cx+16, cy+20, cx-16, cy+20, cx-18, cy+16, cx-18, cy-16)
            love.graphics.setColor(cMat.base)
            love.graphics.polygon("fill", cx-14, cy-18, cx+14, cy-18, cx+16, cy-14, cx+16, cy+14, cx+14, cy+18, cx-14, cy+18, cx-16, cy+14, cx-16, cy-14)
            love.graphics.setColor(cMetal.dark)
            love.graphics.rectangle("fill", cx-12, cy-17, 24, 2)
            love.graphics.rectangle("fill", cx-12, cy+15, 24, 2)
            drawComponent(cx-10, cy-8, 20, 16, PALETTES.paper.base, PALETTES.paper.dark, PALETTES.paper.highlight)
            love.graphics.setColor(rData.color)
            love.graphics.rectangle("fill", cx-10, cy+2, 20, 4)

        elseif archName == "Can" then
            drawComponent(cx - 12, cy - 16, 24, 4, cMetal.highlight, cMetal.dark, nil)
            drawComponent(cx - 12, cy + 12, 24, 4, cMetal.highlight, cMetal.dark, nil)
            drawComponent(cx - 11, cy - 12, 22, 24, cMetal.base, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(cMat.base)
            love.graphics.rectangle("fill", cx - 11, cy - 8, 22, 16)
            love.graphics.setColor(cMat.dark)
            love.graphics.rectangle("fill", cx - 11, cy - 4, 22, 2)
            love.graphics.rectangle("fill", cx - 11, cy + 2, 22, 2)
            love.graphics.setColor(rData.color)
            love.graphics.rectangle("fill", cx - 11, cy - 8, 22, 2)
            -- Specular wrap
            love.graphics.setColor(1,1,1, 0.3)
            love.graphics.rectangle("fill", cx - 7, cy - 12, 3, 24)

        elseif archName == "AlienMeat" then
            drawComponent(cx - 4, cy - 20, 8, 16, PALETTES.paper.highlight, PALETTES.paper.base, nil)
            love.graphics.setColor(PALETTES.paper.highlight)
            love.graphics.circle("fill", cx - 4, cy - 20, 4); love.graphics.circle("fill", cx + 4, cy - 20, 4)
            love.graphics.setColor(PALETTES.flesh.dark)
            love.graphics.polygon("fill", cx-20, cy, cx-12, cy-12, cx+10, cy-14, cx+22, cy+2, cx+16, cy+18, cx-12, cy+20)
            love.graphics.setColor(PALETTES.flesh.base)
            love.graphics.polygon("fill", cx-18, cy+2, cx-10, cy-10, cx+8, cy-12, cx+20, cy+4, cx+14, cy+16, cx-10, cy+18)
            love.graphics.setColor(PALETTES.flesh.highlight)
            love.graphics.setLineWidth(2)
            love.graphics.line(cx-12, cy+2, cx-2, cy-6); love.graphics.line(cx-2, cy+10, cx+12, cy+6)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(cLiquid.base)
            love.graphics.circle("fill", cx-8, cy+8, 3); love.graphics.circle("fill", cx+10, cy-2, 4)

        elseif archName == "EnergyCan" then
            drawComponent(cx - 8, cy - 18, 16, 36, cMetal.dark, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(cLiquid.highlight)
            love.graphics.rectangle("fill", cx - 8, cy - 4, 16, 16)
            love.graphics.setColor(rData.color)
            love.graphics.rectangle("fill", cx - 4, cy, 8, 8)
            -- Bright edge
            love.graphics.setColor(1,1,1,0.4)
            love.graphics.rectangle("fill", cx - 5, cy - 18, 2, 36)

        elseif archName == "Canteen" then
            love.graphics.setColor(cMat.dark)
            love.graphics.ellipse("fill", cx, cy + 2, 15, 17)
            love.graphics.setColor(cMat.base)
            love.graphics.ellipse("fill", cx, cy, 14, 16)
            drawComponent(cx - 4, cy - 18, 8, 6, cMetal.base, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(rData.color)
            love.graphics.circle("fill", cx, cy, 6)

        elseif archName == "Medkit" then
            drawComponent(cx - 22, cy - 12, 44, 28, cMat.base, cMat.dark, cMat.highlight)
            drawComponent(cx - 6, cy - 16, 12, 4, cMetal.base, cMetal.dark, cMetal.highlight) 
            drawComponent(cx - 22, cy, 44, 4, cMetal.dark, cMetal.dark, nil) -- Seam
            love.graphics.setColor(cLiquid.highlight) -- Glowing cross
            love.graphics.rectangle("fill", cx - 4, cy - 6, 8, 12)
            love.graphics.rectangle("fill", cx - 8, cy - 4, 16, 8)
            love.graphics.setColor(1,1,1, 0.8)
            love.graphics.rectangle("fill", cx - 2, cy - 4, 4, 8)
            love.graphics.rectangle("fill", cx - 4, cy - 2, 8, 4)

        elseif archName == "Injector" then
            drawComponent(cx - 8, cy - 28, 16, 4, cMetal.highlight, cMetal.dark, nil)
            drawComponent(cx - 2, cy - 24, 4, 10, cMetal.base, cMetal.dark, nil)
            drawComponent(cx - 8, cy - 14, 16, 26, PALETTES.glass.base, cMetal.dark, nil)
            love.graphics.setColor(cLiquid.highlight)
            love.graphics.rectangle("fill", cx - 7, cy - 8, 14, 19)
            love.graphics.setColor(cMetal.dark)
            for i=-4, 8, 4 do love.graphics.line(cx - 7, cy + i, cx - 2, cy + i) end
            drawComponent(cx - 10, cy + 12, 20, 6, cMat.base, cMetal.dark, cMat.highlight)
            drawComponent(cx - 1, cy + 18, 2, 12, cMetal.base, cMetal.dark, cMetal.highlight) 
            love.graphics.setColor(1,1,1, 0.6) -- Glass specular
            love.graphics.rectangle("fill", cx - 4, cy - 12, 3, 22)

        elseif archName == "RoundVial" then
            drawComponent(cx - 4, cy - 20, 8, 6, cMat.dark, cMetal.dark, nil)
            love.graphics.setColor(cMetal.dark)
            love.graphics.polygon("fill", cx-6, cy-14, cx+6, cy-14, cx+14, cy+8, cx-14, cy+8)
            love.graphics.circle("fill", cx, cy+8, 14)
            love.graphics.setColor(PALETTES.glass.base)
            love.graphics.polygon("fill", cx-4, cy-12, cx+4, cy-12, cx+12, cy+8, cx-12, cy+8)
            love.graphics.circle("fill", cx, cy+8, 12)
            love.graphics.setColor(cLiquid.highlight)
            love.graphics.polygon("fill", cx-8, cy+2, cx+8, cy+2, cx+12, cy+8, cx-12, cy+8)
            love.graphics.arc("fill", cx, cy+8, 12, 0, math.pi)
            love.graphics.setColor(PALETTES.glass.highlight)
            love.graphics.line(cx-6, cy-8, cx-10, cy+6) -- Strong specular reflection
            love.graphics.line(cx-9, cy+8, cx-6, cy+14)

        elseif archName == "TriFlask" then
            drawComponent(cx - 4, cy - 16, 8, 6, cMetal.base, cMetal.dark, nil) 
            love.graphics.setColor(cMetal.dark)
            love.graphics.polygon("fill", cx, cy - 10, cx + 15, cy + 16, cx - 15, cy + 16)
            love.graphics.setColor(PALETTES.glass.base)
            love.graphics.polygon("fill", cx, cy - 8, cx + 13, cy + 15, cx - 13, cy + 15)
            love.graphics.setColor(cLiquid.highlight)
            love.graphics.polygon("fill", cx, cy + 2, cx + 10, cy + 14, cx - 10, cy + 14)
            love.graphics.setColor(PALETTES.glass.highlight)
            love.graphics.line(cx-2, cy-4, cx-10, cy+12)

        elseif archName == "Scroll" then
            drawComponent(cx - 18, cy - 20, 36, 40, PALETTES.paper.base, PALETTES.paper.dark, PALETTES.paper.highlight)
            love.graphics.setColor(PALETTES.paper.highlight)
            love.graphics.rectangle("fill", cx - 16, cy - 18, 32, 36)
            love.graphics.setColor(PALETTES.paper.dark)
            love.graphics.rectangle("fill", cx - 12, cy - 12, 24, 2); love.graphics.rectangle("fill", cx - 12, cy - 6, 18, 2)
            love.graphics.rectangle("fill", cx - 12, cy, 20, 2); love.graphics.rectangle("fill", cx - 12, cy + 6, 14, 2)
            drawComponent(cx - 22, cy - 24, 44, 6, cMat.dark, cMetal.dark, cMetal.highlight)
            drawComponent(cx - 22, cy + 18, 44, 6, cMat.dark, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(rData.color)
            love.graphics.rectangle("fill", cx - 18, cy - 2, 36, 6)
            love.graphics.setColor(0.8, 0.1, 0.1)
            love.graphics.circle("fill", cx, cy + 1, 6)
            love.graphics.setColor(cLiquid.highlight)
            love.graphics.circle("fill", cx, cy + 1, 2)
            love.graphics.circle("line", cx, cy + 1, 4)

        elseif archName == "RuneStone" then
            love.graphics.setColor(PALETTES.stone.dark)
            love.graphics.polygon("fill", cx, cy - 16, cx + 14, cy, cx, cy + 16, cx - 14, cy)
            love.graphics.setColor(PALETTES.stone.base)
            love.graphics.polygon("fill", cx, cy - 14, cx + 12, cy, cx, cy + 14, cx - 12, cy)
            love.graphics.setColor(cLiquid.highlight) 
            love.graphics.circle("fill", cx, cy, 4)
            love.graphics.line(cx, cy - 8, cx, cy + 8); love.graphics.line(cx - 8, cy, cx + 8, cy)
        end
    end)
    
    return { img = img, w = w, h = h, skinName = finalSkinName }
end

--------------------------------------------------------------------------------
-- 3. INTERACTION, JUICE & PARTICLE SYSTEM
--------------------------------------------------------------------------------
local Particles, FloatingTexts = {}, {}
local MouseX, MouseY = 400, 300
local ActiveItem = {}

-- Juice State
local Anim = {
    shake = 0, scaleX = 0, scaleY = 0, targetScale = 1.0, 
    popT = 0, isConsumed = false, screenFlash = 0
}

local function triggerConsume(itemData)
    if Anim.isConsumed then return end
    Anim.isConsumed = true
    Anim.shake = 20
    Anim.screenFlash = 1.0
    Anim.scaleX = 1.8 -- Aggressive stretch
    Anim.scaleY = 0.4 -- Aggressive squash
    Anim.targetScale = 0.0 -- Shrink to nothing

    local liq = PALETTES.liquids[itemData.liquid]
    local arch = ITEM_ARCHETYPES[itemData.arch]
    local cX, cY = 400, 300

    -- Explosive Combat Text
    local val = math.floor(love.math.random(25, 100) * itemData.rData.mult)
    table.insert(FloatingTexts, {
        x = cX, y = cY, targetY = cY - 80, 
        text = "+" .. val .. " " .. string.gsub(liq.text, "+", ""),
        color = liq.highlight, life = 2.5, scale = 0.1
    })

    -- Premium Particle Burst
    local numParticles = love.math.random(30, 50)
    for i=1, numParticles do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(80, 450)
        
        local pColor = liq.base
        if arch.particle == "crumb" then pColor = PALETTES.paper.dark
        elseif arch.particle == "metal" then pColor = PALETTES.metal.highlight
        elseif arch.particle == "glass" then pColor = PALETTES.glass.highlight
        elseif arch.particle == "magic" then pColor = liq.highlight end

        table.insert(Particles, {
            x = cX, y = cY, vx = math.cos(angle)*speed, vy = math.sin(angle)*speed,
            life = love.math.random(0.4, 1.2), maxLife = 1.2, size = love.math.random(3, 8),
            color = pColor, style = arch.particle, rot = love.math.random()*math.pi, rotV = love.math.random(-5, 5)
        })
    end
end

local function updateInteractions(dt)
    -- Physics Spring for Squash & Stretch
    Anim.shake = math.max(0, Anim.shake - dt * 60)
    Anim.screenFlash = math.max(0, Anim.screenFlash - dt * 3)
    
    Anim.scaleX = lerp(Anim.scaleX, Anim.targetScale, dt * 15)
    Anim.scaleY = lerp(Anim.scaleY, Anim.targetScale, dt * 15)

    -- Combat Text Easing
    for i = #FloatingTexts, 1, -1 do
        local ft = FloatingTexts[i]
        ft.life = ft.life - dt
        ft.y = lerp(ft.y, ft.targetY, dt * 8) -- Smooth float up
        ft.scale = lerp(ft.scale, 1.0, dt * 12) -- Pop out
        if ft.life <= 0 then table.remove(FloatingTexts, i) end
    end

    -- Advanced Particles
    local floorY = 460
    for i = #Particles, 1, -1 do
        local p = Particles[i]
        p.life = p.life - dt
        p.rot = p.rot + p.rotV * dt
        
        if p.style == "magic" then
            p.vy = p.vy - 100 * dt -- Float up
            p.vx = p.vx + math.sin(love.timer.getTime()*10 + p.life) * 20 -- Swirl
        else
            p.vy = p.vy + 1200 * dt -- Heavy Gravity
        end
        
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        
        -- Floor Collision
        if p.y > floorY and p.style ~= "magic" then 
            if p.style == "splash" or p.style == "splat" then
                -- Flatten out like a liquid puddle
                p.y = floorY
                p.vy = 0; p.vx = 0
                p.sizeX = p.size * 2
                p.sizeY = p.size * 0.3
            else
                p.vy = -p.vy * 0.4; p.y = floorY; p.vx = p.vx * 0.5 
            end
        end
        
        if p.life <= 0 then table.remove(Particles, i) end
    end
end

--------------------------------------------------------------------------------
-- 4. GAME STATE & MAIN LOOP
--------------------------------------------------------------------------------
local renderScale = 4

local function rollNewItem()
    Particles, FloatingTexts = {}, {}
    Anim = { shake = 0, scaleX = 0, scaleY = 3.0, targetScale = 1.0, isConsumed = false, screenFlash = 0 }

    local archs = { "MRE", "Can", "AlienMeat", "EnergyCan", "Canteen", "Medkit", "Injector", "RoundVial", "TriFlask", "Scroll", "RuneStone" }
    local liquids = {"health", "health", "shield", "mana", "stamina", "toxin"}
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
    
    local arch = archs[love.math.random(1, #archs)]
    local typeDef = ITEM_ARCHETYPES[arch].type
    
    local liquid = liquids[love.math.random(1, #liquids)]
    if typeDef == "Heal" then liquid = "health" end
    if typeDef == "Food" and love.math.random()>0.8 then liquid = "toxin" end
    if typeDef == "Spell" then liquid = (love.math.random()>0.5 and "mana" or "shield") end

    local rarity = rarities[love.math.random(1, #rarities)]
    local data = generateItem(arch, rarity, liquid)

    ActiveItem = {
        image = data.img, w = data.w, h = data.h,
        arch = arch, liquid = liquid, rarity = rarity, rData = RARITIES[rarity], skin = data.skinName,
        name = string.format("%s %s", rarity, arch),
        type = typeDef
    }
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setVisible(false)
    rollNewItem()
end

function love.keypressed(key)
    if key == "space" then rollNewItem() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.mousepressed(x, y, button)
    if button == 1 then triggerConsume(ActiveItem) end
end

function love.update(dt)
    updateInteractions(dt)
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.push()
    if Anim.shake > 0 then
        love.graphics.translate(love.math.random(-Anim.shake, Anim.shake), love.math.random(-Anim.shake, Anim.shake))
    end

    -- Background
    love.graphics.clear(PALETTES.ui.bg)
    love.graphics.setColor(0.08, 0.1, 0.12, 0.5)
    local gridScroll = (time * 15) % 40
    for x = 0, 800, 40 do love.graphics.line(x, 0, x, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y + gridScroll, 800, y + gridScroll) end
    
    -- Pedestal
    local pedX, pedY = 400, 420
    love.graphics.setColor(0.06, 0.08, 0.1)
    love.graphics.polygon("fill", pedX-80, pedY+20, pedX+80, pedY+20, pedX+120, pedY, pedX-120, pedY)
    love.graphics.setColor(0.04, 0.05, 0.07)
    love.graphics.polygon("fill", pedX-80, pedY+20, pedX+80, pedY+20, pedX+80, pedY+35, pedX-80, pedY+35)
    
    -- Floor Base
    love.graphics.setColor(0.06, 0.07, 0.09)
    love.graphics.rectangle("fill", 0, 455, 800, 200)

    -- Dynamic Math
    local idleY = math.sin(time * 3) * 8
    local mNormX = (MouseX - 400) / 400
    local tilt = mNormX * 0.2 -- Parallax tilt towards mouse
    local finalX, finalY = 400 + (mNormX * 10), 320 + idleY

    -- Dynamic Floor Reflection/Shadow
    if not Anim.isConsumed then
        local liqColor = PALETTES.liquids[ActiveItem.liquid].highlight
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(liqColor[1], liqColor[2], liqColor[3], 0.2)
        love.graphics.ellipse("fill", 400, 415, ActiveItem.w * 2, 16)
        love.graphics.setBlendMode("alpha")
        
        love.graphics.setColor(0, 0, 0, 0.5)
        love.graphics.ellipse("fill", 400, 415, ActiveItem.w * 1.2, 8)
    end

    -- Draw Consumable (with Rarity Aura)
    if ActiveItem.rData.glow > 0 and not Anim.isConsumed then
        love.graphics.setBlendMode("add", "alphamultiply")
        local rc = ActiveItem.rData.color
        local pulse = (math.sin(time * 5) + 1) * 0.5
        love.graphics.setColor(rc[1], rc[2], rc[3], ActiveItem.rData.glow * 0.5 * pulse)
        love.graphics.circle("fill", finalX, finalY, ActiveItem.w * 3)
        love.graphics.setBlendMode("alpha")
    end

    love.graphics.setColor(1, 1, 1, 1)
    local sX = renderScale * Anim.scaleX
    local sY = renderScale * Anim.scaleY
    love.graphics.draw(ActiveItem.image, finalX, finalY, tilt, sX, sY, ActiveItem.w/2, ActiveItem.h/2)

    -- Particles
    for _, p in ipairs(Particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rot)
        
        if p.style == "splash" or p.style == "splat" then
            local sx = p.sizeX or p.size
            local sy = p.sizeY or p.size
            love.graphics.ellipse("fill", 0, 0, sx, sy)
        elseif p.style == "magic" then
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.circle("fill", 0, 0, p.size)
            love.graphics.setBlendMode("alpha")
        else
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size) 
        end
        love.graphics.pop()
    end
    love.graphics.pop()

    -- Screen Flash (Rendered outside shake)
    if Anim.screenFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local liqColor = PALETTES.liquids[ActiveItem.liquid].highlight
        love.graphics.setColor(liqColor[1], liqColor[2], liqColor[3], Anim.screenFlash * 0.5)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setBlendMode("alpha")
    end

    -- Floating Text (UI Layer)
    for _, ft in ipairs(FloatingTexts) do
        local alpha = math.min(1.0, ft.life * 2)
        love.graphics.push()
        love.graphics.translate(ft.x, ft.y)
        love.graphics.scale(ft.scale, ft.scale)
        -- Shadow
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.print(ft.text, -20 + 2, 2, 0, 1.5, 1.5)
        -- Text
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
        love.graphics.print(ft.text, -20, 0, 0, 1.5, 1.5)
        love.graphics.pop()
    end

    -- UI Frame
    love.graphics.setColor(PALETTES.ui.panel)
    love.graphics.rectangle("fill", 20, 20, 320, 210, 12, 12)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.rectangle("line", 20, 20, 320, 210, 12, 12)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("[SPACE] Rummage for Loot", 40, 40)
    love.graphics.print("[L-CLICK] Use/Consume Item", 40, 60)
    
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.print(string.upper(ActiveItem.name), 40, 90, 0, 1.2, 1.2)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("TIER: ", 40, 115)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.print(string.upper(ActiveItem.rarity), 80, 115)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("CLASS: ", 180, 115)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.upper(ActiveItem.type), 235, 115)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("PROPERTIES:", 40, 145)
    love.graphics.setColor(PALETTES.liquids[ActiveItem.liquid].highlight)
    love.graphics.print(">> " .. PALETTES.liquids[ActiveItem.liquid].text, 50, 170)

    -- Custom Cursor
    local cx, cy = MouseX, MouseY
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("line", cx, cy, 8)
    love.graphics.circle("fill", cx, cy, 2)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.circle("line", cx, cy, 4)
end