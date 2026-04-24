-- main.lua
-- Procedural Loot Generation Engine v13.1 (Maximum Detail, Parallax & Shockwaves)

local has_flags, FeatureFlags = pcall(require, "game.core.feature_flags")
local has_item_adapter, ItemCompat = pcall(require, "prototypes.adapters.item_compat")

local function is_flag_enabled(name)
    if not has_flags or type(FeatureFlags) ~= "table" or type(FeatureFlags.is_enabled) ~= "function" then
        return false
    end
    return FeatureFlags.is_enabled(name)
end

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES, RARITIES & SETTINGS
--------------------------------------------------------------------------------
local PALETTES = {
    outline = {0.1, 0.1, 0.12},
    metal   = { base={0.45, 0.45, 0.5}, dark={0.15, 0.15, 0.18}, highlight={0.7, 0.75, 0.8} },
    wood    = { base={0.55, 0.35, 0.2}, dark={0.35, 0.2, 0.1}, highlight={0.7, 0.5, 0.3} },
    alien   = { base={0.15, 0.2, 0.15}, dark={0.06, 0.09, 0.06}, node={0.8, 0.1, 0.5}, glow={1.0, 0.3, 0.8} },
    gold    = { base={0.9, 0.7, 0.1}, dark={0.5, 0.3, 0.05}, highlight={1.0, 0.9, 0.5} },
    leather = { base={0.4, 0.25, 0.15}, dark={0.2, 0.1, 0.05} },
    p2w     = { neon={1.0, 0.1, 0.6}, cyan={0.1, 1.0, 0.8}, trim={1.0, 0.9, 0.2}, white={1,1,1} },
    ui      = { bg={0.04, 0.05, 0.07}, panel={0.08, 0.1, 0.12, 0.95}, text={0.9, 0.9, 0.9} }
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2}, mult = 1, glow = 0.0 },
    Common    = { color = {0.6, 0.6, 0.6}, mult = 2, glow = 0.0 },
    Uncommon  = { color = {0.3, 0.8, 0.4}, mult = 4, glow = 0.1 },
    Rare      = { color = {0.2, 0.6, 1.0}, mult = 8, glow = 0.3 },
    Epic      = { color = {0.8, 0.3, 1.0}, mult = 15, glow = 0.6 },
    Legendary = { color = {1.0, 0.8, 0.2}, mult = 30, glow = 1.0 },
    Eridian   = { color = {0.9, 0.2, 0.8}, mult = 50, glow = 1.5 },
    P2W       = { color = {1.0, 0.1, 0.6}, mult = 100, glow = 2.0 } 
}

local ARCHETYPES = {
    SkeletonKey  = { w=32, h=48, type="Key",       class="Access",  particle="spark", drop="Unlocked" },
    Keycard      = { w=32, h=48, type="Key",       class="Tech",    particle="glass", drop="Decrypted" },
    EridianCipher= { w=48, h=48, type="Key",       class="Alien",   particle="plasma",drop="Resonated" },
    BanditLocker = { w=64, h=80, type="Chest",     class="Scrap",   particle="wood",  drop="Loot" },
    TechSafe     = { w=80, h=64, type="Chest",     class="Secure",  particle="metal", drop="High-Tech Loot" },
    AlienPod     = { w=72, h=72, type="Chest",     class="Organic", particle="plasma",drop="Biomass" },
    MicroBox     = { w=64, h=64, type="P2W Crate", class="Premium", particle="confetti",drop="Gems" },
    PremiumGacha = { w=64, h=96, type="P2W Crate", class="VIP",     particle="confetti",drop="Cosmetics" },
    WhaleVault   = { w=96, h=80, type="P2W Crate", class="Whale",   particle="coin",    drop="P2W Tokens" }
}

--------------------------------------------------------------------------------
-- 2. THE CANVAS GENERATOR (Maximum Detail Pixel Art)
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

