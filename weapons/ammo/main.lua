-- main.lua
-- Procedural Ammo & Item Generation Engine

local has_flags, FeatureFlags = pcall(require, "game.core.feature_flags")
local has_ammo_adapter, AmmoCompat = pcall(require, "prototypes.adapters.ammo_compat")

local function is_flag_enabled(name)
    if not has_flags or type(FeatureFlags) ~= "table" or type(FeatureFlags.is_enabled) ~= "function" then
        return false
    end
    return FeatureFlags.is_enabled(name)
end

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES & AMMO ARCHETYPES
--------------------------------------------------------------------------------
local PALETTES = {
    brass     = { base={0.8, 0.65, 0.2}, dark={0.5, 0.4, 0.1}, highlight={0.9, 0.85, 0.4} },
    copper    = { base={0.7, 0.35, 0.15}, dark={0.4, 0.15, 0.05}, highlight={0.9, 0.5, 0.2} },
    lead      = { base={0.35, 0.35, 0.4}, dark={0.2, 0.2, 0.25}, highlight={0.5, 0.5, 0.55} },
    plastic   = { base={0.8, 0.15, 0.15}, dark={0.4, 0.05, 0.05}, highlight={0.9, 0.3, 0.3} }, 
    cardboard = { base={0.6, 0.5, 0.35}, dark={0.4, 0.3, 0.2}, highlight={0.7, 0.6, 0.45} },
    metal     = { base={0.45, 0.45, 0.5}, dark={0.2, 0.2, 0.25}, highlight={0.7, 0.7, 0.75} },
    energy    = { base={0.1, 0.8, 0.9}, dark={0.05, 0.4, 0.5}, highlight={0.5, 1.0, 1.0} },
    wood      = { base={0.5, 0.35, 0.2}, dark={0.25, 0.15, 0.08}, highlight={0.6, 0.45, 0.25} },
    ui        = { bg={0.04, 0.05, 0.07}, panel={0.08, 0.1, 0.12, 0.95}, text={0.9, 0.9, 0.9} }
}

local AMMO_ARCHETYPES = {
    Pistol   = { name="9mm Light", b_w=6, b_h=12, tip="round", case="brass", box="cardboard", box_w=24, box_h=20, count=50, box_color={0.8, 0.8, 0.8} },
    Rifle    = { name="5.56 Heavy", b_w=6, b_h=20, tip="pointy", case="brass", box="metal", box_w=20, box_h=28, count=30, box_color={0.3, 0.4, 0.3} },
    Shotgun  = { name="12 Gauge Shells", b_w=8, b_h=14, tip="flat", case="plastic", box="cardboard", box_w=28, box_h=16, count=12, box_color={0.8, 0.2, 0.2} },
    Sniper   = { name=".50 Caliber", b_w=8, b_h=28, tip="pointy", case="brass", box="metal", box_w=32, box_h=18, count=10, box_color={0.2, 0.2, 0.2} },
    Energy   = { name="Plasma Cells", b_w=8, b_h=16, tip="cell", case="metal", box="metal", box_w=24, box_h=22, count=100, box_color={0.1, 0.8, 0.9} },
    Rocket   = { name="RPG Warheads", b_w=12, b_h=36, tip="rocket", case="metal", box="wood", box_w=40, box_h=24, count=4, box_color={0.4, 0.5, 0.2} }
}

--------------------------------------------------------------------------------
-- 2. CANVAS GENERATORS
--------------------------------------------------------------------------------
local function makeCanvas(w, h, drawFunction)
    local c = love.graphics.newCanvas(w, h)
    love.graphics.setCanvas(c)
    love.graphics.clear(0, 0, 0, 0)
    drawFunction()
    love.graphics.setCanvas()
    return {img = c, w = w, h = h}
end

local function drawComponent(x, y, w, h, cBase, cDark, cHigh)
    love.graphics.setColor(cDark)
    love.graphics.rectangle("fill", x-1, y-1, w+2, h+2)
    love.graphics.setColor(cBase)
    love.graphics.rectangle("fill", x, y, w, h)
    if cHigh then
        love.graphics.setColor(cHigh)
        love.graphics.rectangle("fill", x, y, w, 1)
        love.graphics.setColor(cBase) -- Reset
    end
end

