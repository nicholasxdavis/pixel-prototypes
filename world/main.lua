-- main.lua
-- Procedural Resource Generation Engine v12.0 (Impact Dust & V12 Ecosystem Integration)

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES, RARITIES & SETTINGS
--------------------------------------------------------------------------------
local PALETTES = {
    outline = {0.1, 0.1, 0.12},
    wood    = { base={0.55, 0.35, 0.2}, dark={0.35, 0.2, 0.1}, highlight={0.7, 0.5, 0.3}, ring={0.8, 0.65, 0.45} },
    stone   = { base={0.45, 0.45, 0.5}, dark={0.25, 0.25, 0.3}, highlight={0.65, 0.65, 0.7} },
    obi     = { base={0.15, 0.05, 0.2}, dark={0.05, 0.02, 0.08}, highlight={0.5, 0.2, 0.7} },
    bedrock = { base={0.2, 0.25, 0.22}, dark={0.08, 0.1, 0.09}, highlight={0.3, 0.4, 0.35} },
    special = { base={0.2, 0.2, 0.2}, crystal={0.1, 0.8, 1.0}, highlight={0.8, 1.0, 1.0} },
    alien   = { base={0.15, 0.2, 0.15}, node={0.8, 0.1, 0.5}, glow={1.0, 0.3, 0.8} },
    ui      = { bg={0.04, 0.05, 0.07}, panel={0.08, 0.1, 0.12, 0.95}, text={0.9, 0.9, 0.9} }
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2}, mult = 1, glow = 0.0 },
    Common    = { color = {0.6, 0.6, 0.6}, mult = 2, glow = 0.0 },
    Uncommon  = { color = {0.3, 0.8, 0.4}, mult = 4, glow = 0.1 },
    Rare      = { color = {0.2, 0.6, 1.0}, mult = 8, glow = 0.3 },
    Epic      = { color = {0.8, 0.3, 1.0}, mult = 15, glow = 0.6 },
    Legendary = { color = {1.0, 0.8, 0.2}, mult = 30, glow = 1.0 },
    Eridian   = { color = {0.9, 0.2, 0.8}, mult = 50, glow = 1.5 } 
}

local ARCHETYPES = {
    Wood       = { w=64, h=64, type="Organic",  particle="splinter", drop="Timber" },
    Stone      = { w=64, h=64, type="Mineral",  particle="rock",     drop="Rubble" },
    Obsidian   = { w=64, h=64, type="Volcanic", particle="glass",    drop="Shard" },
    Bedrock    = { w=64, h=64, type="Dense",    particle="rock",     drop="Core" },
    SpecialOre = { w=64, h=64, type="Precious", particle="crystal",  drop="Gem" },
    AlienOre   = { w=64, h=64, type="Unknown",  particle="plasma",   drop="Biomass" }
}

--------------------------------------------------------------------------------
-- 2. THE CANVAS GENERATOR (Cell-Shaded Style)
--------------------------------------------------------------------------------
local function makeCanvas(w, h, drawFunction)
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(c)
    love.graphics.clear(0, 0, 0, 0)
    drawFunction()
    love.graphics.setCanvas()
    return c
end

local function drawPolygonWithOutline(pts, cBase, cDark, cHigh)
    love.graphics.setColor(PALETTES.outline)
    love.graphics.setLineWidth(4)
    love.graphics.polygon("line", pts)
    love.graphics.setColor(cBase)
    love.graphics.polygon("fill", pts)
    love.graphics.setLineWidth(1)
end