local function generateContainer(archName)
    local arch = ARCHETYPES[archName]
    local w, h = arch.w, arch.h
    
    local img = makeCanvas(w, h, function()
        local cx, cy = math.floor(w / 2), math.floor(h / 2)
        
        -- ================= KEYS =================
        if archName == "SkeletonKey" then
            local m = PALETTES.metal
            -- Leather cord
            love.graphics.setColor(PALETTES.leather.base)
            love.graphics.circle("line", cx, cy - 20, 6)
            
            -- Key Bow (Ring)
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx, cy - 10, 10)
            love.graphics.setColor(m.base)
            love.graphics.circle("fill", cx, cy - 10, 8)
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx, cy - 10, 4) -- Hole
            
            -- Key Shaft
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 4, cy, 8, 20)
            love.graphics.setColor(m.base)
            love.graphics.rectangle("fill", cx - 2, cy, 4, 18)
            
            -- Key Teeth
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx + 2, cy + 6, 10, 12)
            love.graphics.setColor(m.base)
            love.graphics.rectangle("fill", cx + 2, cy + 8, 8, 4)
            love.graphics.rectangle("fill", cx + 2, cy + 14, 6, 2)
            
            -- Shading
            love.graphics.setColor(m.highlight)
            love.graphics.line(cx - 1, cy - 14, cx - 1, cy - 6)
            love.graphics.line(cx - 1, cy, cx - 1, cy + 16)

        elseif archName == "Keycard" then
            local m = PALETTES.metal
            -- Card Body
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 14, cy - 22, 28, 44, 4)
            love.graphics.setColor(m.base)
            love.graphics.rectangle("fill", cx - 12, cy - 20, 24, 40, 2)
            love.graphics.setColor(m.highlight)
            love.graphics.rectangle("fill", cx - 10, cy - 18, 20, 12, 1)
            
            -- Magnetic Strip
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 12, cy - 12, 24, 6)
            
            -- EMV Gold Chip
            love.graphics.setColor(PALETTES.gold.dark)
            love.graphics.rectangle("fill", cx - 8, cy + 2, 8, 6)
            love.graphics.setColor(PALETTES.gold.highlight)
            love.graphics.rectangle("fill", cx - 7, cy + 3, 6, 4)
            love.graphics.setColor(PALETTES.gold.dark)
            love.graphics.line(cx - 8, cy + 5, cx, cy + 5)
            
            -- Holographic Barcode / Text
            love.graphics.setColor(PALETTES.p2w.cyan)
            for i=0, 3 do
                love.graphics.rectangle("fill", cx + 2, cy + 2 + (i*2), love.math.random(4, 8), 1)
            end
            
            -- Hole punch for lanyard
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 4, cy - 18, 8, 2)

        elseif archName == "EridianCipher" then
            local p = PALETTES.alien
            -- Outer floating fragments
            love.graphics.setColor(p.node)
            love.graphics.polygon("fill", cx-18, cy-6, cx-12, cy, cx-18, cy+6)
            love.graphics.polygon("fill", cx+18, cy-6, cx+12, cy, cx+18, cy+6)
            
            -- Main Pyramid Core
            local pts = {cx, cy-20, cx+12, cy, cx, cy+20, cx-12, cy}
            drawPolygonWithOutline(pts, p.base, p.base, p.node)
            
            -- Inner glowing eye/core
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx, cy, 8)
            love.graphics.setColor(p.glow)
            love.graphics.circle("fill", cx, cy, 6)
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx-1, cy-4, 2, 8) -- slit pupil
            
            -- Runic lines
            love.graphics.setColor(p.glow)
            love.graphics.line(cx, cy-18, cx, cy-10)
            love.graphics.line(cx, cy+18, cx, cy+10)

        -- ================= CHESTS =================
        elseif archName == "BanditLocker" then
            local w = PALETTES.wood
            local m = PALETTES.metal
            
            -- Main Box
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 26, cy - 32, 52, 64, 4)
            love.graphics.setColor(w.dark)
            love.graphics.rectangle("fill", cx - 24, cy - 30, 48, 60, 2)
            
            -- Individual Wood Planks
            love.graphics.setColor(w.base)
            love.graphics.rectangle("fill", cx - 22, cy - 28, 12, 56)
            love.graphics.rectangle("fill", cx - 8, cy - 28, 16, 56)
            love.graphics.rectangle("fill", cx + 10, cy - 28, 12, 56)
            
            -- Wood highlights
            love.graphics.setColor(w.highlight)
            love.graphics.line(cx - 20, cy - 26, cx - 20, cy + 26)
            love.graphics.line(cx - 6, cy - 26, cx - 6, cy + 26)
            love.graphics.line(cx + 12, cy - 26, cx + 12, cy + 26)

            -- Heavy Metal Bands
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 26, cy - 18, 52, 12)
            love.graphics.rectangle("fill", cx - 26, cy + 16, 52, 12)
            love.graphics.setColor(m.base)
            love.graphics.rectangle("fill", cx - 26, cy - 16, 52, 8)
            love.graphics.rectangle("fill", cx - 26, cy + 18, 52, 8)
            
            -- Rivets
            love.graphics.setColor(m.highlight)
            for i=-20, 20, 10 do
                love.graphics.rectangle("fill", cx + i, cy - 14, 2, 2)
                love.graphics.rectangle("fill", cx + i, cy + 20, 2, 2)
            end

            -- Rusty Padlock
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 8, cy - 6, 16, 18)
            love.graphics.setColor(m.dark)
            love.graphics.rectangle("fill", cx - 6, cy - 4, 12, 14)
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("line", cx, cy - 4, 4) -- Lock shackle
            love.graphics.rectangle("fill", cx - 2, cy + 2, 4, 6) -- Keyhole

        elseif archName == "TechSafe" then
            local m = PALETTES.metal
            local c = PALETTES.p2w.cyan
            
            -- Heavy Beveled Body
            love.graphics.setColor(PALETTES.outline)
            love.graphics.polygon("fill", cx-36, cy-22, cx+36, cy-22, cx+40, cy+26, cx-40, cy+26)
            love.graphics.setColor(m.dark)
            love.graphics.polygon("fill", cx-34, cy-20, cx+34, cy-20, cx+38, cy+24, cx-38, cy+24)
            love.graphics.setColor(m.base)
            love.graphics.polygon("fill", cx-30, cy-16, cx+30, cy-16, cx+32, cy+20, cx-32, cy+20)
            love.graphics.setColor(m.highlight)
            love.graphics.line(cx-28, cy-14, cx+28, cy-14)
            
            -- Digital Keypad
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx + 10, cy - 10, 18, 24)
            love.graphics.setColor(m.dark)
            love.graphics.rectangle("fill", cx + 12, cy - 8, 14, 20)
            love.graphics.setColor(c)
            love.graphics.rectangle("fill", cx + 14, cy - 6, 10, 4) -- Screen
            love.graphics.setColor(1,0,0)
            love.graphics.rectangle("fill", cx + 14, cy + 2, 4, 4) -- Red button
            love.graphics.setColor(0,1,0)
            love.graphics.rectangle("fill", cx + 20, cy + 2, 4, 4) -- Green button
            love.graphics.rectangle("fill", cx + 14, cy + 8, 4, 4) 
            love.graphics.rectangle("fill", cx + 20, cy + 8, 4, 4) 

            -- Vault Wheel
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx - 12, cy + 4, 14)
            love.graphics.setColor(m.highlight)
            love.graphics.circle("fill", cx - 12, cy + 4, 12)
            love.graphics.setColor(PALETTES.outline)
            love.graphics.circle("fill", cx - 12, cy + 4, 6)
            love.graphics.setLineWidth(3)
            love.graphics.line(cx - 24, cy + 4, cx, cy + 4) -- Spokes
            love.graphics.line(cx - 12, cy - 8, cx - 12, cy + 16)
            love.graphics.setLineWidth(1)
            love.graphics.setColor(c)
            love.graphics.circle("fill", cx - 12, cy + 4, 4)

        elseif archName == "AlienPod" then
            local p = PALETTES.alien
            -- Base biomass
            love.graphics.setColor(PALETTES.outline)
            love.graphics.ellipse("fill", cx, cy + 6, 34, 24)
            love.graphics.setColor(p.base)
            love.graphics.ellipse("fill", cx, cy + 6, 32, 22)
            
            -- Tendrils / Veins
            love.graphics.setColor(p.dark)
            love.graphics.line(cx - 20, cy + 10, cx - 10, cy)
            love.graphics.line(cx + 20, cy + 10, cx + 10, cy)
            love.graphics.line(cx - 10, cy + 20, cx, cy + 10)
            
            -- Pulsing Egg Sac
            love.graphics.setColor(PALETTES.outline)
            love.graphics.ellipse("fill", cx, cy - 6, 24, 28)
            love.graphics.setColor(p.node)
            love.graphics.ellipse("fill", cx, cy - 6, 22, 26)
            love.graphics.setColor(p.glow)
            love.graphics.ellipse("fill", cx, cy - 6, 14, 18)
            love.graphics.setColor(1,1,1,0.6)
            love.graphics.ellipse("fill", cx - 4, cy - 12, 6, 8) -- Specular slime highlight

        -- ================= 3 P2W CRATES =================
        elseif archName == "MicroBox" then
            local p = PALETTES.p2w
            -- Box Body
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 22, cy - 20, 44, 40, 4)
            love.graphics.setColor(p.neon)
            love.graphics.rectangle("fill", cx - 20, cy - 18, 40, 36, 2)
            love.graphics.setColor(p.white)
            love.graphics.rectangle("line", cx - 18, cy - 16, 36, 32)
            
            -- Cyan Ribbon Wrap
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 6, cy - 18, 12, 36)
            love.graphics.rectangle("fill", cx - 20, cy - 6, 40, 12)
            love.graphics.setColor(p.cyan)
            love.graphics.rectangle("fill", cx - 4, cy - 18, 8, 36)
            love.graphics.rectangle("fill", cx - 20, cy - 4, 40, 8)
            
            -- Top Bow
            love.graphics.setColor(PALETTES.outline)
            love.graphics.polygon("fill", cx, cy-18, cx-14, cy-28, cx-14, cy-14)
            love.graphics.polygon("fill", cx, cy-18, cx+14, cy-28, cx+14, cy-14)
            love.graphics.setColor(p.cyan)
            love.graphics.polygon("fill", cx, cy-18, cx-12, cy-26, cx-12, cy-16)
            love.graphics.polygon("fill", cx, cy-18, cx+12, cy-26, cx+12, cy-16)
            love.graphics.setColor(p.trim)
            love.graphics.circle("fill", cx, cy - 18, 4)

        elseif archName == "PremiumGacha" then
            local p = PALETTES.p2w
            local g = PALETTES.gold
            local m = PALETTES.metal -- FIX APPLIED HERE
            
            -- Dispenser Base
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 22, cy + 4, 44, 36, 4)
            love.graphics.setColor(g.dark)
            love.graphics.rectangle("fill", cx - 20, cy + 6, 40, 32, 2)
            love.graphics.setColor(g.base)
            love.graphics.rectangle("fill", cx - 18, cy + 8, 36, 28)
            
            -- Coin Slot & Knob
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 14, cy + 12, 8, 14)
            love.graphics.rectangle("fill", cx + 4, cy + 14, 12, 12)
            love.graphics.setColor(m.base)
            love.graphics.rectangle("fill", cx - 12, cy + 14, 4, 10) -- Slot
            love.graphics.circle("fill", cx + 10, cy + 20, 4) -- Knob
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 10, cy + 30, 20, 6) -- Dispense hole
            
            -- Glass Dome
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx - 24, cy - 40, 48, 46, 24)
            love.graphics.setColor(p.cyan[1], p.cyan[2], p.cyan[3], 0.3)
            love.graphics.rectangle("fill", cx - 22, cy - 38, 44, 42, 22)
            
            -- Gacha Balls inside
            love.graphics.setColor(p.neon)
            love.graphics.circle("fill", cx - 10, cy - 10, 8)
            love.graphics.setColor(p.trim)
            love.graphics.circle("fill", cx + 8, cy - 6, 8)
            love.graphics.setColor(p.cyan)
            love.graphics.circle("fill", cx, cy - 22, 10)
            
            -- Glass Glare
            love.graphics.setColor(p.white[1], p.white[2], p.white[3], 0.6)
            love.graphics.polygon("fill", cx - 16, cy - 30, cx - 12, cy - 30, cx - 16, cy - 10, cx - 20, cy - 10)

        elseif archName == "WhaleVault" then
            local g = PALETTES.gold
            local p = PALETTES.p2w
            
            -- Massive Gold Chest Body
            love.graphics.setColor(PALETTES.outline)
            love.graphics.polygon("fill", cx-44, cy-12, cx+44, cy-12, cx+46, cy+32, cx-46, cy+32)
            love.graphics.setColor(g.dark)
            love.graphics.polygon("fill", cx-42, cy-10, cx+42, cy-10, cx+44, cy+30, cx-44, cy+30)
            love.graphics.setColor(g.base)
            love.graphics.polygon("fill", cx-38, cy-6, cx+38, cy-6, cx+40, cy+26, cx-40, cy+26)
            love.graphics.setColor(g.highlight)
            love.graphics.polygon("fill", cx-34, cy-2, cx+34, cy-2, cx+36, cy+18, cx-36, cy+18)
            
            -- Lid / Crown top
            love.graphics.setColor(PALETTES.outline)
            love.graphics.polygon("fill", cx-46, cy-12, cx+46, cy-12, cx+36, cy-32, cx-36, cy-32)
            love.graphics.setColor(p.neon) -- Gaudy pink velvet top
            love.graphics.polygon("fill", cx-44, cy-14, cx+44, cy-14, cx+34, cy-30, cx-34, cy-30)
            
            -- Gold Straps
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", cx-24, cy-34, 12, 64)
            love.graphics.rectangle("fill", cx+12, cy-34, 12, 64)
            love.graphics.setColor(g.highlight)
            love.graphics.rectangle("fill", cx-22, cy-32, 8, 60)
            love.graphics.rectangle("fill", cx+14, cy-32, 8, 60)
            
            -- Giant Diamond Center Lock
            love.graphics.setColor(PALETTES.outline)
            love.graphics.polygon("fill", cx, cy-16, cx+20, cy+2, cx, cy+24, cx-20, cy+2)
            love.graphics.setColor(p.cyan)
            love.graphics.polygon("fill", cx, cy-12, cx+16, cy+2, cx, cy+20, cx-16, cy+2)
            love.graphics.setColor(p.white)
            love.graphics.polygon("fill", cx, cy-6, cx+8, cy+2, cx, cy+12, cx-8, cy+2)
            love.graphics.line(cx-16, cy+2, cx+16, cy+2)
        end
    end)
    
    return { img = img, w = w, h = h }
