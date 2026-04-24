-- =============================================================================
-- CONFIGURATION & CONSTANTS
-- =============================================================================
local WINDOW_WIDTH = 1000
local WINDOW_HEIGHT = 700
local PIXEL_SCALE = 4 

-- VIRTUAL RESOLUTION
local VIRTUAL_WIDTH = WINDOW_WIDTH / PIXEL_SCALE
local VIRTUAL_HEIGHT = WINDOW_HEIGHT / PIXEL_SCALE

-- PHYSICS CONSTANTS
local GRAVITY = 800 
local WALK_SPEED = 60
local RUN_SPEED = 100
local JUMP_FORCE = -250
local ACCELERATION = 800
local FRICTION = 600
local FLOOR_Y = 130
-- Mouse vs character center: avoid flip jitter (screen px)
local FACING_DEADZONE_PX = 6

-- =============================================================================
-- ASSET REPOSITORY
-- =============================================================================
local characterAssets = {
    -- Base Character
    skins = {}, skinColors = {},
    hairs = {}, longhairs = {}, tops = {}, bottoms = {}, dresses = {}, shoes = {}, hats = {},
    -- New Armor Assets
    armor_chests = {}, armor_legs = {}, armor_boots = {}
}

-- ANIMATION DATA
local characterAnimations = {
    idle = {row = 0, frames = 4, speed = 0.2},
    walk = {row = 1, frames = 6, speed = 0.175},
    run  = {row = 2, frames = 6, speed = 0.17},
    jump = {row = 3, frames = 2, speed = 0.1}
}

-- PROCEDURAL WEAPON + combat (../weapons/weapon_gen.lua, ../weapons/shooting.lua)
local WeaponGen
local Shooting
local heldWeapon

-- ~24 virtual px drawn width for a 32px-wide character frame; wide canvases scale down
local function handHeldGunScale(w, h)
    w = tonumber(w) or 96
    h = tonumber(h) or 48
    local span = math.max(w, h * 0.9)
    local s = 24 / span
    return math.max(0.22, math.min(0.46, s)) * 1.03
end

-- Forward declaration so releaseHeldWeapon can clear gun-smooth fields on the real player table.
local player

local function releaseHeldWeapon()
    if heldWeapon and heldWeapon.image then
        pcall(function() heldWeapon.image:release() end)
    end
    heldWeapon = nil
    player.smoothAim = nil
    player.smoothGH = nil
    player.gunFrame = nil
    if Shooting and Shooting.resetSession then Shooting.resetSession() end
end

local function lerpAngle(a, b, t)
    local d = (b - a + math.pi) % (math.pi * 2) - math.pi
    return a + d * t
end

local function rollHeldWeapon()
    if not WeaponGen then return end
    releaseHeldWeapon()
    heldWeapon = WeaponGen.rollRandomProceduralWeapon()
end

-- Hand motion matches procedural sprite sheet (row = anim row, col = frame column 0–3).
-- Walk: small leg sway. Run: wider legs, no vertical bounce (face/hair stay level).
local function animHandMotion(animRow, frameCol)
    local legOffset = 0
    if animRow == 1 then
        legOffset = (frameCol % 2 == 0) and 1 or -1
    elseif animRow == 2 then
        legOffset = (frameCol % 2 == 0) and 2 or -2
    end
    local bounce = 0
    local jLift = (animRow == 3) and -2 or 0
    return legOffset, bounce, jLift
end

-- Frame coords (32×48, origin bottom-center 16,48).
-- Gun hand always uses high lx, off-hand low lx: horizontal flip (facing -1) maps high lx → screen-left (muzzle side when aiming left).
local HAND_BASE_Y = 38

local function forwardHandFrame(legOffset, bounce, jLift)
    local ly = HAND_BASE_Y + bounce + jLift
    return 24 - legOffset, ly
end

local function offHandFrame(legOffset, bounce, jLift)
    local ly = HAND_BASE_Y + bounce + jLift
    return 8 + legOffset, ly
end

local function frameToWorld(lx, ly, drawX, drawY, facing)
    return drawX + (lx - 16) * facing, drawY + (ly - 48)
end