local function generateResource(archName)
    local arch = ARCHETYPES[archName]
    local w, h = arch.w, arch.h
    
    local img = makeCanvas(w, h, function()
        local cx, cy = math.floor(w / 2), math.floor(h / 2)
        
        if archName == "Wood" then
            local p = PALETTES.wood
            local logs = love.math.random(2, 3)
            for i = 1, logs do
                local ox = cx + love.math.random(-8, 8)
                local oy = cy + love.math.random(-8, 8) + (i * 4) - 8
                local lw = love.math.random(14, 18)
                local lh = love.math.random(35, 45)
                
                love.graphics.setColor(PALETTES.outline)
                love.graphics.rectangle("fill", ox - lw - 2, oy - lh/2 - 2, lw*2 + 4, lh + 4, 4)
                love.graphics.setColor(p.dark)
                love.graphics.rectangle("fill", ox - lw, oy - lh/2, lw*2, lh, 3)
                love.graphics.setColor(p.base)
                love.graphics.rectangle("fill", ox - lw + 2, oy - lh/2, lw*2 - 4, lh, 2)
                
                love.graphics.setColor(p.highlight)
                love.graphics.rectangle("fill", ox - lw + 4, oy - lh/2 + 4, 2, lh - 8)
                love.graphics.rectangle("fill", ox + 2, oy - lh/2 + 6, 2, lh - 12)
                
                love.graphics.setColor(PALETTES.outline)
                love.graphics.ellipse("fill", ox, oy - lh/2, lw + 2, 6)
                love.graphics.setColor(p.ring)
                love.graphics.ellipse("fill", ox, oy - lh/2, lw, 4)
                love.graphics.setColor(p.dark)
                love.graphics.ellipse("line", ox, oy - lh/2, lw - 2, 2)
            end

        elseif archName == "Stone" then
            local p = PALETTES.stone
            local pts = {}
            for i=0, 7 do
                local ang = i * (math.pi/4)
                local rad = love.math.random(16, 26)
                table.insert(pts, cx + math.cos(ang)*rad)
                table.insert(pts, cy + math.sin(ang)*rad)
            end
            drawPolygonWithOutline(pts, p.base, p.dark, p.highlight)
            
            love.graphics.setColor(PALETTES.outline)
            love.graphics.setLineWidth(2)
            love.graphics.line(pts[1], pts[2], cx, cy)
            love.graphics.line(pts[5], pts[6], cx, cy)
            love.graphics.line(pts[9], pts[10], cx, cy)
            love.graphics.setColor(p.highlight)
            love.graphics.polygon("fill", cx, cy, pts[11], pts[12], pts[13], pts[14])

        elseif archName == "Obsidian" then
            local p = PALETTES.obi
            for i=1, love.math.random(3, 5) do
                local ox = cx + love.math.random(-12, 12)
                local oy = cy + love.math.random(-5, 10)
                local cw = love.math.random(6, 12)
                local ch = love.math.random(20, 35)
                
                local pts = { ox, oy - ch, ox + cw, oy, ox, oy + ch/3, ox - cw, oy }
                drawPolygonWithOutline(pts, p.base, p.dark, p.highlight)
                
                love.graphics.setColor(p.highlight)
                love.graphics.polygon("fill", ox, oy - ch + 2, ox - cw + 2, oy, ox, oy + ch/3 - 2)
                love.graphics.setColor(1, 1, 1, 0.4)
                love.graphics.line(ox, oy - ch + 4, ox - cw/2, oy)
            end

        elseif archName == "Bedrock" then
            local p = PALETTES.bedrock
            local s = 22
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - s - 2, cy - s - 2, s*2 + 4, s*2 + 4, 4)
            love.graphics.setColor(p.dark)
            love.graphics.rectangle("fill", cx - s, cy - s, s*2, s*2, 2)
            love.graphics.setColor(p.base)
            love.graphics.rectangle("fill", cx - s + 4, cy - s + 4, s*2 - 4, s*2 - 8)
            
            love.graphics.setColor(PALETTES.outline)
            love.graphics.setLineWidth(2)
            love.graphics.line(cx - s, cy, cx + s, cy)
            love.graphics.line(cx, cy - s, cx, cy + s)
            love.graphics.setColor(p.highlight)
            love.graphics.line(cx - s + 2, cy - s + 2, cx + s - 2, cy - s + 2)

        elseif archName == "SpecialOre" then
            local p = PALETTES.special
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx, cy + 4, 22)
            love.graphics.setColor(p.base)
            love.graphics.circle("fill", cx, cy + 4, 20)
            
            for i=1, love.math.random(4, 7) do
                local ang = love.math.random() * math.pi * 2
                local dist = love.math.random(5, 15)
                local rad = love.math.random(6, 12)
                local ox = cx + math.cos(ang) * dist
                local oy = cy + math.sin(ang) * dist
                
                love.graphics.setColor(PALETTES.outline)
                love.graphics.polygon("fill", ox, oy-rad*2, ox+rad, oy, ox, oy+rad, ox-rad, oy)
                love.graphics.setColor(p.crystal)
                love.graphics.polygon("fill", ox, oy-rad*2 + 2, ox+rad - 2, oy, ox, oy+rad - 2, ox-rad + 2, oy)
                love.graphics.setColor(p.highlight)
                love.graphics.polygon("fill", ox, oy-rad*2 + 2, ox-rad + 2, oy, ox, oy+rad - 2)
            end

        elseif archName == "AlienOre" then
            local p = PALETTES.alien
            local pts = {}
            for i=0, 9 do
                local ang = i * (math.pi/5)
                local rad = love.math.random(18, 25)
                table.insert(pts, cx + math.cos(ang)*rad)
                table.insert(pts, cy + math.sin(ang)*rad)
            end
            drawPolygonWithOutline(pts, p.base, p.base, p.base)
            
            for i=1, love.math.random(3, 5) do
                local ox = cx + love.math.random(-12, 12)
                local oy = cy + love.math.random(-12, 12)
                local r = love.math.random(4, 8)
                
                love.graphics.setColor(PALETTES.outline)
                love.graphics.circle("fill", ox, oy, r + 2)
                love.graphics.setColor(p.node)
                love.graphics.circle("fill", ox, oy, r)
                love.graphics.setColor(p.glow)
                love.graphics.circle("fill", ox - r*0.3, oy - r*0.3, r*0.4)
            end
        end
    end)
    
    return { img = img, w = w, h = h }