end

--------------------------------------------------------------------------------
-- 3. INTERACTION, PHYSICS & PARTICLES (V13 Engine)
--------------------------------------------------------------------------------
local Particles, FloatingTexts, Dust, Shockwaves = {}, {}, {}, {}
local MouseX, MouseY = 400, 300
local ActiveItem = {}

local LootState = { shake = 0, scaleX = 1.0, scaleY = 1.0, screenFlash = 0, hitFlash = 0, lastHit = 0 }

local function triggerLoot(itemData)
    local t = love.timer.getTime()
    if t - LootState.lastHit < 0.2 then return end
    LootState.lastHit = t

    local arch = ARCHETYPES[itemData.arch]
    local isP2W = arch.type == "P2W Crate"
    
    -- Heavy physical squash on open
    LootState.shake = isP2W and 25 or 15
    LootState.scaleX = 1.5 
    LootState.scaleY = 0.5 
    LootState.hitFlash = 1.0 

    if isP2W or itemData.rarity == "Legendary" or itemData.rarity == "Eridian" then
        LootState.screenFlash = isP2W and 1.0 or 0.8
    end

    local cX, cY = 400, 320

    -- Shockwave Ping
    table.insert(Shockwaves, {
        x = cX, y = cY, radius = 10, maxRadius = isP2W and 250 or 150, life = 1.0, 
        color = itemData.rData.color, thickness = isP2W and 8 or 4
    })

    -- Floating Loot Text
    local val = math.floor(love.math.random(10, 50) * itemData.rData.mult)
    if arch.type == "Key" then val = 1 end
    
    table.insert(FloatingTexts, {
        x = cX, y = cY - 20, 
        vx = love.math.random(-40, 40), vy = love.math.random(-400, -200),
        text = "+" .. val .. " " .. arch.drop,
        color = itemData.rData.color, life = 2.5, scale = 0.1
    })

    -- Particle Explosion
    local numParticles = isP2W and love.math.random(30, 50) or love.math.random(10, 20)
    for i=1, numParticles do
        local angle = (math.pi + love.math.random() * math.pi) -- burst upward
        local speed = love.math.random(200, 700)
        
        local pColor = PALETTES.metal.highlight
        if arch.particle == "confetti" then 
            local colors = {PALETTES.p2w.neon, PALETTES.p2w.cyan, PALETTES.gold.base, {1,1,1}}
            pColor = colors[love.math.random(1, #colors)]
        elseif arch.particle == "coin" then pColor = PALETTES.gold.base
        elseif arch.particle == "plasma" then pColor = PALETTES.alien.glow
        elseif arch.particle == "glass" then pColor = PALETTES.p2w.cyan 
        elseif arch.particle == "wood" then pColor = PALETTES.wood.highlight end

        table.insert(Particles, {
            x = cX, y = cY, vx = math.cos(angle)*speed, vy = math.sin(angle)*speed,
            life = isP2W and love.math.random(1.0, 3.0) or love.math.random(0.5, 1.2), 
            maxLife = 3.0, size = love.math.random(4, 8),
            color = pColor, style = arch.particle, rot = love.math.random()*math.pi, rotV = love.math.random(-20, 20)
        })
    end

    -- Volumetric Dust Cloud
    if arch.type == "Chest" or arch.type == "P2W Crate" then
        for i=1, love.math.random(6, 12) do
            table.insert(Dust, {
                x = cX + love.math.random(-40, 40), y = cY + love.math.random(10, 30), 
                vx = love.math.random(-80, 80), vy = love.math.random(-20, 20),
                life = love.math.random(0.6, 1.2), maxLife = 1.2, size = love.math.random(8, 16),
                color = isP2W and PALETTES.gold.dark or {0.3, 0.3, 0.3}, blend = "alpha",
                wobble = love.math.random() * math.pi * 2, wobbleSpeed = love.math.random(-1, 1)
            })
        end
    end
end

local function updatePhysics(dt)
    LootState.shake = math.max(0, LootState.shake - dt * 50)
    LootState.screenFlash = math.max(0, LootState.screenFlash - dt * 3)
    LootState.hitFlash = math.max(0, LootState.hitFlash - dt * 10)
    
    LootState.scaleX = LootState.scaleX + (1.0 - LootState.scaleX) * 12 * dt
    LootState.scaleY = LootState.scaleY + (1.0 - LootState.scaleY) * 12 * dt

    for i = #Shockwaves, 1, -1 do
        local sw = Shockwaves[i]
        sw.life = sw.life - dt * 1.5
        sw.radius = sw.radius + (sw.maxRadius - sw.radius) * 10 * dt
        if sw.life <= 0 then table.remove(Shockwaves, i) end
    end

    for i = #FloatingTexts, 1, -1 do
        local ft = FloatingTexts[i]
        ft.life = ft.life - dt
        ft.vy = ft.vy + 700 * dt 
        ft.x = ft.x + ft.vx * dt
        ft.y = ft.y + ft.vy * dt
        ft.scale = ft.scale + (1.0 - ft.scale) * dt * 15
        if ft.life <= 0 then table.remove(FloatingTexts, i) end
    end

    local floorY = 440
    for i = #Particles, 1, -1 do
        local p = Particles[i]
        p.life = p.life - dt
        p.rot = p.rot + p.rotV * dt
        
        if p.style == "plasma" then
            p.vy = p.vy - 100 * dt 
        elseif p.style == "confetti" then
            p.vy = p.vy + 300 * dt 
            p.vx = p.vx * (1 - 3*dt) -- flutter drag
            p.rotV = p.rotV + math.sin(love.timer.getTime()*10) * 10 * dt
        else
            p.vy = p.vy + 1200 * dt 
            p.vx = p.vx * (1 - 2*dt)
        end
        
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        
        if p.y > floorY and p.style ~= "plasma" then 
            if p.style == "confetti" then
                p.y = floorY; p.vy = 0; p.vx = 0; p.rotV = 0 -- stick to floor
            else
                p.vy = -p.vy * love.math.random(0.3, 0.6) 
                p.y = floorY 
                p.vx = p.vx * 0.5 
            end
        end
        if p.life <= 0 then table.remove(Particles, i) end
    end

    for i = #Dust, 1, -1 do
        local p = Dust[i]
        p.life = p.life - dt
        p.vy = p.vy - 15 * dt 
        p.size = p.size + 20 * dt 
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

local ITEM_ARCH_COMPAT_MAP = {
    toolkit = "BanditLocker",
    keycard = "Keycard",
    cache_crate = "TechSafe",
}

local RARITY_COMPAT_MAP = {
    scrap = "Scrap",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    eridian = "Eridian",
    p2w = "P2W",
}

local function read_compat_meta(compat)
    if type(compat) ~= "table" or type(compat.meta) ~= "table" then
        return {}
    end
    return compat.meta
end

local function normalize_dimension(value, fallback)
    local n = tonumber(value)
    if n and n > 0 then
        return n
    end
    return fallback
end

local function rollNewContainer()
    Particles, FloatingTexts, Dust, Shockwaves = {}, {}, {}, {}
    LootState = { shake = 0, scaleX = 1.0, scaleY = 1.0, screenFlash = 0, hitFlash = 0, lastHit = 0 }
    if is_flag_enabled("enable_mte_item_gen") and has_item_adapter and type(ItemCompat.rollNewItem) == "function" then
        local compat, compat_err = ItemCompat.rollNewItem()
        if compat and compat.image then
            local meta = read_compat_meta(compat)
            local arch_key = tostring(meta.archetype or compat.arch or "toolkit"):lower()
            local arch_name = ITEM_ARCH_COMPAT_MAP[arch_key] or "BanditLocker"
            local arch = ARCHETYPES[arch_name] or ARCHETYPES.BanditLocker
            local rarity_key = tostring(meta.rarity or "common"):lower()
            local rarity = RARITY_COMPAT_MAP[rarity_key] or "Common"
            ActiveItem = {
                image = compat.image,
                w = normalize_dimension(compat.w, 64),
                h = normalize_dimension(compat.h, 64),
                arch = arch_name,
                rarity = rarity,
                rData = RARITIES[rarity] or RARITIES.Common,
                def = arch,
                name = compat.name or (rarity .. " " .. arch_name),
            }
            return
        end
        if compat_err then
            print("MTE item adapter failed; falling back to legacy generator: " .. tostring(compat_err))
        end
    end

    local archs = { 
        "SkeletonKey", "Keycard", "EridianCipher", 
        "BanditLocker", "TechSafe", "AlienPod", 
        "MicroBox", "PremiumGacha", "WhaleVault" 
    }
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Eridian", "P2W"}
    
    local archName = archs[love.math.random(1, #archs)]
    local arch = ARCHETYPES[archName]
    local rarity = rarities[love.math.random(1, 5)]
    
    if arch.type == "Key" then rarity = rarities[love.math.random(1, 4)] end
    if archName == "EridianCipher" or archName == "AlienPod" then rarity = "Eridian" end
    if arch.type == "P2W Crate" then rarity = "P2W" end 

    local data = generateContainer(archName)

    ActiveItem = {
        image = data.img, w = data.w, h = data.h, arch = archName,
        rarity = rarity, rData = RARITIES[rarity], def = arch,
        name = string.format("%s %s", rarity, (arch.type == "Key" and arch.class.." Key" or archName))
    }
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)
    rollNewContainer()
end

function love.keypressed(key)
    if key == "space" then rollNewContainer() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.mousepressed(x, y, button)
    if button == 1 then triggerLoot(ActiveItem) end
end

function love.update(dt)
    updatePhysics(dt)
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.push()
    if LootState.shake > 0 then
        love.graphics.translate(love.math.random(-LootState.shake, LootState.shake), love.math.random(-LootState.shake, LootState.shake))
    end

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

    -- Parallax & Hover Math
    local idleY = math.sin(time * 3) * 6
    local idleRot = math.sin(time * 1.5) * 0.03
    
    if ActiveItem.def.type == "Key" then
        idleY = math.sin(time * 4) * 12 - 20
        idleRot = math.sin(time * 2) * 0.1
    end
    
    -- Mouse Tilt Parallax
    local mNormX = (MouseX - 400) / 400
    local tilt = mNormX * 0.15
    local finalX = 400 + (mNormX * 20)
    local finalY = 300 + idleY

    -- Shockwaves (Drawn behind item)
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, sw in ipairs(Shockwaves) do
        love.graphics.setColor(sw.color[1], sw.color[2], sw.color[3], sw.life * 0.8)
        love.graphics.setLineWidth(sw.thickness)
        love.graphics.circle("line", sw.x, sw.y, sw.radius)
        love.graphics.setColor(sw.color[1], sw.color[2], sw.color[3], sw.life * 0.2)
        love.graphics.circle("fill", sw.x, sw.y, sw.radius * 0.9)
    end
    love.graphics.setLineWidth(1)
    love.graphics.setBlendMode("alpha")

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

    -- Draw Main Object
    love.graphics.setColor(1, 1, 1, 1)
    local sX = renderScale * LootState.scaleX
    local sY = renderScale * LootState.scaleY
    love.graphics.draw(ActiveItem.image, finalX, finalY, idleRot + tilt, sX, sY, ActiveItem.w/2, ActiveItem.h/2)

    if LootState.hitFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(1, 1, 1, LootState.hitFlash)
        love.graphics.draw(ActiveItem.image, finalX, finalY, idleRot + tilt, sX, sY, ActiveItem.w/2, ActiveItem.h/2)
        love.graphics.setBlendMode("alpha")
    end

    -- Particles
    for _, p in ipairs(Particles) do
        local alpha = p.life / 1.0 -- Fade out in last second
        if alpha > 1 then alpha = 1 end
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(p.rot)
        
        if p.style == "plasma" or p.style == "glass" then
            love.graphics.setBlendMode("add", "alphamultiply")
            love.graphics.polygon("fill", 0, -p.size, p.size, 0, 0, p.size, -p.size, 0)
            love.graphics.setBlendMode("alpha")
        elseif p.style == "coin" then
            love.graphics.ellipse("fill", 0, 0, p.size, p.size * 0.5)
            love.graphics.setColor(1,1,1, alpha * 0.8)
            love.graphics.ellipse("fill", 0, 0, p.size*0.5, p.size*0.2)
        elseif p.style == "confetti" then
            love.graphics.rectangle("fill", -p.size/2, -p.size/4, p.size, p.size/2)
        else
            love.graphics.setColor(PALETTES.outline)
            love.graphics.rectangle("fill", -p.size/2 - 1, -p.size/2 - 1, p.size + 2, p.size + 2)
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.rectangle("fill", -p.size/2, -p.size/2, p.size, p.size) 
        end
        love.graphics.pop()
    end
    
    -- Volumetric Dust Cloud
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

    if LootState.screenFlash > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local flashColor = ActiveItem.rData.color
        love.graphics.setColor(flashColor[1], flashColor[2], flashColor[3], LootState.screenFlash * 0.4)
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

    -- Custom Crosshair
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