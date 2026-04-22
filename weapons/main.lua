-- main.lua
-- Procedural Weapon Generation Engine v12.0 (Organic Smoke & Detail Polish)

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES, RARITIES & SETTINGS
--------------------------------------------------------------------------------
local PALETTES = {
    metal = { base={0.45, 0.45, 0.5}, dark={0.15, 0.15, 0.18}, highlight={0.7, 0.75, 0.8} },
    gold  = { base={0.9, 0.7, 0.1}, dark={0.5, 0.3, 0.05}, highlight={1.0, 0.9, 0.5} },
    brass = { base={0.9, 0.7, 0.2}, dark={0.6, 0.4, 0.1}, highlight={1.0, 0.9, 0.5} },
    mats = {
        wood  = { base={0.5, 0.35, 0.2}, dark={0.25, 0.15, 0.08}, highlight={0.6, 0.45, 0.25}, name="Wood" },
        comp  = { base={0.18, 0.18, 0.2}, dark={0.05, 0.05, 0.08}, highlight={0.3, 0.3, 0.35}, name="Polymer" },
        tan   = { base={0.65, 0.55, 0.4}, dark={0.4, 0.35, 0.25}, highlight={0.8, 0.7, 0.5}, name="Desert Tan" },
        olive = { base={0.35, 0.45, 0.3}, dark={0.15, 0.25, 0.15}, highlight={0.5, 0.6, 0.45}, name="Olive Drab" },
        scrap = { base={0.6, 0.3, 0.15}, dark={0.3, 0.1, 0.05}, highlight={0.8, 0.4, 0.2}, name="Rusted" },
        cyber = { base={0.9, 0.9, 0.95}, dark={0.5, 0.5, 0.6}, highlight={1.0, 1.0, 1.0}, name="Ceramic" }
    },
    ui    = { bg={0.04, 0.05, 0.07}, panel={0.08, 0.1, 0.12, 0.95}, text={0.9, 0.9, 0.9} },
    spells = {
        plasma = { base={0.2, 0.9, 1.0}, highlight={0.8, 1.0, 1.0}, style="float", blend="add" },
        fire   = { base={1.0, 0.4, 0.1}, highlight={1.0, 0.9, 0.2}, style="burn", blend="add" },
        shock  = { base={0.8, 0.9, 0.1}, highlight={1.0, 1.0, 0.8}, style="zap", blend="add" },
        poison = { base={0.4, 0.9, 0.2}, highlight={0.7, 1.0, 0.4}, style="drip", blend="alpha" },
        ice    = { base={0.6, 1.0, 1.0}, highlight={1.0, 1.0, 1.0}, style="shatter", blend="add" },
        void   = { base={0.15, 0.05, 0.25}, highlight={0.3, 0.1, 0.5}, style="void", blend="alpha" },
        none   = { base={1.0, 0.9, 0.6}, highlight={1.0, 1.0, 1.0}, style="kinetic", blend="add" }
    }
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2}, mods = 0, p_mult = 0.2, stats = {dmg=0.5, speed=0.8} },
    Common    = { color = {0.6, 0.6, 0.6}, mods = 0, p_mult = 0.5, stats = {dmg=1.0, speed=1.0} },
    Uncommon  = { color = {0.3, 0.8, 0.4}, mods = 1, p_mult = 0.8, stats = {dmg=1.2, speed=1.1} },
    Rare      = { color = {0.2, 0.6, 1.0}, mods = 2, p_mult = 1.2, stats = {dmg=1.5, speed=1.2} },
    Epic      = { color = {0.8, 0.3, 1.0}, mods = 3, p_mult = 2.0, stats = {dmg=2.0, speed=1.4} },
    Legendary = { color = {1.0, 0.8, 0.2}, mods = 4, p_mult = 3.5, stats = {dmg=3.0, speed=1.8} },
    Mythic    = { color = {0.1, 1.0, 0.8}, mods = 4, p_mult = 4.5, stats = {dmg=4.0, speed=2.0} },
    P2W       = { color = {1.0, 0.1, 0.6}, mods = 5, p_mult = 6.0, stats = {dmg=6.0, speed=3.0} }
}