end

--------------------------------------------------------------------------------
-- 3. INTERACTION, PHYSICS & PARTICLES (V12 Integration)
--------------------------------------------------------------------------------
local Particles, FloatingTexts, Dust = {}, {}, {}
local MouseX, MouseY = 400, 300
local ActiveItem = {}

local MiningState = { shake = 0, scaleX = 1.0, scaleY = 1.0, screenFlash = 0, hitFlash = 0, lastHit = 0 }

local function triggerHarvest(itemData)
    local t = love.timer.getTime()
    if t - MiningState.lastHit < 0.1 then return end
    MiningState.lastHit = t

    -- V12 POLISH: Physical Impact (Squash down, stretch out horizontally)
    MiningState.shake = 15
    MiningState.scaleX = 1.3 
    MiningState.scaleY = 0.7 
    MiningState.hitFlash = 1.0 

    local arch = ARCHETYPES[itemData.arch]
    local cX, cY = 400, 320

    -- Floating Loot Text
    local val = math.floor(love.math.random(1, 5) * itemData.rData.mult)
    table.insert(FloatingTexts, {
        x = cX, y = cY - 20, 
        vx = love.math.random(-40, 40), vy = love.math.random(-300, -150),
        text = "+" .. val .. " " .. arch.drop,
        color = itemData.rData.color, life = 2.0, scale = 0.1
    })

    -- V12 POLISH: Physical Debris with Horizontal Drag
    local pColor = PALETTES.stone.highlight
    if arch.particle == "splinter" then pColor = PALETTES.wood.ring
    elseif arch.particle == "glass" then pColor = PALETTES.obi.highlight
    elseif arch.particle == "crystal" then pColor = PALETTES.special.crystal
    elseif arch.particle == "plasma" then pColor = PALETTES.alien.glow end

    for i=1, love.math.random(6, 12) do
        local angle = (math.pi + love.math.random() * math.pi) 
        local speed = love.math.random(150, 400)
        table.insert(Particles, {
            x = cX, y = cY, vx = math.cos(angle)*speed, vy = math.sin(angle)*speed,
            life = love.math.random(0.3, 0.6), maxLife = 0.6, size = love.math.random(3, 6),
            color = pColor, style = arch.particle, rot = love.math.random()*math.pi, rotV = love.math.random(-15, 15)
        })
    end

    -- V12 POLISH: Volumetric Impact Dust (Reusing Weapon Smoke System)
    if arch.particle ~= "plasma" then
        for i=1, love.math.random(3, 5) do
            table.insert(Dust, {
                x = cX + love.math.random(-20, 20), y = cY + love.math.random(0, 20), 
                vx = love.math.random(-30, 30), vy = love.math.random(-20, 10),
                life = love.math.random(0.5, 0.8), maxLife = 0.8, size = love.math.random(4, 10),
                color = {0.3, 0.3, 0.3}, blend = "alpha",
                wobble = love.math.random() * math.pi * 2, wobbleSpeed = love.math.random(-1, 1)
            })
        end
    end
    
    if itemData.rarity == "Legendary" or itemData.rarity == "Eridian" then
        MiningState.screenFlash = 0.8
    end
end

