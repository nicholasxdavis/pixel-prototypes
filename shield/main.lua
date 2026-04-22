-- Procedural Shield Generation Engine v1.0 (Borderlands Inspired Tech Modules)

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES, RARITIES & SETTINGS
--------------------------------------------------------------------------------
local PALETTES = {
    metal = { base={0.45, 0.45, 0.5}, dark={0.15, 0.15, 0.18}, highlight={0.7, 0.75, 0.8} },
    gold  = { base={0.9, 0.7, 0.1}, dark={0.5, 0.3, 0.05}, highlight={1.0, 0.9, 0.5} },
    brass = { base={0.9, 0.7, 0.2}, dark={0.6, 0.4, 0.1}, highlight={1.0, 0.9, 0.5} },
    mats = {
        hyper = { base={0.8, 0.2, 0.2}, dark={0.4, 0.1, 0.1}, highlight={0.9, 0.4, 0.4}, name="Aggressive" },
        comp  = { base={0.18, 0.18, 0.2}, dark={0.05, 0.05, 0.08}, highlight={0.3, 0.3, 0.35}, name="Polymer" },
        tan   = { base={0.65, 0.55, 0.4}, dark={0.4, 0.35, 0.25}, highlight={0.8, 0.7, 0.5}, name="Military Tan" },
        pang  = { base={0.35, 0.45, 0.3}, dark={0.15, 0.25, 0.15}, highlight={0.5, 0.6, 0.45}, name="Hardened" },
        scrap = { base={0.6, 0.3, 0.15}, dark={0.3, 0.1, 0.05}, highlight={0.8, 0.4, 0.2}, name="Bandit" },
        cyber = { base={0.9, 0.9, 0.95}, dark={0.5, 0.5, 0.6}, highlight={1.0, 1.0, 1.0}, name="Ceramic" }
    },
    ui    = { bg={0.05, 0.06, 0.08}, panel={0.1, 0.12, 0.15, 0.9}, text={0.9, 0.9, 0.9} },
    elements = {
        plasma = { base={0.2, 0.9, 1.0}, highlight={0.8, 1.0, 1.0}, style="shock", blend="add" },
        fire   = { base={1.0, 0.4, 0.1}, highlight={1.0, 0.9, 0.2}, style="nova", blend="add" },
        shock  = { base={0.8, 0.9, 0.1}, highlight={1.0, 1.0, 0.8}, style="shock", blend="add" },
        poison = { base={0.4, 0.9, 0.2}, highlight={0.7, 1.0, 0.4}, style="drip", blend="alpha" },
        ice    = { base={0.6, 1.0, 1.0}, highlight={1.0, 1.0, 1.0}, style="spike", blend="add" },
        void   = { base={0.5, 0.1, 0.8}, highlight={0.8, 0.4, 1.0}, style="absorb", blend="alpha" },
        none   = { base={1.0, 0.9, 0.6}, highlight={1.0, 1.0, 1.0}, style="standard", blend="add" }
    }
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2}, mods = 0, p_mult = 0.2 },
    Common    = { color = {0.6, 0.6, 0.6}, mods = 0, p_mult = 0.5 },
    Uncommon  = { color = {0.3, 0.8, 0.4}, mods = 1, p_mult = 0.8 },
    Rare      = { color = {0.2, 0.6, 1.0}, mods = 2, p_mult = 1.2 },
    Epic      = { color = {0.8, 0.3, 1.0}, mods = 3, p_mult = 2.0 },
    Legendary = { color = {1.0, 0.5, 0.1}, mods = 4, p_mult = 3.5 },
    Mythic    = { color = {0.1, 1.0, 0.8}, mods = 4, p_mult = 4.5 },
    P2W       = { color = {1.0, 0.1, 0.6}, mods = 5, p_mult = 6.0 }
}