local function generateBullet(arch)
    local w, h = 32, 48
    return makeCanvas(w, h, function()
        local bw, bh = arch.b_w, arch.b_h
        local bx = math.floor(w/2 - bw/2)
        local by = math.floor(h/2 - bh/2) + 4
        
        local cCase = PALETTES[arch.case]

        if arch.tip == "round" then
            drawComponent(bx, by + 4, bw, bh - 4, cCase.base, cCase.dark, cCase.highlight)
            drawComponent(bx + 1, by, bw - 2, 4, PALETTES.copper.base, PALETTES.copper.dark, PALETTES.copper.highlight)
            drawComponent(bx - 1, by + bh - 2, bw + 2, 2, cCase.base, cCase.dark, nil) -- Rim

        elseif arch.tip == "pointy" then
            drawComponent(bx, by + 8, bw, bh - 8, cCase.base, cCase.dark, cCase.highlight)
            drawComponent(bx + 1, by + 4, bw - 2, 4, cCase.base, cCase.dark, nil) -- Neck
            -- Sharp tip
            love.graphics.setColor(PALETTES.copper.dark)
            love.graphics.polygon("fill", bx, by + 4, bx + bw, by + 4, bx + bw/2, by - 4)
            love.graphics.setColor(PALETTES.copper.base)
            love.graphics.polygon("fill", bx + 1, by + 4, bx + bw - 1, by + 4, bx + bw/2, by - 2)
            drawComponent(bx - 1, by + bh - 2, bw + 2, 2, cCase.base, cCase.dark, nil) -- Rim

        elseif arch.tip == "flat" then
            drawComponent(bx, by, bw, bh - 4, cCase.base, cCase.dark, cCase.highlight)
            drawComponent(bx, by + bh - 4, bw, 4, PALETTES.brass.base, PALETTES.brass.dark, nil) -- Brass base
            drawComponent(bx - 1, by + bh - 2, bw + 2, 2, PALETTES.brass.base, PALETTES.brass.dark, nil) -- Rim
            -- Shell ridges
            love.graphics.setColor(cCase.dark)
            for i=2, bh-6, 3 do
                love.graphics.rectangle("fill", bx + 1, by + i, bw - 2, 1)
            end

        elseif arch.tip == "cell" then
            drawComponent(bx, by + 2, bw, bh - 4, PALETTES.energy.base, PALETTES.energy.dark, PALETTES.energy.highlight)
            drawComponent(bx, by, bw, 2, cCase.base, cCase.dark, cCase.highlight) -- Top cap
            drawComponent(bx, by + bh - 2, bw, 2, cCase.base, cCase.dark, nil) -- Bottom cap
            -- Core glow line
            love.graphics.setColor(1, 1, 1, 0.8)
            love.graphics.rectangle("fill", bx + math.floor(bw/2), by + 3, 1, bh - 6)

        elseif arch.tip == "rocket" then
            drawComponent(bx, by + 8, bw, bh - 12, cCase.base, cCase.dark, cCase.highlight)
            -- Warhead
            love.graphics.setColor(PALETTES.plastic.dark) -- using plastic palette for red tip
            love.graphics.polygon("fill", bx-1, by+8, bx+bw+1, by+8, bx+bw/2, by-2)
            love.graphics.setColor(PALETTES.plastic.base)
            love.graphics.polygon("fill", bx, by+8, bx+bw, by+8, bx+bw/2, by)
            -- Fins
            love.graphics.setColor(cCase.dark)
            love.graphics.rectangle("fill", bx - 2, by + bh - 6, 2, 4)
            love.graphics.rectangle("fill", bx + bw, by + bh - 6, 2, 4)
            -- Thruster
            drawComponent(bx + 2, by + bh - 4, bw - 4, 4, PALETTES.copper.base, PALETTES.copper.dark, nil)
        end
    end)
end