local function updatePhysics(dt)
    MiningState.shake = math.max(0, MiningState.shake - dt * 50)
    MiningState.screenFlash = math.max(0, MiningState.screenFlash - dt * 4)
    MiningState.hitFlash = math.max(0, MiningState.hitFlash - dt * 12)
    
    -- Spring back to normal scale
    MiningState.scaleX = MiningState.scaleX + (1.0 - MiningState.scaleX) * 15 * dt
    MiningState.scaleY = MiningState.scaleY + (1.0 - MiningState.scaleY) * 15 * dt

    for i = #FloatingTexts, 1, -1 do
        local ft = FloatingTexts[i]
        ft.life = ft.life - dt
        ft.vy = ft.vy + 600 * dt 
        ft.x = ft.x + ft.vx * dt
        ft.y = ft.y + ft.vy * dt
        ft.scale = ft.scale + (1.0 - ft.scale) * dt * 12
        if ft.life <= 0 then table.remove(FloatingTexts, i) end
    end

    local floorY = 440
    for i = #Particles, 1, -1 do
        local p = Particles[i]
        p.life = p.life - dt
        p.rot = p.rot + p.rotV * dt
        
        if p.style == "plasma" then
            p.vy = p.vy - 150 * dt 
        else
            p.vy = p.vy + 1000 * dt 
            p.vx = p.vx * (1 - 2*dt) -- V12 Drag
        end
        
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        
        if p.y > floorY and p.style ~= "plasma" then 
            p.vy = -p.vy * love.math.random(0.3, 0.5) 
            p.y = floorY 
            p.vx = p.vx * 0.6 
        end
        if p.life <= 0 then table.remove(Particles, i) end
    end

    for i = #Dust, 1, -1 do
        local p = Dust[i]
        p.life = p.life - dt
        p.vy = p.vy - 10 * dt -- Dust rises
        p.size = p.size + 12 * dt -- Dust dissipates
        p.wobble = p.wobble + p.wobbleSpeed * dt
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        if p.life <= 0 then table.remove(Dust, i) end
    end
end

--------------------------------------------------------------------------------
-- 4. GAME STATE & MAIN LOOP
--------------------------------------------------------------------------------
local renderScale = 4