local WEAPON_ARCHETYPES = {
    Revolver       = { w=64, h=48, b_len=12, b_thick=4, rec_len=12, rec_thick=8, grip=10, stock=0, fireDelay=0.4, kick=15, pellets=1, spread=0.02, shell=2 },
    HandCannon     = { w=80, h=48, b_len=16, b_thick=6, rec_len=16, rec_thick=10, grip=12, stock=0, fireDelay=0.6, kick=35, pellets=1, spread=0.01, shell=3 },
    Pistol         = { w=64, h=48, b_len=10, b_thick=5, rec_len=14, rec_thick=8, grip=10, stock=0, fireDelay=0.2, kick=8, pellets=1, spread=0.04, shell=1 },
    MachinePistol  = { w=64, h=48, b_len=8,  b_thick=5, rec_len=12, rec_thick=8, grip=10, stock=0, fireDelay=0.06, kick=6, pellets=1, spread=0.15, shell=1 },
    SMG            = { w=80, h=48, b_len=12, b_thick=5, rec_len=16, rec_thick=10, grip=12, stock=10, fireDelay=0.08, kick=4, pellets=1, spread=0.1, shell=1 },
    VectorSMG      = { w=80, h=48, b_len=10, b_thick=6, rec_len=16, rec_thick=12, grip=12, stock=12, fireDelay=0.05, kick=2, pellets=1, spread=0.08, shell=1 },
    AssaultRifle   = { w=96, h=48, b_len=24, b_thick=6, rec_len=20, rec_thick=10, grip=12, stock=16, fireDelay=0.12, kick=6, pellets=1, spread=0.05, shell=2 },
    BullpupRifle   = { w=96, h=48, b_len=26, b_thick=6, rec_len=16, rec_thick=10, grip=12, stock=20, fireDelay=0.1, kick=5, pellets=1, spread=0.04, shell=2 },
    DMR            = { w=112, h=48, b_len=30, b_thick=5, rec_len=22, rec_thick=9, grip=12, stock=16, fireDelay=0.4, kick=18, pellets=1, spread=0.01, shell=3 },
    Shotgun        = { w=96, h=48, b_len=24, b_thick=6, rec_len=18, rec_thick=10, grip=12, stock=14, fireDelay=0.7, kick=25, pellets=8, spread=0.25, shell=3 },
    AutoShotgun    = { w=96, h=48, b_len=20, b_thick=8, rec_len=24, rec_thick=12, grip=12, stock=14, fireDelay=0.2, kick=18, pellets=5, spread=0.2, shell=3 },
    SawedOff       = { w=64, h=48, b_len=10, b_thick=8, rec_len=12, rec_thick=8, grip=10, stock=0, fireDelay=0.9, kick=40, pellets=10, spread=0.4, shell=3 },
    DoubleBarrel   = { w=80, h=48, b_len=18, b_thick=8, rec_len=14, rec_thick=8, grip=12, stock=14, fireDelay=1.0, kick=45, pellets=12, spread=0.35, shell=3 },
    SniperRifle    = { w=112, h=48, b_len=36, b_thick=4, rec_len=20, rec_thick=9, grip=12, stock=18, fireDelay=1.2, kick=35, pellets=1, spread=0.0, shell=4 },
    HeavyMG        = { w=112, h=64, b_len=32, b_thick=8, rec_len=28, rec_thick=14, grip=14, stock=18, fireDelay=0.08, kick=8, pellets=1, spread=0.12, shell=3 },
    Minigun        = { w=112, h=64, b_len=30, b_thick=14, rec_len=26, rec_thick=16, grip=14, stock=0, fireDelay=0.04, kick=3, pellets=1, spread=0.15, shell=2 },
    RocketLauncher = { w=112, h=64, b_len=40, b_thick=12, rec_len=24, rec_thick=14, grip=12, stock=10, fireDelay=1.5, kick=40, pellets=1, spread=0.0, shell=0 }
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

local function generateGun(archName, rarityName, element, mods)
    local arch = WEAPON_ARCHETYPES[archName]
    local w, h = arch.w, arch.h
    local rData = RARITIES[rarityName]
    
    local cMetal = PALETTES.metal
    local skinPool = {PALETTES.mats.wood, PALETTES.mats.comp, PALETTES.mats.tan, PALETTES.mats.olive}
    local cMat = skinPool[love.math.random(1, #skinPool)]
    
    if rarityName == "Scrap" then cMat = PALETTES.mats.scrap; cMetal = PALETTES.mats.scrap end
    if rarityName == "Mythic" then cMat = PALETTES.mats.cyber; cMetal = PALETTES.mats.cyber end
    if rarityName == "P2W" then cMat = PALETTES.mats.comp; cMetal = PALETTES.gold end
    
    local finalSkinName = cMat.name
    
    local canvasData = makeCanvas(w, h, function()
        local rx, ry = math.floor(w * 0.35), math.floor(h * 0.4)
        local magLen = mods.extended_clip and 16 or 8
        if archName == "MachinePistol" then magLen = magLen + 6 end
        local laserAnchor = nil

        if arch.stock > 0 then drawComponent(rx - arch.stock, ry + 2, arch.stock, 6, cMat.base, cMetal.dark, cMat.highlight) end

        local magX = rx + math.floor(arch.rec_len * 0.6)
        if archName == "BullpupRifle" then magX = rx - 10
        elseif archName == "VectorSMG" then magX = rx + 6 end

        if mods.drum_mag or archName == "AutoShotgun" or archName == "HeavyMG" then
            drawComponent(magX - 4, ry + arch.rec_thick, 14, 14, cMetal.base, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(cMetal.dark)
            love.graphics.circle("fill", magX + 3, ry + arch.rec_thick + 7, 4)
        else
            drawComponent(magX, ry + arch.rec_thick, 6, magLen, cMetal.base, cMetal.dark, nil)
        end

        local gripX = rx + 2
        drawComponent(gripX, ry + arch.rec_thick, 6, arch.grip, cMat.base, cMetal.dark, nil)
        love.graphics.setColor(cMetal.dark)
        for i = 2, arch.grip - 2, 3 do love.graphics.line(gripX, ry + arch.rec_thick + i, gripX + 6, ry + arch.rec_thick + i) end

        if archName == "VectorSMG" then
            love.graphics.setColor(cMetal.dark)
            love.graphics.polygon("fill", gripX+6, ry+arch.rec_thick-1, magX+8, ry+arch.rec_thick-1, gripX+6, ry+arch.rec_thick+10)
            love.graphics.setColor(cMetal.base)
            love.graphics.polygon("fill", gripX+7, ry+arch.rec_thick, magX+6, ry+arch.rec_thick, gripX+7, ry+arch.rec_thick+8)
        end

        local barrelY = ry + math.floor(arch.rec_thick / 2) - math.floor(arch.b_thick / 2)
        drawComponent(rx + arch.rec_len, barrelY, arch.b_len, arch.b_thick, cMetal.base, cMetal.dark, cMetal.highlight)

        if archName == "Shotgun" then
            drawComponent(rx + arch.rec_len + 4, barrelY + 2, 12, 4, cMat.base, cMetal.dark, cMat.highlight)
        elseif archName == "SawedOff" then
            drawComponent(rx + arch.rec_len + 2, barrelY + 4, 6, 4, cMat.base, cMetal.dark, nil)
        elseif archName == "DoubleBarrel" then
            love.graphics.setColor(cMetal.dark)
            love.graphics.rectangle("fill", rx + arch.rec_len, barrelY + math.floor(arch.b_thick/2) - 1, arch.b_len, 2)
            drawComponent(rx + arch.rec_len, barrelY + arch.b_thick, 10, 3, cMat.base, cMetal.dark, nil)
        elseif archName == "Minigun" then
            love.graphics.setColor(cMetal.dark)
            love.graphics.rectangle("fill", rx + arch.rec_len, barrelY + math.floor(arch.b_thick/2), arch.b_len, 2)
        end

        drawComponent(rx, ry, arch.rec_len, arch.rec_thick, cMetal.base, cMetal.dark, cMetal.highlight)

        love.graphics.setColor(cMetal.dark)
        love.graphics.rectangle("fill", rx + 2, ry + 2, 1, 1)
        love.graphics.rectangle("fill", rx + arch.rec_len - 3, ry + 2, 1, 1)
        love.graphics.rectangle("fill", rx + 2, ry + arch.rec_thick - 3, 1, 1)
        love.graphics.setColor(cMetal.highlight)
        love.graphics.rectangle("fill", rx + math.floor(arch.rec_len/2), ry + 2, 2, 1)
        
        love.graphics.setColor(cMetal.dark)
        love.graphics.rectangle("fill", gripX + 6, ry + arch.rec_thick, 6, 5)
        love.graphics.setColor(0, 0, 0, 0)
        love.graphics.setBlendMode("replace")
        love.graphics.rectangle("fill", gripX + 7, ry + arch.rec_thick, 4, 3)
        love.graphics.setBlendMode("alpha")
        love.graphics.setColor(cMetal.highlight)
        love.graphics.rectangle("fill", gripX + 7, ry + arch.rec_thick, 2, 2)

        if element ~= "none" then
            local spell = PALETTES.spells[element]
            love.graphics.setColor(0.1, 0.1, 0.1)
            love.graphics.rectangle("fill", rx + 8, ry + 2, arch.rec_len - 12, arch.rec_thick - 4)
            love.graphics.setColor(spell.base)
            love.graphics.rectangle("fill", rx + 9, ry + 3, arch.rec_len - 14, arch.rec_thick - 6)
        end

        if rarityName == "P2W" then
            love.graphics.setColor(1.0, 0.1, 0.6)
            love.graphics.rectangle("fill", rx, ry, 2, arch.rec_thick)
            love.graphics.rectangle("fill", rx + 4, ry + arch.rec_thick - 2, arch.rec_len - 8, 2)
        elseif rarityName == "Mythic" then
            love.graphics.setColor(0.1, 1.0, 0.8)
            love.graphics.rectangle("fill", rx, ry, 2, arch.rec_thick)
            love.graphics.rectangle("fill", rx + arch.rec_len - 6, ry + 2, 4, 2)
        else
            love.graphics.setColor(rData.color)
            love.graphics.rectangle("fill", rx, ry, 2, arch.rec_thick)
        end

        if mods.red_dot or mods.extended_sight then
            local sLen = mods.extended_sight and 12 or 6
            local sX = rx + math.floor(arch.rec_len/2) - math.floor(sLen/2)
            drawComponent(sX, ry - 4, sLen, 3, cMetal.base, cMetal.dark, cMetal.highlight)
            love.graphics.setColor(cMetal.dark)
            love.graphics.rectangle("fill", rx + math.floor(arch.rec_len/2), ry - 1, 2, 1)
            if mods.red_dot then
                love.graphics.setColor(1, 0, 0)
                love.graphics.rectangle("fill", sX + sLen - 2, ry - 3, 2, 2)
                laserAnchor = {x = sX + sLen, y = ry - 2}
            end
        end

        if mods.foregrip then
            local fgX = rx + arch.rec_len + 2
            local fgY = barrelY + arch.b_thick
            drawComponent(fgX, fgY, 4, 8, PALETTES.mats.comp.base, cMetal.dark, nil)
        end

        if mods.bayonet then
            local byX = rx + arch.rec_len + arch.b_len - 2
            local byY = barrelY + arch.b_thick
            love.graphics.setColor(cMetal.dark)
            love.graphics.polygon("fill", byX, byY-1, byX+14, byY+2, byX+2, byY+5)
            love.graphics.setColor(cMetal.base)
            love.graphics.polygon("fill", byX+1, byY, byX+12, byY+2, byX+2, byY+4)
            love.graphics.setColor(cMetal.highlight)
            love.graphics.line(byX+1, byY, byX+12, byY+2)
        end

        local muzzleOffset = 0
        if mods.silencer then
            muzzleOffset = 14
            drawComponent(rx + arch.rec_len + arch.b_len, barrelY - 1, 14, arch.b_thick + 2, PALETTES.mats.comp.base, cMetal.dark, PALETTES.mats.comp.highlight)
        end

        local coreX, coreY = rx + math.floor(arch.rec_len/2), ry + math.floor(arch.rec_thick/2)
        local muzzleX = rx + arch.rec_len + arch.b_len + muzzleOffset
        local muzzleY = barrelY + math.floor(arch.b_thick/2)
        
        return { muzzle = {x=muzzleX, y=muzzleY}, core = {x=coreX, y=coreY}, laser = laserAnchor }
    end)
    
    canvasData.skinName = finalSkinName
    return canvasData
end

--------------------------------------------------------------------------------
-- 3. COMBAT, EFFECTS & MICROINTERACTIONS
--------------------------------------------------------------------------------
local Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
local MouseX, MouseY = 400, 300

local CombatState = { shake = 0, recoilX = 0, recoilRot = 0, fireTimer = 0, crosshairSpread = 0, flashLight = 0 }

local function spawnDebris(x, y, color)
    -- V12 POLISH: Toned down sparks drastically. Smaller, fewer, and they lose momentum fast.
    table.insert(Flashes, {x=x, y=y, life=love.math.random(0.02, 0.04), size=love.math.random(2, 4), rot=0, color={1,1,1}})
    for i=1, love.math.random(1, 3) do
        table.insert(Particles, {
            x = x, y = y, vx = love.math.random(-100, -20), vy = love.math.random(-80, 80),
            life = love.math.random(0.1, 0.2), maxLife = 0.2, size = love.math.random(1, 2),
            color = color, blend = "add", style = "debris"
        })
    end
end

local function spawnProjectile(x, y, spellData, archData)
    local p = {
        x = x, y = y, speed = love.math.random(1500, 2400),
        angle = (love.math.random() - 0.5) * archData.spread, life = 2.0,
        color = spellData.highlight, baseColor = spellData.base, style = spellData.style, history = {}
    }
    p.vx = math.cos(p.angle) * p.speed
    p.vy = math.sin(p.angle) * p.speed
    table.insert(Projectiles, p)
end

local function triggerFire(weaponData)
    if CombatState.fireTimer > 0 then return end
    local arch = WEAPON_ARCHETYPES[weaponData.arch]
    
    local speedVar = love.math.random(90, 110) / 100
    CombatState.fireTimer = (arch.fireDelay / weaponData.rData.stats.speed) * speedVar
    
    local kickMod = weaponData.mods.foregrip and 0.5 or 1.0
    local kickVar = love.math.random(85, 115) / 100
    local actualKick = arch.kick * kickMod * kickVar

    CombatState.recoilX = CombatState.recoilX - actualKick
    CombatState.recoilRot = CombatState.recoilRot - (actualKick * 0.005)
    CombatState.shake = actualKick * 0.4
    CombatState.crosshairSpread = math.min(30, CombatState.crosshairSpread + actualKick)
    CombatState.flashLight = love.math.random(50, 90) / 100

    local scale = 4
    local time = love.timer.getTime()
    local idleY = math.sin(time * 3) * 6
    local idleRot = math.sin(time * 2) * 0.02
    local wX, wY = 400, 300 + idleY
    local rot = CombatState.recoilRot + idleRot
    
    local function getRotatedAnchor(anchor)
        if not anchor then return nil, nil end
        local dx = (anchor.x - weaponData.w/2) * scale
        local dy = (anchor.y - weaponData.h/2) * scale
        local rx = dx * math.cos(rot) - dy * math.sin(rot)
        local ry = dx * math.sin(rot) + dy * math.cos(rot)
        return wX + rx + CombatState.recoilX, wY + ry
    end

    local mX, mY = getRotatedAnchor(weaponData.anchors.muzzle)
    local cX, cY = getRotatedAnchor(weaponData.anchors.core)

    local spellData = PALETTES.spells[weaponData.element]
    table.insert(Flashes, {
        x = mX, y = mY, life = love.math.random(0.04, 0.06), 
        size = actualKick * love.math.random(0.5, 0.8), 
        rot = rot + love.math.random(-0.2, 0.2), color = spellData.base
    })
    
    -- V12 POLISH: Volumetric Smoke. Drastically reduced spawn rate and opacity.
    if love.math.random() > 0.6 then -- Only 40% chance per bullet
        table.insert(Particles, {
            x = mX + love.math.random(-2, 2), y = mY + love.math.random(-2, 2), 
            vx = love.math.random(-15, 15), vy = love.math.random(-20, -5),
            life = love.math.random(0.4, 0.7), maxLife = 0.7, size = love.math.random(2, 5),
            color = {0.6, 0.6, 0.6}, blend = "alpha", style = "smoke",
            wobble = love.math.random() * math.pi * 2, wobbleSpeed = love.math.random(-1, 1)
        })
    end
    
    for i=1, arch.pellets do spawnProjectile(mX, mY, spellData, arch) end
    
    if arch.shell > 0 then
        table.insert(Casings, {
            x = cX, y = cY, 
            vx = love.math.random(-150, -60), vy = love.math.random(-300, -180),
            rot = love.math.random() * math.pi * 2, rotV = love.math.random(-12, 12), 
            size = arch.shell, life = 2.0
        })
    end
end

local function updateCombatPhysics(dt)
    CombatState.fireTimer = math.max(0, CombatState.fireTimer - dt)
    CombatState.recoilX = CombatState.recoilX + (0 - CombatState.recoilX) * 12 * dt
    CombatState.recoilRot = CombatState.recoilRot + (0 - CombatState.recoilRot) * 12 * dt
    CombatState.shake = math.max(0, CombatState.shake - dt * 45)
    CombatState.crosshairSpread = CombatState.crosshairSpread + (0 - CombatState.crosshairSpread) * 15 * dt
    CombatState.flashLight = math.max(0, CombatState.flashLight - dt * 12)

    local floorY = 440
    for i = #Casings, 1, -1 do
        local c = Casings[i]
        c.life = c.life - dt
        c.vy = c.vy + 750 * dt
        c.x = c.x + c.vx * dt; c.y = c.y + c.vy * dt; c.rot = c.rot + c.rotV * dt
        if c.y > floorY then 
            c.y = floorY; c.vy = -c.vy * love.math.random(0.3, 0.5)
            c.vx = c.vx * 0.5; c.rotV = c.rotV * 0.5 
        end
        if c.life <= 0 then table.remove(Casings, i) end
    end

    for i = #Projectiles, 1, -1 do
        local p = Projectiles[i]
        p.life = p.life - dt
        table.insert(p.history, 1, {x = p.x, y = p.y})
        if #p.history > 12 then table.remove(p.history) end
        p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
        if p.x > 850 or p.life <= 0 then
            spawnDebris(math.min(p.x, 830), p.y, p.color)
            table.remove(Projectiles, i)
        end
    end

    for i = #Flashes, 1, -1 do
        Flashes[i].life = Flashes[i].life - dt
        if Flashes[i].life <= 0 then table.remove(Flashes, i) end
    end

    for i = #Particles, 1, -1 do
        local p = Particles[i]
        p.life = p.life - dt
        if p.style == "debris" then
            p.vy = p.vy + 500 * dt
            p.vx = p.vx * (1 - 2*dt) -- V12 POLISH: Sparks drag horizontally and slow down
            p.x = p.x + p.vx * dt; p.y = p.y + p.vy * dt
            if p.y > floorY then p.vy = -p.vy * 0.4; p.y = floorY end
        elseif p.style == "smoke" then
            p.vy = p.vy - 10 * dt
            p.size = p.size + 10 * dt
            p.wobble = p.wobble + p.wobbleSpeed * dt
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
        end
        if p.life <= 0 then table.remove(Particles, i) end
    end
end

--------------------------------------------------------------------------------
-- 4. GAME STATE & MAIN LOOP
--------------------------------------------------------------------------------
local Weapon = {}
local renderScale = 4

local function rollNewWeapon()
    Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
    local archs = {
        "Revolver", "HandCannon", "Pistol", "MachinePistol", 
        "SMG", "VectorSMG", "AssaultRifle", "BullpupRifle", "DMR",
        "Shotgun", "AutoShotgun", "SawedOff", "DoubleBarrel", 
        "SniperRifle", "HeavyMG", "Minigun", "RocketLauncher"
    }
    local spells = {"none", "none", "plasma", "fire", "shock", "poison", "ice", "void"}
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "P2W"}
    
    local arch = archs[love.math.random(1, #archs)]
    local element = spells[love.math.random(1, #spells)]
    local rarity = rarities[love.math.random(1, #rarities)]
    local rData = RARITIES[rarity]
    
    local availableMods = {"extended_clip", "drum_mag", "red_dot", "extended_sight", "silencer", "foregrip", "bayonet"}
    local mods = {}
    for i=1, rData.mods do
        if #availableMods > 0 then
            local idx = love.math.random(1, #availableMods)
            mods[availableMods[idx]] = true
            table.remove(availableMods, idx)
        end
    end

    if arch == "SniperRifle" or arch == "DMR" then mods.red_dot = nil; mods.extended_sight = true end
    if arch == "Shotgun" or arch == "AutoShotgun" or arch == "DoubleBarrel" or arch == "SawedOff" or arch == "Minigun" then mods.foregrip = nil end
    if arch == "Pistol" or arch == "MachinePistol" or arch == "Revolver" or arch == "HandCannon" or arch == "VectorSMG" or arch == "SawedOff" then mods.foregrip = nil end
    if arch == "Minigun" or arch == "RocketLauncher" or arch == "DoubleBarrel" or arch == "SawedOff" then mods.bayonet = nil; mods.silencer = nil; mods.extended_clip = nil; mods.drum_mag = nil end
    if mods.drum_mag then mods.extended_clip = nil end

    local data = generateGun(arch, rarity, element, mods)

    Weapon = {
        image = data.img, anchors = data.anchors, w = data.w, h = data.h,
        arch = arch, element = element, rarity = rarity, rData = rData, skin = data.skinName,
        name = string.format("%s %s %s", rarity, (element == "none" and "" or element), arch),
        mods = mods
    }
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.mouse.setVisible(false)
    rollNewWeapon()
end

function love.keypressed(key)
    if key == "space" then rollNewWeapon() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.update(dt)
    updateCombatPhysics(dt)
    if love.mouse.isDown(1) then triggerFire(Weapon) end
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.push()
    if CombatState.shake > 0 then
        love.graphics.translate(love.math.random(-CombatState.shake, CombatState.shake), love.math.random(-CombatState.shake, CombatState.shake))
    end

    love.graphics.clear(PALETTES.ui.bg)
    love.graphics.setColor(0.08, 0.1, 0.12, 0.4)
    local gridScroll = (time * 15) % 40
    for x = 0, 800, 40 do love.graphics.line(x - gridScroll, 0, x - gridScroll, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y, 800, y) end
    
    if CombatState.flashLight > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local c = PALETTES.spells[Weapon.element].base
        love.graphics.setColor(c[1], c[2], c[3], CombatState.flashLight * 0.04)
        love.graphics.rectangle("fill", 0, 0, 800, 600)
        love.graphics.setBlendMode("alpha")
    end

    local pedX, pedY = 400, 380
    love.graphics.setColor(0.06, 0.08, 0.1)
    love.graphics.polygon("fill", pedX-100, pedY+30, pedX+100, pedY+30, pedX+140, pedY, pedX-140, pedY)
    love.graphics.setColor(0.04, 0.05, 0.07)
    love.graphics.polygon("fill", pedX-100, pedY+30, pedX+100, pedY+30, pedX+100, pedY+45, pedX-100, pedY+45)
    
    love.graphics.setColor(0.06, 0.07, 0.09)
    love.graphics.rectangle("fill", 0, 440, 800, 200)
    if CombatState.flashLight > 0 then
        love.graphics.setBlendMode("add", "alphamultiply")
        local c = PALETTES.spells[Weapon.element].base
        love.graphics.setColor(c[1], c[2], c[3], CombatState.flashLight * 0.08)
        love.graphics.polygon("fill", 0, 440, 800, 440, 600, 600, 200, 600)
        love.graphics.setBlendMode("alpha")
    end

    local idleY = math.sin(time * 3) * 6
    local idleRot = math.sin(time * 2) * 0.02
    local finalX = 400 + CombatState.recoilX
    local finalY = 300 + idleY
    local finalRot = CombatState.recoilRot + idleRot

    love.graphics.setColor(0.02, 0.03, 0.04, 0.6)
    love.graphics.ellipse("fill", finalX, 420, Weapon.w * 1.5, 12)

    for _, c in ipairs(Casings) do
        love.graphics.push()
        love.graphics.translate(c.x, c.y)
        love.graphics.rotate(c.rot)
        love.graphics.setColor(PALETTES.brass.base)
        love.graphics.rectangle("fill", -c.size*1.5, -c.size, c.size*3, c.size*2)
        love.graphics.setColor(PALETTES.brass.highlight)
        love.graphics.rectangle("fill", -c.size*1.5, -c.size, c.size*3, 1)
        love.graphics.pop()
    end

    if Weapon.anchors.laser then
        local dx = (Weapon.anchors.laser.x - Weapon.w/2) * renderScale
        local dy = (Weapon.anchors.laser.y - Weapon.h/2) * renderScale
        local lX = finalX + (dx * math.cos(finalRot) - dy * math.sin(finalRot))
        local lY = finalY + (dx * math.sin(finalRot) + dy * math.cos(finalRot))
        
        love.graphics.setBlendMode("add", "alphamultiply")
        local flicker = love.math.random(8, 10) / 10
        -- V12 POLISH: Laser is softer and fades out.
        love.graphics.setColor(1, 0, 0, 0.1 * flicker)
        love.graphics.setLineWidth(4)
        love.graphics.line(lX, lY, lX + math.cos(finalRot)*600, lY + math.sin(finalRot)*600)
        love.graphics.setColor(1, 0, 0, 0.3 * flicker)
        love.graphics.setLineWidth(2)
        love.graphics.line(lX, lY, lX + math.cos(finalRot)*600, lY + math.sin(finalRot)*600)
        love.graphics.setBlendMode("alpha")
        love.graphics.setLineWidth(1)
    end

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(Weapon.image, finalX, finalY, finalRot, renderScale, renderScale, Weapon.w/2, Weapon.h/2)

    love.graphics.setBlendMode("add", "alphamultiply")
    for _, f in ipairs(Flashes) do
        local alpha = f.life * 15
        love.graphics.setColor(f.color[1], f.color[2], f.color[3], alpha)
        local numSpikes = love.math.random(3, 5)
        for j=1, numSpikes do
            local ang = f.rot + (math.pi/numSpikes) * j - (math.pi/2) + love.math.random(-0.3, 0.3)
            local rad = f.size * love.math.random(0.7, 1.3)
            love.graphics.polygon("fill", f.x, f.y, 
                f.x + math.cos(ang - 0.2)*rad*0.3, f.y + math.sin(ang - 0.2)*rad*0.3, 
                f.x + math.cos(ang)*rad, f.y + math.sin(ang)*rad, 
                f.x + math.cos(ang + 0.2)*rad*0.3, f.y + math.sin(ang + 0.2)*rad*0.3)
        end
        love.graphics.circle("fill", f.x, f.y, f.size * 0.3)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", f.x, f.y, f.size * 0.15)
    end

    love.graphics.setBlendMode("alpha")
    for _, p in ipairs(Projectiles) do
        if p.style ~= "void" then love.graphics.setBlendMode("add", "alphamultiply") end
        
        love.graphics.setColor(p.color)
        if p.style == "plasma" or p.style == "void" or p.style == "ice" then 
            love.graphics.circle("fill", p.x, p.y, p.style == "void" and 8 or 6)
        else 
            love.graphics.rectangle("fill", p.x, p.y-2, 16, 4) 
        end
        
        if #p.history > 1 then
            love.graphics.setLineWidth(p.style == "plasma" and 10 or 4)
            for i=1, #p.history-1 do
                local alpha = 1 - (i / #p.history)
                love.graphics.setColor(p.baseColor[1], p.baseColor[2], p.baseColor[3], alpha)
                love.graphics.line(p.history[i].x, p.history[i].y, p.history[i+1].x, p.history[i+1].y)
            end
        end
        love.graphics.setBlendMode("alpha")
    end
    love.graphics.setLineWidth(1)
    
    for _, p in ipairs(Particles) do
        local alpha = p.life / p.maxLife
        
        if p.style == "smoke" then
            -- V12 POLISH: Smoke is a soft, rotating, composite puff, drastically lower opacity.
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.wobble)
            local s = p.size
            love.graphics.rectangle("fill", -s, -s/2, s*2, s)
            love.graphics.rectangle("fill", -s/2, -s, s, s*2)
            love.graphics.rectangle("fill", -s*0.7, -s*0.7, s*1.4, s*1.4)
            love.graphics.pop()
        elseif p.style == "void" then 
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.circle("fill", p.x, p.y, p.size)
        else 
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            love.graphics.rectangle("fill", p.x, p.y, p.size, p.size) 
        end
    end
    love.graphics.pop()

    -- 3. DRAW UI 
    love.graphics.setColor(PALETTES.ui.panel)
    love.graphics.rectangle("fill", 20, 20, 320, 240, 12, 12)
    love.graphics.setColor(Weapon.rData.color)
    love.graphics.rectangle("line", 20, 20, 320, 240, 12, 12)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("[SPACE] Generate Prototype", 40, 40)
    love.graphics.print("[L-CLICK] Fire Weapon", 40, 60)
    
    love.graphics.setColor(Weapon.rData.color)
    love.graphics.print(string.upper(Weapon.name), 40, 90, 0, 1.2, 1.2)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("TIER: ", 40, 115)
    love.graphics.setColor(Weapon.rData.color)
    love.graphics.print(string.upper(Weapon.rarity), 80, 115)
    
    love.graphics.setColor(0.6, 0.6, 0.6)
    love.graphics.print("CHASSIS: ", 180, 115)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print(string.upper(Weapon.skin), 245, 115)

    love.graphics.setColor(PALETTES.ui.text)
    love.graphics.print("ATTACHMENTS:", 40, 145)
    local y = 170
    local hasMods = false
    for mod, _ in pairs(Weapon.mods) do
        love.graphics.setColor(0.4, 0.8, 0.4)
        love.graphics.print(">> " .. string.upper(mod:gsub("_", " ")), 50, y)
        y = y + 20
        hasMods = true
    end
    if not hasMods then 
        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.print("-- FACTORY STANDARD", 50, y) 
    end

    -- Crosshair
    local cx, cy = MouseX, MouseY
    local sp = CombatState.crosshairSpread + 4
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", cx - 1, cy - sp - 6, 2, 6)
    love.graphics.rectangle("fill", cx - 1, cy + sp, 2, 6)    
    love.graphics.rectangle("fill", cx - sp - 6, cy - 1, 6, 2)
    love.graphics.rectangle("fill", cx + sp, cy - 1, 6, 2)    
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.rectangle("fill", cx - 1, cy - 1, 2, 2)     
end