-- Procedural gun canvas generator (shared by weapons/ and character demos)

local M = {}

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
        -- Pivot for holding: center of vertical grip strip (matches character arm stub ~y34 in 32×48 frame)
        local gripCx = gripX + 3
        local gripCy = ry + arch.rec_thick + math.floor(arch.grip / 2)

        return { muzzle = {x=muzzleX, y=muzzleY}, core = {x=coreX, y=coreY}, laser = laserAnchor, grip = {x=gripCx, y=gripCy} }
    end)
    
    canvasData.skinName = finalSkinName
    return canvasData
end

M.PALETTES = PALETTES
M.RARITIES = RARITIES
M.WEAPON_ARCHETYPES = WEAPON_ARCHETYPES
M.generateGun = generateGun

-- Same rules as the legacy branch of weapons/main.lua rollNewWeapon()
function M.rollRandomProceduralWeapon()
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

    return {
        image = data.img, anchors = data.anchors, w = data.w, h = data.h,
        arch = arch, element = element, rarity = rarity, rData = rData, skin = data.skinName,
        name = string.format("%s %s %s", rarity, (element == "none" and "" or element), arch),
        mods = mods
    }
end

return M