local function rollNewResource()
    Particles, FloatingTexts, Dust = {}, {}, {}
    MiningState = { shake = 0, scaleX = 1.0, scaleY = 1.0, screenFlash = 0, hitFlash = 0, lastHit = 0 }

    local archs = { "Wood", "Stone", "Obsidian", "Bedrock", "SpecialOre", "AlienOre" }
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Eridian"}
    
    local arch = archs[love.math.random(1, #archs)]
    local rarity = rarities[love.math.random(1, #rarities)]
    
    if arch == "Bedrock" or arch == "SpecialOre" then rarity = rarities[love.math.random(4, 7)] end
    if arch == "AlienOre" then rarity = "Eridian" end
    if arch == "Wood" or arch == "Stone" then rarity = rarities[love.math.random(1, 4)] end

    local data = generateResource(arch)

    ActiveItem = {
        image = data.img, w = data.w, h = data.h, arch = arch,
        rarity = rarity, rData = RARITIES[rarity],
        name = string.format("%s %s", rarity, arch)
    }
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough") -- V12 Gritty Lines
    love.mouse.setVisible(false)
    rollNewResource()
end

function love.keypressed(key)
    if key == "space" then rollNewResource() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.mousepressed(x, y, button)
    if button == 1 then triggerHarvest(ActiveItem) end
end

function love.update(dt)
    updatePhysics(dt)
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.push()
    if MiningState.shake > 0 then
        love.graphics.translate(love.math.random(-MiningState.shake, MiningState.shake), love.math.random(-MiningState.shake, MiningState.shake))
    end

    -- V12 Ecosystem Background sync
    love.graphics.clear(PALETTES.ui.bg)
    love.graphics.setColor(0.08, 0.1, 0.12, 0.4)
    local gridScroll = (time * 15) % 40
    for x = 0, 800, 40 do love.graphics.line(x - gridScroll, 0, x - gridScroll, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y, 800, y) end
    
    local pedX, pedY = 400, 380
    love.graphics.setColor(0.06, 0.08, 0.1)
    love.graphics.polygon("fill", pedX-100, pedY+30, pedX+100, pedY+30, pedX+140, pedY, pedX-140, pedY)
    love.graphics.setColor(0.04, 0.05, 0.07)
    love.graphics.polygon("fill", pedX-100, pedY+30, pedX+100, pedY+30, pedX+100, pedY+45, pedX-100, pedY+45)
    
    love.graphics.setColor(0.06, 0.07, 0.09)
    love.graphics.rectangle("fill", 0, 440, 800, 200)

    local idleY = math.sin(time * 3) * 6
    local idleRot = math.sin(time * 1.5) * 0.03
    local finalX, finalY = 400, 300 + idleY

    -- Aura Glow
    if ActiveItem.rData.glow > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local rc = ActiveItem.rData.color
        local pulse = (math.sin(time * 6) + 1) * 0.5
        love.graphics.setColor(rc[1], rc[2], rc[3], ActiveItem.rData.glow * 0.3 * pulse)
        love.graphics.ellipse("fill", 400, 420, ActiveItem.w * 2, 16)
        love.graphics.setColor(rc[1], rc[2], rc[3], ActiveItem.rData.glow * 0.1)
        love.graphics.circle("fill", finalX, finalY, ActiveItem.w * 3)
        love.graphics.setBlendMode("alpha")
    end

    -- Shadow
    love.graphics.setColor(0.02, 0.03, 0.04, 0.6)
    love.graphics.ellipse("fill", 400, 420, ActiveItem.w * 1.5, 12)

    -- Node Draw
    love.graphics.setColor(1, 1, 1, 1)
    local sX = renderScale * MiningState.scaleX
    local sY = renderScale * MiningState.scaleY
    love.graphics.draw(ActiveItem.image, finalX, finalY, idleRot, sX, sY, ActiveItem.w/2, ActiveItem.h/2)

    if MiningState.hitFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(1, 1, 1, MiningState.hitFlash)
        love.graphics.draw(ActiveItem.image, finalX, finalY, idleRot, sX, sY, ActiveItem.w/2, ActiveItem.h/2)
        love.graphics.setBlendMode("alpha")
    end

    -- Debris Particles
    for _, p in ipairs(Particles) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rot)
        
        if p.style == "plasma" or p.style == "glass" then
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.polygon("fill", 0, -p.size, p.size, 0, 0, p.size, -p.size, 0)
            love.graphics.setBlendMode("alpha")
        else
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", -p.size/2 - 1, -p.size/2 - 1, p.size + 2, p.size + 2)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size) 
        end
        love.graphics.pop()
    end
    
    -- Volumetric Dust (V12 Smoke System)
    for _, p in ipairs(Dust) do
        local alpha = p.life / p.maxLife
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.wobble)
        local s = p.size
        love.graphics.rectangle("fill", -s, -s/2, s*2, s)
        love.graphics.rectangle("fill", -s/2, -s, s, s*2)
        love.graphics.rectangle("fill", -s*0.7, -s*0.7, s*1.4, s*1.4)
        love.graphics.pop()
    end
    love.graphics.pop()

    if MiningState.screenFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local flashColor = ActiveItem.rData.color
        love.graphics.setColor(flashColor[1], flashColor[2], flashColor[3], MiningState.screenFlash * 0.4)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setBlendMode("alpha")
    end

    for _, ft in ipairs(FloatingTexts) do
        local alpha = math.min(1.0, ft.life * 3)
        love.graphics.push()
        love.graphics.translate(ft.x, ft.y)
        love.graphics.scale(ft.scale, ft.scale)
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.print(ft.text, -20 + 2, 2, 0, 2, 2) 
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
        love.graphics.print(ft.text, -20, 0, 0, 2, 2)
        love.graphics.pop()
    end

    -- V12 UI Layout Frame
    love.graphics.setColor(PALETTES.ui.panel)
    love.graphics.rectangle("fill", 20, 20, 320, 240, 12, 12)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.rectangle("line", 20, 20, 320, 240, 12, 12)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("[SPACE] Discover New Node", 40, 40)
    love.graphics.print("[L-CLICK] Mine / Harvest", 40, 60)
    
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.print(string.upper(ActiveItem.name), 40, 90, 0, 1.2, 1.2)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("TIER: ", 40, 115)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.print(string.upper(ActiveItem.rarity), 80, 115)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("CLASS: ", 180, 115)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.upper(ARCHETYPES[ActiveItem.arch].type), 235, 115)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("YIELD:", 40, 145)
    love.graphics.setColor(0.4, 0.8, 0.4)
    love.graphics.print(">> " .. string.upper(ARCHETYPES[ActiveItem.arch].drop) .. " RESOURCES", 50, 170)

    -- V12 Crosshair
    local cx, cy = MouseX, MouseY
    local sp = 4
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", cx - 1, cy - sp - 6, 2, 6)
    love.graphics.rectangle("fill", cx - 1, cy + sp, 2, 6)    
    love.graphics.rectangle("fill", cx - sp - 6, cy - 1, 6, 2)
    love.graphics.rectangle("fill", cx + sp, cy - 1, 6, 2)    
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.rectangle("fill", cx - 1, cy - 1, 2, 2)     
end