-- Aim / muzzle for update + draw. Must sit after animHandMotion / forwardHandFrame / frameToWorld (Lua local scope).
local function computeHeldGunState(dt, heldWeapon)
    if not heldWeapon or not heldWeapon.image then return nil end
    local animData = characterAnimations[player.state] or characterAnimations.idle
    local frameIndex = math.max(1, math.min(player.currentFrame or 1, animData.frames))
    local frameCol = (frameIndex - 1) % 4
    local lo, bou, jl = animHandMotion(animData.row, frameCol)
    local fhx, fhy = forwardHandFrame(lo, bou, jl)
    local drawX = math.floor(player.x) + player.width / 2
    local drawY = math.floor(player.y) + player.height
    local sx = player.facing
    local ghX, ghY = frameToWorld(fhx, fhy, drawX, drawY, sx)
    local mx, my = love.mouse.getX() / PIXEL_SCALE, love.mouse.getY() / PIXEL_SCALE
    local dx, dy = mx - ghX, my - ghY
    local ang = math.atan2(dy, dx)
    local gGsc = handHeldGunScale(heldWeapon.w, heldWeapon.h)
    local gGsx, gGsy = gGsc, gGsc
    local gAim
    if ang > math.pi / 2 then
        gAim = ang - math.pi
        gGsx = -gGsx
    elseif ang < -math.pi / 2 then
        gAim = ang + math.pi
        gGsx = -gGsx
    else
        gAim = ang
    end
    if dt and dt > 0 then
        player.smoothAim = lerpAngle(player.smoothAim or gAim, gAim, math.min(1, dt * 22))
    end
    local aimDraw = player.smoothAim or gAim
    local a = heldWeapon.anchors
    local gPivotX = (a and a.grip and a.grip.x) or (heldWeapon.w * 0.38)
    local gPivotY = (a and a.grip and a.grip.y) or (heldWeapon.h * 0.52)
    local mux = (a and a.muzzle and a.muzzle.x) or (heldWeapon.w * 0.92)
    local muy = (a and a.muzzle and a.muzzle.y) or (heldWeapon.h * 0.5)
    local vx, vy = mux - gPivotX, muy - gPivotY
    local gVl = math.sqrt(vx * vx + vy * vy)
    if gVl < 1 then gVl = 1 end
    vx, vy = vx / gVl, vy / gVl
    if gGsx < 0 then vx = -vx end
    local gBwx = vx * math.cos(aimDraw) - vy * math.sin(aimDraw)
    local gBwy = vx * math.sin(aimDraw) + vy * math.cos(aimDraw)
    local gBarrelWorld = gVl * gGsc
    local muzzleX = ghX + gBwx * gBarrelWorld
    local muzzleY = ghY + gBwy * gBarrelWorld
    local aimAngleWorld = math.atan2(my - muzzleY, mx - muzzleX)
    local ww = tonumber(heldWeapon.w) or 96
    local gGunCompact = (ww <= 76) or (gBarrelWorld < 19)
    return {
        ghX = ghX, ghY = ghY,
        gAim = gAim, aimDraw = aimDraw,
        gGsx = gGsx, gGsy = gGsy, gGsc = gGsc,
        gPivotX = gPivotX, gPivotY = gPivotY,
        gBwx = gBwx, gBwy = gBwy,
        gBarrelWorld = gBarrelWorld,
        gGunCompact = gGunCompact,
        muzzleX = muzzleX, muzzleY = muzzleY,
        aimAngleWorld = aimAngleWorld,
        fhx = fhx, fhy = fhy, drawX = drawX, drawY = drawY, sx = sx,
    }
end

local function drawFloatingHandSquare(drawX, drawY, facing, lx, ly, skinRgb)
    local wx, wy = frameToWorld(lx, ly, drawX, drawY, facing)
    love.graphics.setColor(skinRgb[1], skinRgb[2], skinRgb[3])
    love.graphics.rectangle("fill", wx - 1, wy - 1, 3, 3)
    love.graphics.setColor(
        math.min(skinRgb[1] * 1.1, 1),
        math.min(skinRgb[2] * 1.06, 1),
        math.min(skinRgb[3] * 1.04, 1)
    )
    love.graphics.rectangle("fill", wx - 1, wy - 1, 2, 1)
end

local function drawFloatingHandWorld(wx, wy, skinRgb)
    love.graphics.setColor(skinRgb[1], skinRgb[2], skinRgb[3])
    love.graphics.rectangle("fill", wx - 1, wy - 1, 3, 3)
    love.graphics.setColor(
        math.min(skinRgb[1] * 1.1, 1),
        math.min(skinRgb[2] * 1.06, 1),
        math.min(skinRgb[3] * 1.04, 1)
    )
    love.graphics.rectangle("fill", wx - 1, wy - 1, 2, 1)
end

-- PLAYER ENTITY
player = {
    x = 50, y = 50,
    width = 16, height = 24, 
    vx = 0, vy = 0,
    facing = 1,
    state = "idle",
    timer = 0,
    currentFrame = 1,
    grounded = false,
    
    -- Appearance Indices
    indices = { skin = 1, hair = 1, top = 1, bottom = 1, shoes = 1, hat = 2 }, -- hat 2 is empty/none
    
    -- Armor Indices (0 means nothing equipped)
    armor = { chest = 0, legs = 0, boots = 0 },
    
    -- Final visual stack for drawing
    equipment = {}
}