-- Width, Height, Core dimensions, Wing extensions, Battery placements
local SHIELD_ARCHETYPES = {
    Standard  = { w=64, h=64, c_w=20, c_h=30, wing_w=16, wing_h=24, cap_y=8, style="standard" },
    Bulwark   = { w=80, h=64, c_w=30, c_h=24, wing_w=20, wing_h=32, cap_y=12, style="turtle" },
    Burst     = { w=64, h=80, c_w=16, c_h=36, wing_w=12, wing_h=16, cap_y=16, style="nova" },
    Thorn     = { w=72, h=72, c_w=22, c_h=22, wing_w=18, wing_h=20, cap_y=6, style="spike" },
    Amp       = { w=80, h=48, c_w=24, c_h=16, wing_w=22, wing_h=12, cap_y=0, style="amp" },
    Siphon    = { w=64, h=72, c_w=18, c_h=28, wing_w=14, wing_h=32, cap_y=10, style="absorb" },
    Phalanx   = { w=80, h=80, c_w=28, c_h=40, wing_w=16, wing_h=44, cap_y=18, style="heavy" },
}

--------------------------------------------------------------------------------
-- 2. THE CANVAS GENERATOR (Strict Pixel-Art Engine)
--------------------------------------------------------------------------------
local function makeCanvas(w, h, drawFunction)
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(c)
    love.graphics.clear(0, 0, 0, 0)
    local anchors = drawFunction()
    love.graphics.setCanvas()
    return {img = c, w = w, h = h, anchors = anchors}
end

local function drawComponent(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x-1, y-1, w+2, h+2)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1)
    end
end

-- Draw symmetric components across a center line
local function drawSymmetric(cx, cy, offsetX, offsetY, w, h, cBase, cDark, cHigh)
    -- Left
    drawComponent(cx - offsetX - w, cy + offsetY, w, h, cBase, cDark, cHigh)
    -- Right
    drawComponent(cx + offsetX, cy + offsetY, w, h, cBase, cDark, cHigh)
end