local function generateAmmoBox(arch)
    local w, h = 64, 64
    return makeCanvas(w, h, function()
        local boxW, boxH = arch.box_w, arch.box_h
        local bx = math.floor(w/2 - boxW/2)
        local by = math.floor(h/2 - boxH/2) + 8
        local cBox = PALETTES[arch.box]

        drawComponent(bx, by, boxW, boxH, cBox.base, cBox.dark, cBox.highlight)

        if arch.box == "cardboard" then
            -- Flaps
            love.graphics.setColor(cBox.dark)
            love.graphics.rectangle("fill", bx, by + 4, boxW, 1)
            -- Label
            love.graphics.setColor(0.9, 0.9, 0.9)
            love.graphics.rectangle("fill", bx + 4, by + 8, boxW - 8, boxH - 12)
            love.graphics.setColor(arch.box_color)
            love.graphics.rectangle("fill", bx + 6, by + 10, boxW - 12, 4)

        elseif arch.box == "metal" then
            -- Tin lid
            drawComponent(bx - 1, by - 2, boxW + 2, 4, cBox.base, cBox.dark, cBox.highlight)
            -- Latch
            love.graphics.setColor(cBox.dark)
            love.graphics.rectangle("fill", bx + math.floor(boxW/2) - 2, by + 2, 4, 6)
            -- Ridges
            love.graphics.setColor(cBox.dark)
            for i=by + 8, by + boxH - 4, 4 do
                love.graphics.rectangle("fill", bx + 2, i, boxW - 4, 1)
            end
            -- Stripe indicator
            love.graphics.setColor(arch.box_color)
            love.graphics.rectangle("fill", bx + 4, by + math.floor(boxH/2) - 2, boxW - 8, 4)

        elseif arch.box == "wood" then
            -- Planks
            love.graphics.setColor(cBox.dark)
            love.graphics.rectangle("fill", bx, by + math.floor(boxH/3), boxW, 1)
            love.graphics.rectangle("fill", bx, by + math.floor(boxH/3)*2, boxW, 1)
            -- Cross brace
            love.graphics.line(bx, by, bx + boxW, by + boxH)
            love.graphics.line(bx, by + boxH, bx + boxW, by)
            -- Stencil
            love.graphics.setColor(0.2, 0.2, 0.2, 0.8)
            love.graphics.rectangle("fill", bx + math.floor(boxW/2) - 4, by + math.floor(boxH/2) - 4, 8, 8)
        end
    end)
end

--------------------------------------------------------------------------------
-- 3. MAIN LOOP
--------------------------------------------------------------------------------
local CurrentAmmo = {}

local function read_compat_meta(compat)
    if type(compat) ~= "table" or type(compat.meta) ~= "table" then
        return {}
    end
    return compat.meta
end

local function read_compat_stats(compat)
    if type(compat) ~= "table" or type(compat.stats) ~= "table" then
        return {}
    end
    return compat.stats
end

local function rollNewAmmo()
    if is_flag_enabled("enable_mte_ammo_gen") and has_ammo_adapter and type(AmmoCompat.rollNewAmmo) == "function" then
        local compat, compat_err = AmmoCompat.rollNewAmmo()
        if compat and compat.image then
            local meta = read_compat_meta(compat)
            local stats = read_compat_stats(compat)
            local damage_mod = tonumber(stats.damage_mod) or 1
            CurrentAmmo = {
                bulletImg = compat.image,
                boxImg = compat.box_image or compat.image,
                arch = {
                    name = meta.label or compat.name or "MTE Ammo",
                    count = math.max(1, math.floor(damage_mod * 30)),
                },
                type = meta.archetype or compat.arch or "light_round",
            }
            return
        end
        if compat_err then
            print("MTE ammo adapter failed; falling back to legacy generator: " .. tostring(compat_err))
        end
    end

    local types = {"Pistol", "Rifle", "Shotgun", "Sniper", "Energy", "Rocket"}
    local sel = types[love.math.random(1, #types)]
    local arch = AMMO_ARCHETYPES[sel]
    
    CurrentAmmo = {
        bulletImg = generateBullet(arch).img,
        boxImg = generateAmmoBox(arch).img,
        arch = arch,
        type = sel
    }
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.graphics.setLineStyle("rough")
    rollNewAmmo()
end

function love.keypressed(key)
    if key == "space" then rollNewAmmo() end
    if key == "escape" then love.event.quit() end
end

function love.draw()
    local time = love.timer.getTime()
    
    love.graphics.clear(PALETTES.ui.bg)
    
    -- Grid background
    love.graphics.setColor(0.08, 0.1, 0.12, 0.4)
    local gridScroll = (time * 15) % 40
    for x = 0, 800, 40 do love.graphics.line(x - gridScroll, 0, x - gridScroll, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y, 800, y) end

    -- Floating animation
    local hover1 = math.sin(time * 3) * 6
    local hover2 = math.cos(time * 2.5) * 4

    -- Shadows
    love.graphics.setColor(0.02, 0.03, 0.04, 0.6)
    love.graphics.ellipse("fill", 300, 420, 40, 10)
    love.graphics.ellipse("fill", 550, 420, 25, 8)

    -- Draw the Pack/Box (scaled x6)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(CurrentAmmo.boxImg, 300, 340 + hover1, 0, 6, 6, 32, 32)
    
    -- Draw the single Bullet/Shell (scaled x6)
    love.graphics.draw(CurrentAmmo.bulletImg, 550, 360 + hover2, 0, 6, 6, 16, 24)
end