--------------------------------------------------------------------------------
-- Shared loot-shooter pixel art language (matches shield / weapons / items / consumables)
--------------------------------------------------------------------------------
local PALETTES = {
    metal = { base={0.45, 0.45, 0.5}, dark={0.15, 0.15, 0.18}, highlight={0.7, 0.75, 0.8} },
    gold  = { base={0.9, 0.7, 0.1}, dark={0.5, 0.3, 0.05}, highlight={1.0, 0.9, 0.5} },
    mats = {
        leather = { base={0.4, 0.25, 0.15}, dark={0.2, 0.1, 0.05}, highlight={0.55, 0.35, 0.22}, name="Leather" },
        comp    = { base={0.18, 0.18, 0.2}, dark={0.05, 0.05, 0.08}, highlight={0.3, 0.3, 0.35}, name="Polymer" },
        tan     = { base={0.65, 0.55, 0.4}, dark={0.4, 0.35, 0.25}, highlight={0.8, 0.7, 0.5}, name="Military Tan" },
        pang    = { base={0.35, 0.45, 0.3}, dark={0.15, 0.25, 0.15}, highlight={0.5, 0.6, 0.45}, name="Hardened" },
        scrap   = { base={0.6, 0.3, 0.15}, dark={0.3, 0.1, 0.05}, highlight={0.8, 0.4, 0.2}, name="Rusted" },
        cyber   = { base={0.9, 0.9, 0.95}, dark={0.5, 0.5, 0.6}, highlight={1.0, 1.0, 1.0}, name="Ceramic" },
        hyper   = { base={0.8, 0.2, 0.2}, dark={0.4, 0.1, 0.1}, highlight={0.9, 0.4, 0.4}, name="Aggressive" },
    },
    spells = {
        plasma = { base={0.2, 0.9, 1.0}, highlight={0.8, 1.0, 1.0} },
        fire   = { base={1.0, 0.4, 0.1}, highlight={1.0, 0.9, 0.2} },
        shock  = { base={0.8, 0.9, 0.1}, highlight={1.0, 1.0, 0.8} },
        ice    = { base={0.6, 1.0, 1.0}, highlight={1.0, 1.0, 1.0} },
        void   = { base={0.15, 0.05, 0.25}, highlight={0.3, 0.1, 0.5} },
        none   = { base={1.0, 0.9, 0.6}, highlight={1.0, 1.0, 1.0} },
    },
    ui = { bg={0.04, 0.05, 0.07} },
}

local RARITIES = {
    Scrap     = { color = {0.5, 0.3, 0.2} },
    Common    = { color = {0.6, 0.6, 0.6} },
    Uncommon  = { color = {0.3, 0.8, 0.4} },
    Rare      = { color = {0.2, 0.6, 1.0} },
    Epic      = { color = {0.8, 0.3, 1.0} },
    Legendary = { color = {1.0, 0.8, 0.2} },
    Mythic    = { color = {0.1, 1.0, 0.8} },
    P2W       = { color = {1.0, 0.1, 0.6} },
}

-- Armor tiers: panel material + frame metal + rarity trim (+ optional elemental inlay like weapons/shields)
local ArmorSets = {
    { name="Leather",  mat=PALETTES.mats.leather, metal=PALETTES.mats.scrap,   rarity="Scrap",     accent=nil },
    { name="Iron",     mat=PALETTES.metal,        metal=PALETTES.metal,        rarity="Common",    accent=nil },
    { name="Steel",    mat=PALETTES.mats.comp,    metal=PALETTES.metal,        rarity="Uncommon",  accent=nil },
    { name="Gold",     mat=PALETTES.gold,         metal=PALETTES.gold,         rarity="Epic",      accent=nil },
    { name="Diamond",  mat=PALETTES.mats.cyber,  metal=PALETTES.metal,        rarity="Legendary", accent="ice" },
    { name="Obsidian", mat=PALETTES.mats.comp,    metal=PALETTES.mats.comp,    rarity="Rare",     accent="void" },
    { name="Ruby",     mat=PALETTES.mats.hyper,   metal=PALETTES.metal,        rarity="Rare",     accent="fire" },
    { name="Cyber",    mat=PALETTES.mats.cyber,   metal=PALETTES.mats.comp,    rarity="Mythic",   accent="plasma" },
}

-- Matches consumables / shield tech panels: rim + fill + top & left bevel
local function drawComponent(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x - 1, y - 1, w + 2, h + 2)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1)
        if h > 2 then
            love.graphics.rectangle("fill", x, y + 1, 1, h - 1)
        end
    end
end

-- No rim row above the part (avoids a full-width dark band on the face row above).
local function drawComponentFlatTop(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x - 1, y, 1, h + 1)
    love.graphics.rectangle("fill", x + w, y, 1, h + 1)
    love.graphics.rectangle("fill", x - 1, y + h, w + 2, 1)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1)
        if h > 2 then
            love.graphics.rectangle("fill", x, y + 1, 1, h - 1)
        end
    end
end

-- No rim row below the part (thins the “chin beard” from the default outer rect).
local function drawComponentFlatBottom(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x - 1, y - 1, w + 2, 1)
    love.graphics.rectangle("fill", x - 1, y, 1, h)
    love.graphics.rectangle("fill", x + w, y, 1, h)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1)
        if h > 2 then
            love.graphics.rectangle("fill", x, y + 1, 1, h - 1)
        end
    end
end

local function drawRivet(x, y, cDark)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x, y, 2, 2)
    love.graphics.setColor(PALETTES.metal.highlight)
    love.graphics.rectangle("fill", x, y, 1, 1)
end

local function drawVentStrip(x, y, w, h, cLine)
    love.graphics.setColor(cLine)
    for yy = y, y + h - 1, 2 do
        love.graphics.rectangle("fill", x, yy, w, 1)
    end
end