local function generateShield(archName, rarityName, element, mods)
    local arch = SHIELD_ARCHETYPES[archName]
    local w, h = arch.w, arch.h
    local rData = RARITIES[rarityName]
    
    local cMetal = PALETTES.metal
    local skinPool = {PALETTES.mats.hyper, PALETTES.mats.comp, PALETTES.mats.tan, PALETTES.mats.pang}
    local cMat = skinPool[love.math.random(1, #skinPool)]
    
    if rarityName == "Scrap" then cMat = PALETTES.mats.scrap; cMetal = PALETTES.mats.scrap end
    if rarityName == "Mythic" then cMat = PALETTES.mats.cyber; cMetal = PALETTES.mats.cyber end
    if rarityName == "P2W" then cMat = PALETTES.mats.comp; cMetal = PALETTES.gold end
    
    local finalSkinName = cMat.name
    local eleColor = PALETTES.elements[element].base
    
    local canvasData = makeCanvas(w, h, function()
        local cx, cy = math.floor(w / 2), math.floor(h / 2)
        
        -- Background Plate (Dark Metal)
        drawComponent(cx - math.floor(arch.c_w/2) - 2, cy - math.floor(arch.c_h/2) - 2, arch.c_w + 4, arch.c_h + 4, cMetal.base, cMetal.dark, nil)

        -- Wings/Side Plates
        local wingY = -math.floor(arch.wing_h/2)
        drawSymmetric(cx, cy, math.floor(arch.c_w/2) - 2, wingY, arch.wing_w, arch.wing_h, cMat.base, cMetal.dark, cMat.highlight)
        
        -- Secondary chassis bulk (if Heavy)
        if mods.heavy_chassis then
            drawSymmetric(cx, cy, math.floor(arch.c_w/2) + arch.wing_w - 4, wingY + 4, 8, arch.wing_h - 8, cMetal.base, cMetal.dark, cMetal.highlight)
        end

        -- Spikes (if Spiked Plating)
        if mods.spiked_plating then
            love.graphics.setColor(cMetal.dark)
            local sx1 = cx - math.floor(arch.c_w/2) - arch.wing_w - 4
            local sx2 = cx + math.floor(arch.c_w/2) + arch.wing_w
            -- Left spike
            love.graphics.polygon("fill", sx1+2, cy-4, sx1-4, cy, sx1+2, cy+4)
            -- Right spike
            love.graphics.polygon("fill", sx2-2, cy-4, sx2+4, cy, sx2-2, cy+4)
            love.graphics.setColor(cMetal.highlight)
            love.graphics.line(sx1+2, cy-4, sx1-4, cy)
            love.graphics.line(sx2-2, cy-4, sx2+4, cy)
        end

        -- Main Core Block
        drawComponent(cx - math.floor(arch.c_w/2), cy - math.floor(arch.c_h/2), arch.c_w, arch.c_h, cMetal.base, cMetal.dark, cMetal.highlight)

        -- Energy Cells / Batteries
        local capY = -math.floor(arch.cap_y)
        local capH = arch.cap_y * 2
        if capH == 0 then capH = 8; capY = -4 end
        
        -- Draw battery housings
        drawSymmetric(cx, cy, math.floor(arch.c_w/2) - 6, capY - 2, 10, capH + 4, cMetal.dark, cMetal.dark, nil)
        
        -- Draw glowing cells
        love.graphics.setColor(eleColor)
        drawSymmetric(cx, cy, math.floor(arch.c_w/2) - 5, capY, 8, capH, eleColor, cMetal.dark, PALETTES.elements[element].highlight)
        
        -- Overclocked Core
        if mods.overclocked_core then
            drawSymmetric(cx, cy, math.floor(arch.c_w/2) - 5, capY - 6, 8, 4, eleColor, cMetal.dark, nil)
            drawSymmetric(cx, cy, math.floor(arch.c_w/2) - 5, capY + capH + 2, 8, 4, eleColor, cMetal.dark, nil)
        end

        -- Central Emitter Ring
        love.graphics.setColor(cMetal.dark)
        love.graphics.circle("fill", cx, cy, 10)
        love.graphics.setColor(cMat.base)
        love.graphics.circle("fill", cx, cy, 8)
        
        if mods.capacitor_array then
            love.graphics.setColor(cMetal.highlight)
            love.graphics.rectangle("fill", cx-2, cy-8, 4, 16)
            love.graphics.rectangle("fill", cx-8, cy-2, 16, 4)
        end

        -- Glowing core center
        love.graphics.setColor(cMetal.dark)
        love.graphics.circle("fill", cx, cy, 5)
        love.graphics.setColor(eleColor)
        love.graphics.circle("fill", cx, cy, 3)
        love.graphics.setColor(PALETTES.elements[element].highlight)
        love.graphics.circle("fill", cx, cy, 1)

        -- Rarity Trim
        love.graphics.setColor(rData.color)
        love.graphics.rectangle("fill", cx - 4, cy - math.floor(arch.c_h/2), 8, 2)
        love.graphics.rectangle("fill", cx - 4, cy + math.floor(arch.c_h/2) - 2, 8, 2)

        return { core = {x=cx, y=cy} }
    end)
    
    canvasData.skinName = finalSkinName
    return canvasData
end

--------------------------------------------------------------------------------
-- 3. COMBAT, EFFECTS & MICROINTERACTIONS
--------------------------------------------------------------------------------
local Particles, ShieldPulse = {}, {}
local MouseX, MouseY = 400, 300

local ModuleState = { shake = 0, hoverY = 0, hoverRot = 0, flashLight = 0, lastTrigger = 0 }

local function triggerShield(moduleData)
    local t = love.timer.getTime()
    if t - ModuleState.lastTrigger < 0.3 then return end
    ModuleState.lastTrigger = t

    ModuleState.shake = 10
    ModuleState.flashLight = 1.0

    local ele = PALETTES.elements[moduleData.element]
    local arch = SHIELD_ARCHETYPES[moduleData.arch]
    
    local cX, cY = 400, 300

    -- Shield Projection Effect (Expands outward)
    table.insert(ShieldPulse, {
        x = cX, y = cY, radius = 20, maxRadius = 180, life = 1.0, 
        color = ele.base, style = arch.style, highlight = ele.highlight
    })

    -- Spark debris
    for i=1, love.math.random(8, 15) do
        local angle = love.math.random() * math.pi * 2
        local speed = love.math.random(100, 400)
        table.insert(Particles, {
            x = cX, y = cY, vx = math.cos(angle)*speed, vy = math.sin(angle)*speed,
            life = love.math.random(0.3, 0.7), maxLife = 0.7, size = love.math.random(2, 5),
            color = ele.highlight, style = "spark"
        })
    end
end

local function updateModulePhysics(dt)
    ModuleState.shake = math.max(0, ModuleState.shake - dt * 40)
    ModuleState.flashLight = math.max(0, ModuleState.flashLight - dt * 2) 

    local floorY = 480
    
    for i = #ShieldPulse, 1, -1 do
        local p = ShieldPulse[i]
        p.life = p.life - dt * 1.5
        -- Ease out radius expansion
        p.radius = p.radius + (p.maxRadius - p.radius) * 10 * dt
        if p.life <= 0 then table.remove(ShieldPulse, i) end
    end

    for i = #Particles, 1, -1 do
        local p = Particles[i]
        p.life = p.life - dt
        
        if p.style == "spark" then
            p.vy = p.vy + 800 * dt -- gravity
            p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
            if p.y > floorY then p.vy = -p.vy * 0.4; p.y = floorY; p.vx = p.vx * 0.7 end
        end
        if p.life <= 0 then table.remove(Particles, i) end
    end
end

-- Helper to draw an energy Hexagon
local function drawHexagon(x, y, radius)
    local pts = {}
    for i=0,5 do
        local angle = i * (math.pi / 3) + (love.timer.getTime() * 0.5)
        table.insert(pts, x + math.cos(angle)*radius)
        table.insert(pts, y + math.sin(angle)*radius)
    end
    love.graphics.polygon("line", pts)
end

--------------------------------------------------------------------------------
-- 4. GAME STATE & MAIN LOOP
--------------------------------------------------------------------------------
local ActiveModule = {}
local renderScale = 4

local function rollNewModule()
    Particles, ShieldPulse = {}, {}
    local archs = { "Standard", "Bulwark", "Burst", "Thorn", "Amp", "Siphon", "Phalanx" }
    local elements = {"none", "none", "plasma", "fire", "shock", "poison", "ice", "void"}
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "P2W"}
    
    local arch = archs[love.math.random(1, #archs)]
    local element = elements[love.math.random(1, #elements)]
    local rarity = rarities[love.math.random(1, #rarities)]
    local rData = RARITIES[rarity]
    
    local availableMods = {"heavy_chassis", "spiked_plating", "overclocked_core", "capacitor_array"}
    local mods = {}
    for i=1, rData.mods do
        if #availableMods > 0 then
            local idx = love.math.random(1, #availableMods)
            mods[availableMods[idx]] = true
            table.remove(availableMods, idx)
        end
    end

    if arch == "Thorn" then mods.spiked_plating = true end
    if arch == "Bulwark" or arch == "Phalanx" then mods.heavy_chassis = true end

    local data = generateShield(arch, rarity, element, mods)

    ActiveModule = {
        image = data.img, anchors = data.anchors, w = data.w, h = data.h,
        arch = arch, element = element, rarity = rarity, rData = rData, skin = data.skinName,
        name = string.format("%s %s %s Module", rarity, (element == "none" and "Kinetic" or element), arch),
        mods = mods
    }
    
    ModuleState.shake = 5
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setVisible(false)
    rollNewModule()
end

function love.keypressed(key)
    if key == "space" then rollNewModule() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.mousepressed(x, y, button)
    if button == 1 then triggerShield(ActiveModule) end
end

function love.update(dt)
    updateModulePhysics(dt)
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.push()
    if ModuleState.shake > 0 then
        love.graphics.translate(love.math.random(-ModuleState.shake, ModuleState.shake), love.math.random(-ModuleState.shake, ModuleState.shake))
    end

    love.graphics.clear(PALETTES.ui.bg)
    love.graphics.setColor(0.1, 0.12, 0.15, 0.5)
    local gridScroll = (time * 10) % 40
    for x = 0, 800, 40 do love.graphics.line(x, 0, x, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y + gridScroll, 800, y + gridScroll) end
    
    if ModuleState.flashLight > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local c = PALETTES.elements[ActiveModule.element].base
        love.graphics.setColor(c[1], c[2], c[3], ModuleState.flashLight * 0.15)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setBlendMode("alpha")
    end

    local pedX, pedY = 400, 410
    love.graphics.setColor(0.08, 0.1, 0.12)
    love.graphics.polygon("fill", pedX-120, pedY+30, pedX+120, pedY+30, pedX+160, pedY, pedX-160, pedY)
    love.graphics.setColor(0.05, 0.07, 0.09)
    love.graphics.polygon("fill", pedX-120, pedY+30, pedX+120, pedY+30, pedX+120, pedY+45, pedX-120, pedY+45)
    
    -- Draw Floor
    love.graphics.setColor(0.08, 0.09, 0.11)
    love.graphics.rectangle("fill", 0, 455, 800, 200)

    -- Hover Math
    local idleY = math.sin(time * 2) * 8
    local idleRot = math.sin(time * 1.5) * 0.05
    local finalX, finalY = 400, 300 + idleY
    local finalRot = idleRot

    -- Shadow
    love.graphics.setColor(0.03, 0.04, 0.05, 0.6)
    love.graphics.ellipse("fill", 400, 440, ActiveModule.w * 1.5 + (idleY*2), 12 + (idleY*0.5))

    -- Drawn Shield Pulses (Rendered behind the module)
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, p in ipairs(ShieldPulse) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life)
        love.graphics.setLineWidth(4)
        
        if p.style == "nova" then
            love.graphics.circle("line", p.x, p.y + idleY, p.radius)
            love.graphics.setColor(p.highlight[1], p.highlight[2], p.highlight[3], p.life * 0.5)
            love.graphics.circle("fill", p.x, p.y + idleY, p.radius * 0.8)
        elseif p.style == "spike" then
            drawHexagon(p.x, p.y + idleY, p.radius)
            love.graphics.setColor(p.highlight[1], p.highlight[2], p.highlight[3], p.life)
            for i=0,5 do
                local ang = i * (math.pi/3) + (time*0.5)
                love.graphics.line(p.x, p.y + idleY, p.x + math.cos(ang)*p.radius*1.2, p.y + idleY + math.sin(ang)*p.radius*1.2)
            end
        else
            -- Standard Holographic Hex Barrier
            drawHexagon(p.x, p.y + idleY, p.radius)
            love.graphics.setLineWidth(1)
            drawHexagon(p.x, p.y + idleY, p.radius * 0.9)
            drawHexagon(p.x, p.y + idleY, p.radius * 0.8)
        end
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(1)

    -- Draw the Shield Module
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(ActiveModule.image, finalX, finalY, finalRot, renderScale, renderScale, ActiveModule.w/2, ActiveModule.h/2)

    -- Particles
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, p in ipairs(Particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.rectangle("fill", p.x, p.y, p.size, p.size) 
    end
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()

    -- UI Frame
    love.graphics.setColor(PALETTES.ui.panel)
    love.graphics.rectangle("fill", 20, 20, 320, 240, 12, 12)
    love.graphics.setColor(ActiveModule.rData.color)
    love.graphics.rectangle("line", 20, 20, 320, 240, 12, 12)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("[SPACE] Roll New Module", 40, 40)
    love.graphics.print("[L-CLICK] Trigger Barrier", 40, 60)
    
    love.graphics.setColor(ActiveModule.rData.color)
    love.graphics.print(string.upper(ActiveModule.name), 40, 90, 0, 1.2, 1.2)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("TIER: ", 40, 115)
    love.graphics.setColor(ActiveModule.rData.color)
    love.graphics.print(string.upper(ActiveModule.rarity), 80, 115)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("MAKE: ", 180, 115)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.upper(ActiveModule.skin), 225, 115)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("INTERNAL SYSTEMS:", 40, 145)
    local y = 170
    local hasMods = false
    for mod, _ in pairs(ActiveModule.mods) do
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print(">> " .. string.upper(mod:gsub("_", " ")), 50, y)
        y = y + 20
        hasMods = true
    end
    if not hasMods then 
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("-- FACTORY STANDARD", 50, y) 
    end

    -- Crosshair / Cursor
    local cx, cy = MouseX, MouseY
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.circle("line", cx, cy, 6)
    love.graphics.circle("fill", cx, cy, 2)
end