-- =============================================================================
-- PROCEDURAL TEXTURE GENERATION
-- =============================================================================
function createProceduralTexture(texType, colorData)
    local isArmorPiece = (texType == "armor_chest" or texType == "armor_legs" or texType == "armor_boots")
    local mainColor, detailColor
    local cMat, cMetal, rData, spell
    if isArmorPiece and colorData.mat and colorData.metal then
        cMat = colorData.mat
        cMetal = colorData.metal
        rData = RARITIES[colorData.rarity] or RARITIES.Common
        spell = colorData.accent and PALETTES.spells[colorData.accent]
        -- Armor sets are not RGB triples; base layers below set their own colors in drawComponent.
        mainColor = {1, 1, 1}
        detailColor = {1, 1, 1}
    else
        mainColor = colorData.color or colorData
        detailColor = colorData.detail or { mainColor[1] * 0.8, mainColor[2] * 0.8, mainColor[3] * 0.8 }
    end

    local width, height = 128, 192 
    local frameW, frameH = 32, 48 
    local canvas = love.graphics.newCanvas(width, height)
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0,0,0,0) 
    
    for row=0, 3 do 
        for col=0, 3 do
            local bx = col * frameW
            local by = (row * frameH) + 16 
            
            -- Walk: smaller leg sway. Run: wider legs. No vertical bob on head/hair/hat (any row).
            local legOffset = 0
            if row == 1 then
                legOffset = (col % 2 == 0) and 1 or -1
            elseif row == 2 then
                legOffset = (col % 2 == 0) and 2 or -2
            end

            love.graphics.setColor(mainColor)

            -- === BASE CHARACTER (drawComponent bevel — matches armor panel language) ===
            if texType == "skin" then
                local sk, dk = mainColor, detailColor
                local hi = {
                    math.min(sk[1] * 1.06, 1), math.min(sk[2] * 1.05, 1), math.min(sk[3] * 1.04, 1)
                }
                drawComponent(bx + 10 + legOffset, by + 26, 4, 6, sk, dk, hi)
                drawComponent(bx + 18 - legOffset, by + 26, 4, 6, sk, dk, hi)
                drawComponentFlatTop(bx + 11, by + 14, 10, 12, sk, dk, hi)
                drawComponentFlatTop(bx + 12, by + 13, 8, 2, sk, dk, hi)
                drawComponentFlatBottom(bx + 11, by + 4, 10, 10, sk, dk, hi)
                love.graphics.setColor(0.12, 0.09, 0.09)
                love.graphics.rectangle("fill", bx + 13, by + 8, 2, 2)
                love.graphics.rectangle("fill", bx + 17, by + 8, 2, 2)

            elseif texType == "top" then
                local hi = {
                    math.min(mainColor[1] * 1.07, 1), math.min(mainColor[2] * 1.05, 1), math.min(mainColor[3] * 1.04, 1)
                }
                drawComponent(bx + 10, by + 15, 12, 10, mainColor, detailColor, hi)
                drawComponent(bx + 8, by + 15, 2, 4, mainColor, detailColor, hi)
                drawComponent(bx + 22, by + 15, 2, 4, mainColor, detailColor, hi)
                love.graphics.setColor(hi[1], hi[2], hi[3])
                love.graphics.rectangle("fill", bx + 12, by + 16, 8, 1)
                love.graphics.setColor(detailColor[1], detailColor[2], detailColor[3])
                love.graphics.rectangle("fill", bx + 10, by + 23, 12, 1)

            elseif texType == "bottom" then
                local hi = {
                    math.min(mainColor[1] * 1.05, 1), math.min(mainColor[2] * 1.04, 1), math.min(mainColor[3] * 1.03, 1)
                }
                drawComponent(bx + 9, by + 23, 14, 4, mainColor, detailColor, hi)
                drawComponent(bx + 9 + legOffset, by + 26, 6, 5, mainColor, detailColor, hi)
                drawComponent(bx + 17 - legOffset, by + 26, 6, 5, mainColor, detailColor, hi)
                love.graphics.setColor(detailColor[1], detailColor[2], detailColor[3])
                love.graphics.rectangle("fill", bx + 10, by + 24, 12, 1)

            elseif texType == "shoes" then
                local sole = {
                    mainColor[1] * 0.4, mainColor[2] * 0.35, mainColor[3] * 0.32
                }
                local hi = {
                    math.min(mainColor[1] * 1.04, 1), math.min(mainColor[2] * 1.03, 1), math.min(mainColor[3] * 1.02, 1)
                }
                drawComponent(bx + 9 + legOffset, by + 30, 6, 2, mainColor, sole, hi)
                drawComponent(bx + 17 - legOffset, by + 30, 6, 2, mainColor, sole, hi)

            elseif texType == "hair" then
                local hi = {
                    math.min(mainColor[1] * 1.06, 1), math.min(mainColor[2] * 1.05, 1), math.min(mainColor[3] * 1.04, 1)
                }
                drawComponent(bx + 9, by + 2, 14, 4, mainColor, detailColor, hi)
                drawComponent(bx + 8, by + 4, 3, 5, mainColor, detailColor, hi)
                drawComponent(bx + 21, by + 4, 3, 5, mainColor, detailColor, hi)
                drawComponent(bx + 10, by + 3, 12, 2, mainColor, detailColor, hi)

            elseif texType == "hat" then
                if type(colorData) == "table" and colorData[4] == 0 then
                    -- Invisible hat: skip pixels
                else
                    local hi = {
                        math.min(mainColor[1] * 1.06, 1), math.min(mainColor[2] * 1.05, 1), math.min(mainColor[3] * 1.04, 1)
                    }
                    drawComponent(bx + 8, by + 1, 16, 4, mainColor, detailColor, hi)
                    drawComponent(bx + 10, by - 3, 12, 6, mainColor, detailColor, hi)
                end

            -- === NEW ARMOR PARTS ===
            
            elseif texType == "armor_chest" then
                -- Modular plates: shield / item style chassis + rarity rails + optional elemental core
                drawComponent(bx + 9, by + 14, 14, 12, cMat.base, cMetal.dark, cMat.highlight)
                drawComponent(bx + 7, by + 14, 3, 4, cMetal.base, cMetal.dark, cMetal.highlight)
                drawComponent(bx + 22, by + 14, 3, 4, cMetal.base, cMetal.dark, cMetal.highlight)
                drawComponent(bx + 13, by + 16, 6, 6, cMetal.base, cMetal.dark, cMetal.highlight)
                drawVentStrip(bx + 11, by + 15, 1, 10, cMetal.dark)
                drawVentStrip(bx + 20, by + 15, 1, 10, cMetal.dark)
                love.graphics.setColor(rData.color)
                love.graphics.rectangle("fill", bx + 9, by + 14, 2, 12)
                love.graphics.rectangle("fill", bx + 21, by + 14, 2, 12)
                drawRivet(bx + 11, by + 16, cMetal.dark)
                drawRivet(bx + 19, by + 16, cMetal.dark)
                drawRivet(bx + 11, by + 22, cMetal.dark)
                drawRivet(bx + 19, by + 22, cMetal.dark)
                if spell then
                    love.graphics.setColor(spell.base)
                    love.graphics.rectangle("fill", bx + 14, by + 18, 4, 4)
                    love.graphics.setColor(spell.highlight)
                    love.graphics.rectangle("fill", bx + 15, by + 19, 2, 1)
                    love.graphics.rectangle("fill", bx + 14, by + 20, 4, 1)
                end

            elseif texType == "armor_boots" then
                drawComponent(bx + 8 + legOffset, by + 28, 7, 4, cMat.base, cMetal.dark, cMat.highlight)
                drawComponent(bx + 17 - legOffset, by + 28, 7, 4, cMat.base, cMetal.dark, cMat.highlight)
                love.graphics.setColor(cMetal.dark)
                love.graphics.rectangle("fill", bx + 9 + legOffset, by + 31, 5, 1)
                love.graphics.rectangle("fill", bx + 18 - legOffset, by + 31, 5, 1)
                love.graphics.setColor(rData.color)
                love.graphics.rectangle("fill", bx + 8 + legOffset, by + 28, 1, 4)
                love.graphics.rectangle("fill", bx + 23 - legOffset, by + 28, 1, 4)
                drawRivet(bx + 10 + legOffset, by + 29, cMetal.dark)
                drawRivet(bx + 20 - legOffset, by + 29, cMetal.dark)

            elseif texType == "armor_legs" then
                drawComponent(bx + 9, by + 23, 14, 4, cMat.base, cMetal.dark, cMat.highlight)
                drawComponent(bx + 8 + legOffset, by + 26, 7, 4, cMat.base, cMetal.dark, cMat.highlight)
                drawComponent(bx + 17 - legOffset, by + 26, 7, 4, cMat.base, cMetal.dark, cMat.highlight)
                drawComponent(bx + 10 + legOffset, by + 28, 3, 2, cMetal.base, cMetal.dark, cMetal.highlight)
                drawComponent(bx + 19 - legOffset, by + 28, 3, 2, cMetal.base, cMetal.dark, cMetal.highlight)
                love.graphics.setColor(rData.color)
                love.graphics.rectangle("fill", bx + 10, by + 23, 2, 2)
                if spell then
                    love.graphics.setColor(spell.base)
                    love.graphics.rectangle("fill", bx + 15, by + 24, 2, 2)
                end

            end
        end
    end
    love.graphics.setCanvas()
    return canvas
end

function refreshPlayerAppearance()
    player.equipment = {}
    
    -- 1. BASE BODY
    table.insert(player.equipment, characterAssets.skins[player.indices.skin])
    
    -- 2. CLOTHING (Under Armor)
    table.insert(player.equipment, characterAssets.bottoms[player.indices.bottom])
    table.insert(player.equipment, characterAssets.tops[player.indices.top])
    table.insert(player.equipment, characterAssets.shoes[player.indices.shoes])
    
    -- 3. ARMOR LAYERS (Over Clothing)
    if player.armor.boots > 0 then table.insert(player.equipment, characterAssets.armor_boots[player.armor.boots]) end
    if player.armor.legs > 0 then table.insert(player.equipment, characterAssets.armor_legs[player.armor.legs]) end
    if player.armor.chest > 0 then table.insert(player.equipment, characterAssets.armor_chests[player.armor.chest]) end

    -- 4. Hair / hat (hands drawn at runtime — floating squares)
    table.insert(player.equipment, characterAssets.hairs[player.indices.hair])
    table.insert(player.equipment, characterAssets.hats[player.indices.hat])
end

-- =============================================================================
-- MAIN FUNCTIONS
-- =============================================================================
function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Armor Module - MTE pixel style")

    local sep = package.config:sub(1, 1)
    local base = (love.filesystem.getSource() or "."):gsub("[/\\]+$", "")
    package.path = base .. sep .. ".." .. sep .. "weapons" .. sep .. "?.lua;" .. package.path
    WeaponGen = require("weapon_gen")
    Shooting = require("shooting")
    Shooting.init()
    Shooting.setDrawScale(PIXEL_SCALE)
    Shooting.setBounds(VIRTUAL_WIDTH, FLOOR_Y)
    rollHeldWeapon()

    -- 1. GENERATE BASE ASSETS
    characterAssets.skinColors = {{0.95, 0.85, 0.75}, {0.7, 0.5, 0.4}, {0.4, 0.3, 0.25}} 
    for _, c in ipairs(characterAssets.skinColors) do table.insert(characterAssets.skins, createProceduralTexture("skin", c)) end

    -- Clothes
    table.insert(characterAssets.tops, createProceduralTexture("top", {0.2, 0.6, 0.8}))
    table.insert(characterAssets.tops, createProceduralTexture("top", {0.8, 0.2, 0.2}))
    table.insert(characterAssets.tops, createProceduralTexture("top", {0.95, 0.95, 0.95}))
    
    table.insert(characterAssets.bottoms, createProceduralTexture("bottom", {0.3, 0.3, 0.4}))
    table.insert(characterAssets.bottoms, createProceduralTexture("bottom", {0.7, 0.6, 0.4}))
    table.insert(characterAssets.bottoms, createProceduralTexture("bottom", {0.2, 0.3, 0.5}))
    
    table.insert(characterAssets.shoes, createProceduralTexture("shoes", {0.1, 0.1, 0.1}))
    table.insert(characterAssets.shoes, createProceduralTexture("shoes", {0.5, 0.3, 0.2}))

    -- Hair
    table.insert(characterAssets.hairs, createProceduralTexture("hair", {0.2, 0.1, 0.0})) 
    table.insert(characterAssets.hairs, createProceduralTexture("hair", {0.9, 0.8, 0.2}))
    
    -- Hats
    table.insert(characterAssets.hats, createProceduralTexture("hat", {0.8, 0.2, 0.2})) 
    table.insert(characterAssets.hats, createProceduralTexture("hat", {0, 0, 0, 0})) -- Invisible hat

    -- 2. GENERATE ARMOR ASSETS (24 pieces: 8 sets * 3 pieces, no helms)
    for _, set in ipairs(ArmorSets) do
        table.insert(characterAssets.armor_chests, createProceduralTexture("armor_chest", set))
        table.insert(characterAssets.armor_legs, createProceduralTexture("armor_legs", set))
        table.insert(characterAssets.armor_boots, createProceduralTexture("armor_boots", set))
    end

    refreshPlayerAppearance()
end

function love.keypressed(key)
    -- Appearance Controls
    if key == "1" then player.indices.skin = (player.indices.skin % #characterAssets.skins) + 1
    elseif key == "2" then player.indices.hair = (player.indices.hair % #characterAssets.hairs) + 1
    elseif key == "3" then player.indices.top = (player.indices.top % #characterAssets.tops) + 1
    elseif key == "4" then player.indices.bottom = (player.indices.bottom % #characterAssets.bottoms) + 1
    
    -- ARMOR CONTROLS
    elseif key == "q" then
        -- Equip Random Full Set
        local setIndex = love.math.random(#ArmorSets)
        player.armor.chest = setIndex
        player.armor.legs = setIndex
        player.armor.boots = setIndex
        
    elseif key == "e" then
        -- Mix and Match Random
        player.armor.chest = love.math.random(0, #ArmorSets)
        player.armor.legs = love.math.random(0, #ArmorSets)
        player.armor.boots = love.math.random(0, #ArmorSets)
        
    elseif key == "r" then
        -- Remove Armor
        player.armor = {chest=0, legs=0, boots=0}
    elseif key == "g" then
        rollHeldWeapon()
    end
    
    refreshPlayerAppearance()
end

function love.quit()
    releaseHeldWeapon()
end

function love.update(dt)
    -- Mouse / Facing
    local mx = love.mouse.getX()
    local cx = (player.x + player.width / 2) * PIXEL_SCALE
    if mx < cx - FACING_DEADZONE_PX then
        player.facing = -1
    elseif mx > cx + FACING_DEADZONE_PX then
        player.facing = 1
    end

    -- Movement Physics
    local moveDir = 0
    if love.keyboard.isDown("left") or love.keyboard.isDown("a") then moveDir = -1
    elseif love.keyboard.isDown("right") or love.keyboard.isDown("d") then moveDir = 1 end

    local targetSpeed = (love.keyboard.isDown("lshift") and RUN_SPEED or WALK_SPEED)
    
    if moveDir ~= 0 then
        player.vx = player.vx + (moveDir * ACCELERATION * dt)
        if math.abs(player.vx) > targetSpeed then player.vx = (player.vx / math.abs(player.vx)) * targetSpeed end
    else
        if math.abs(player.vx) < FRICTION*dt then player.vx = 0
        else player.vx = player.vx - (player.vx > 0 and 1 or -1) * FRICTION * dt end
    end

    player.vy = player.vy + GRAVITY * dt
    player.x = player.x + player.vx * dt
    player.y = player.y + player.vy * dt

    -- Floor Collision
    if player.y + player.height > FLOOR_Y then
        player.y = FLOOR_Y - player.height
        player.vy = 0
        player.grounded = true
    else
        player.grounded = false
    end

    -- Jump
    if (love.keyboard.isDown("space") or love.keyboard.isDown("up")) and player.grounded then
        player.vy = JUMP_FORCE
        player.grounded = false
    end

    -- Animation State Logic
    local newState = "idle"
    if not player.grounded then newState = "jump"
    elseif math.abs(player.vx) > 5 then newState = (targetSpeed == RUN_SPEED and "run" or "walk") end
    
    if newState ~= player.state then
        player.state = newState
        player.timer = 0
        player.currentFrame = 1
    end
    
    local animData = characterAnimations[player.state]
    player.timer = player.timer + dt
    while player.timer > animData.speed do
        player.timer = player.timer - animData.speed
        player.currentFrame = player.currentFrame + 1
        if player.currentFrame > animData.frames then player.currentFrame = 1 end
    end

    player.gunFrame = nil
    if heldWeapon and heldWeapon.image then
        player.gunFrame = computeHeldGunState(dt, heldWeapon)
        if player.gunFrame and love.mouse.isDown(1) then
            local g = player.gunFrame
            Shooting.triggerFire(heldWeapon, {
                muzzleX = g.muzzleX,
                muzzleY = g.muzzleY,
                aimAngleWorld = g.aimAngleWorld,
                gripX = g.ghX,
                gripY = g.ghY,
                gunAngle = g.aimDraw,
                gunScale = g.gGsc,
            })
        end
    end
    Shooting.update(dt)
end

function love.draw()
    love.graphics.push()
    love.graphics.scale(PIXEL_SCALE, PIXEL_SCALE)
    if Shooting then
        local shk = Shooting.getShake()
        if shk > 0 then
            love.graphics.translate(love.math.random(-shk, shk), love.math.random(-shk, shk))
        end
    end

    -- A. DRAW BACKGROUND / FLOOR
    local tileSize = 32
    local cols = math.ceil(VIRTUAL_WIDTH / tileSize) 
    local sky = PALETTES.ui.bg
    love.graphics.setColor(sky[1], sky[2], sky[3])
    love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    
    for r=0, 2 do 
        for c=0, cols do
            if (r + c) % 2 == 0 then love.graphics.setColor(0.3, 0.3, 0.3)
            else love.graphics.setColor(0.35, 0.35, 0.35) end
            love.graphics.rectangle("fill", c*tileSize, FLOOR_Y+(r*tileSize), tileSize, tileSize)
        end
    end

    if Shooting and heldWeapon and Shooting.getFlashLight() > 0 then
        local spell = Shooting.getElementForFlash(heldWeapon)
        love.graphics.setBlendMode("add", "alphamultiply")
        love.graphics.setColor(spell.base[1], spell.base[2], spell.base[3], Shooting.getFlashLight() * 0.04)
        love.graphics.rectangle("fill", 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
        love.graphics.setBlendMode("alpha")
        Shooting.drawFloorFlash(heldWeapon, FLOOR_Y, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)
    end

    -- B. DRAW PLAYER
    local gunFxDrawn = false
    if player.equipment and #player.equipment > 0 then
        local animData = characterAnimations[player.state] or characterAnimations.idle
        local frameW, frameH = 32, 48
        local frameIndex = math.max(1, math.min(player.currentFrame or 1, animData.frames))
        local qx = ((frameIndex - 1) % 4) * frameW
        local quad = love.graphics.newQuad(qx, animData.row * frameH, frameW, frameH, 128, 192)
        
        local drawX = math.floor(player.x) + player.width / 2
        local drawY = math.floor(player.y) + player.height 
        local sx = player.facing
        local ox, oy = 16, 48 -- Origin at bottom center of sprite
        
        love.graphics.setColor(1, 1, 1)
        local eq = player.equipment
        local skinRgb = characterAssets.skinColors[player.indices.skin] or {0.92, 0.82, 0.72}
        local frameCol = (frameIndex - 1) % 4
        local lo, bou, jl = animHandMotion(animData.row, frameCol)
        local ohx, ohy = offHandFrame(lo, bou, jl)
        local fhx, fhy = forwardHandFrame(lo, bou, jl)

        local function drawEquipRange(i0, i1)
            for i = i0, i1 do
                if eq[i] then
                    love.graphics.draw(eq[i], quad, drawX, drawY, 0, sx, 1, ox, oy)
                end
            end
        end

        local hasGun = heldWeapon and heldWeapon.image
        local g = player.gunFrame
        if hasGun and not g then
            g = computeHeldGunState(0, heldWeapon)
        end
        local ghX, ghY, gGsx, gGsy, gGsc, gPivotX, gPivotY, aimDraw, gBwx, gBwy, gBarrelWorld, gGunCompact
        if g then
            ghX, ghY = g.ghX, g.ghY
            gGsx, gGsy, gGsc = g.gGsx, g.gGsy, g.gGsc
            gPivotX, gPivotY = g.gPivotX, g.gPivotY
            aimDraw = g.aimDraw
            gBwx, gBwy = g.gBwx, g.gBwy
            gBarrelWorld, gGunCompact = g.gBarrelWorld, g.gGunCompact
        end

        local rcx, rcr = 0, 0
        if hasGun and g and Shooting then
            rcx = (Shooting.getRecoilX() or 0) * 0.12
            rcr = (Shooting.getRecoilRot() or 0)
        end

        local function drawHeldGunSprite()
            if not hasGun or not g then return end
            love.graphics.setColor(1, 1, 1)
            love.graphics.draw(
                heldWeapon.image,
                ghX + rcx, ghY, aimDraw + rcr,
                gGsx, gGsy,
                gPivotX, gPivotY
            )
        end

        -- Smoothed world positions for secondary / fore hand (grip stays on ghX, ghY).
        local function drawGunHands()
            if not hasGun or not g then return end
            local ghW, ghH = tonumber(g.ghX), tonumber(g.ghY)
            local bwx, bwy = tonumber(g.gBwx), tonumber(g.gBwy)
            local gsc = tonumber(g.gGsc)
            local bWorld = tonumber(g.gBarrelWorld)
            if not ghW or not ghH or not bwx or not bwy or not gsc or not bWorld then return end
            local dt = tonumber(love.timer.getDelta()) or 0
            local sk = math.min(1, math.max(0, dt) * 20)
            player.smoothGH = player.smoothGH or {}
            local sm = player.smoothGH
            local function pull2(kx, ky, tx, ty)
                tx, ty = tonumber(tx), tonumber(ty)
                if tx == nil or ty == nil then
                    return tonumber(sm[kx]) or 0, tonumber(sm[ky]) or 0
                end
                local cx = tonumber(sm[kx])
                if cx == nil then cx = tx end
                local cy = tonumber(sm[ky])
                if cy == nil then cy = ty end
                sm[kx] = cx + (tx - cx) * sk
                sm[ky] = cy + (ty - cy) * sk
                return sm[kx], sm[ky]
            end
            local ww = tonumber(heldWeapon.w) or 96
            local compact = g.gGunCompact
            if compact then
                local perpx, perpy = -bwy, bwx
                local side = (sx == 1 and 1 or -1) * (2.1 + math.min(1.4, ww * gsc * 0.045)) * 1.12
                local tuck = 0.9 + ww * gsc * 0.018
                local t1x = ghW + perpx * side + bwx * tuck
                local t1y = ghH + perpy * side + bwy * tuck
                if sx == 1 then
                    t1x = t1x + 2.25
                    t1y = t1y - 0.75
                end
                local px1, py1 = pull2("c1x", "c1y", t1x, t1y)
                local px2, py2 = pull2("c2x", "c2y", ghW, ghH)
                if sx == 1 then
                    drawFloatingHandWorld(px2, py2, skinRgb)
                    drawFloatingHandWorld(px1, py1, skinRgb)
                else
                    drawFloatingHandWorld(px1, py1, skinRgb)
                    drawFloatingHandWorld(px2, py2, skinRgb)
                end
            else
                local fore = math.min(bWorld * 0.5, ww * gsc * 0.36)
                local t1x, t1y = ghW + bwx * fore, ghH + bwy * fore
                local px1, py1 = pull2("l1x", "l1y", t1x, t1y)
                local px2, py2 = pull2("l2x", "l2y", ghW, ghH)
                if sx == 1 then
                    drawFloatingHandWorld(px2, py2, skinRgb)
                    drawFloatingHandWorld(px1, py1, skinRgb)
                else
                    drawFloatingHandWorld(px1, py1, skinRgb)
                    drawFloatingHandWorld(px2, py2, skinRgb)
                end
            end
        end

        if hasGun then
            drawEquipRange(1, #eq)
            if g and heldWeapon and Shooting and heldWeapon.anchors and heldWeapon.anchors.laser then
                Shooting.drawLaser(heldWeapon, {
                    ghX = ghX + rcx, ghY = ghY,
                    aim = aimDraw + rcr,
                    beamAngle = g.aimAngleWorld,
                    gGsx = gGsx, gGsy = gGsy,
                    pivotX = gPivotX, pivotY = gPivotY,
                })
            end
            drawHeldGunSprite()
            if Shooting then
                Shooting.drawBehindHands()
            end
            drawGunHands()
            if Shooting then
                Shooting.drawInFrontOfHands()
            end
            gunFxDrawn = true
        else
            drawEquipRange(1, #eq)
            drawFloatingHandSquare(drawX, drawY, sx, ohx, ohy, skinRgb)
            drawFloatingHandSquare(drawX, drawY, sx, fhx, fhy, skinRgb)
        end
    end

    if Shooting and not gunFxDrawn then
        Shooting.drawBehindHands()
        Shooting.drawInFrontOfHands()
    end

    love.graphics.pop() 

    if Shooting then
        Shooting.drawCrosshair(love.mouse.getX(), love.mouse.getY())
    end

    -- C. UI TEXT
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("[1-4] Base Character Style", 10, 10)
    love.graphics.print("[Q] Random Full Set  [E] Mix Armor  [R] Clear Armor  [G] New gun  [LMB] Fire", 10, 30)
    
    local cName = player.armor.chest > 0 and ArmorSets[player.armor.chest].name or "None"
    local lName = player.armor.legs > 0 and ArmorSets[player.armor.legs].name or "None"
    
    love.graphics.print("Chest: " .. cName, 10, 60)
    love.graphics.print("Legs: " .. lName, 10, 75)
    if heldWeapon and heldWeapon.name then
        love.graphics.print("Gun: " .. heldWeapon.name, 10, 90)
    end
end

