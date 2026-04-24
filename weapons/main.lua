-- main.lua
-- Procedural Weapon Generation Engine v12.0 (Organic Smoke & Detail Polish)

local has_flags, FeatureFlags = pcall(require, "game.core.feature_flags")
local has_weapon_adapter, WeaponCompat = pcall(require, "prototypes.adapters.weapon_compat")

local function is_flag_enabled(name)
    if not has_flags or type(FeatureFlags) ~= "table" or type(FeatureFlags.is_enabled) ~= "function" then
        return false
    end
    return FeatureFlags.is_enabled(name)
end

--------------------------------------------------------------------------------
-- 1. SYSTEM PALETTES, RARITIES & SETTINGS (from weapon_gen.lua)
-------------------------------------------------------------------------------
local weapon_gen = require("weapon_gen")
local PALETTES = weapon_gen.PALETTES
local RARITIES = weapon_gen.RARITIES
local WEAPON_ARCHETYPES = weapon_gen.WEAPON_ARCHETYPES
local generateGun = weapon_gen.generateGun

-------------------------------------------------------------------------------
-- 3. COMBAT, EFFECTS & MICROINTERACTIONS
--------------------------------------------------------------------------------
local Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
local MouseX, MouseY = 400, 300

local CombatState = { shake = 0, recoilX = 0, recoilRot = 0, fireTimer = 0, crosshairSpread = 0, flashLight = 0 }
local ParticleFX = { systems = {} }

local function makeParticleTexture(size)
    local canvas = love.graphics.newCanvas(size, size)
    love.graphics.setCanvas(canvas)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("fill", size * 0.5, size * 0.5, size * 0.45)
    love.graphics.setCanvas()
    return canvas
end

local function createParticleFX()
    local tex = makeParticleTexture(16)

    local muzzleFlash = love.graphics.newParticleSystem(tex, 80)
    muzzleFlash:setParticleLifetime(0.04, 0.08)
    muzzleFlash:setLinearAcceleration(-40, -20, 40, 20)
    muzzleFlash:setSizes(1.3, 0.7, 0.0)
    muzzleFlash:setSizeVariation(0.4)
    muzzleFlash:setSpeed(20, 90)
    muzzleFlash:setDirection(0)
    muzzleFlash:setSpread(math.pi * 0.7)
    muzzleFlash:setEmissionRate(0)
    muzzleFlash:setInsertMode("top")
    muzzleFlash:stop()

    local muzzleSmoke = love.graphics.newParticleSystem(tex, 120)
    muzzleSmoke:setParticleLifetime(0.3, 0.75)
    muzzleSmoke:setLinearAcceleration(-12, -30, 12, -5)
    muzzleSmoke:setSizes(0.4, 1.1, 1.6)
    muzzleSmoke:setSizeVariation(0.35)
    muzzleSmoke:setSpeed(8, 30)
    muzzleSmoke:setDirection(-math.pi * 0.5)
    muzzleSmoke:setSpread(math.pi * 0.45)
    muzzleSmoke:setEmissionRate(0)
    muzzleSmoke:setInsertMode("top")
    muzzleSmoke:stop()

    local impactSparks = love.graphics.newParticleSystem(tex, 100)
    impactSparks:setParticleLifetime(0.08, 0.2)
    impactSparks:setLinearAcceleration(-500, -220, -120, 220)
    impactSparks:setSizes(0.35, 0.1)
    impactSparks:setSizeVariation(0.5)
    impactSparks:setSpeed(50, 180)
    impactSparks:setDirection(math.pi)
    impactSparks:setSpread(math.pi * 0.8)
    impactSparks:setEmissionRate(0)
    impactSparks:setInsertMode("top")
    impactSparks:stop()

    local impactSmoke = love.graphics.newParticleSystem(tex, 100)
    impactSmoke:setParticleLifetime(0.15, 0.4)
    impactSmoke:setLinearAcceleration(-80, -40, 80, 40)
    impactSmoke:setSizes(0.3, 0.8, 1.2)
    impactSmoke:setSizeVariation(0.4)
    impactSmoke:setSpeed(20, 70)
    impactSmoke:setDirection(math.pi)
    impactSmoke:setSpread(math.pi * 0.6)
    impactSmoke:setEmissionRate(0)
    impactSmoke:setInsertMode("top")
    impactSmoke:stop()

    return {
        texture = tex,
        blendModes = {
            muzzleFlash = "add",
            muzzleSmoke = "alpha",
            impactSparks = "add",
            impactSmoke = "alpha"
        },
        systems = {
            muzzleFlash = muzzleFlash,
            muzzleSmoke = muzzleSmoke,
            impactSparks = impactSparks,
            impactSmoke = impactSmoke
        }
    }
end

local function emitFX(system, x, y, count, colors)
    if not system then return end
    system:setPosition(x, y)
    if colors then
        system:setColors(unpack(colors))
    end
    system:emit(count)
end

local function updateParticleFX(dt)
    for _, system in pairs(ParticleFX.systems) do
        system:update(dt)
    end
end

local function drawParticleFX()
    for key, system in pairs(ParticleFX.systems) do
        local blendMode = ParticleFX.blendModes[key] or "alpha"
        love.graphics.setBlendMode(blendMode, "alphamultiply")
        love.graphics.draw(system)
    end
    love.graphics.setBlendMode("alpha")
end

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
    emitFX(ParticleFX.systems.impactSparks, x, y, love.math.random(10, 16), {
        color[1], color[2], color[3], 1.0,
        color[1], color[2], color[3], 0.8,
        1.0, 1.0, 1.0, 0.0
    })
    emitFX(ParticleFX.systems.impactSmoke, x, y, love.math.random(4, 8), {
        0.7, 0.7, 0.72, 0.35,
        0.5, 0.5, 0.52, 0.2,
        0.3, 0.3, 0.32, 0.0
    })
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
    emitFX(ParticleFX.systems.muzzleFlash, mX, mY, love.math.random(8, 14), {
        spellData.highlight[1], spellData.highlight[2], spellData.highlight[3], 1.0,
        spellData.base[1], spellData.base[2], spellData.base[3], 0.75,
        spellData.base[1], spellData.base[2], spellData.base[3], 0.0
    })
    emitFX(ParticleFX.systems.muzzleSmoke, mX, mY, love.math.random(4, 7), {
        0.85, 0.85, 0.88, 0.3,
        0.65, 0.65, 0.68, 0.18,
        0.45, 0.45, 0.48, 0.0
    })
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

local ARCH_COMPAT_MAP = {
    assault_rifle = "AssaultRifle",
    smg = "SMG",
}

local RARITY_COMPAT_MAP = {
    scrap = "Scrap",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
    mythic = "Mythic",
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

local function normalize_weapon_anchors(anchors, w, h)
    local default_muzzle = { x = w, y = math.floor(h * 0.5) }
    local default_core = { x = math.floor(w * 0.5), y = math.floor(h * 0.5) }
    local default_grip = { x = math.floor(w * 0.38), y = math.floor(h * 0.55) }
    if type(anchors) ~= "table" then
        return { muzzle = default_muzzle, core = default_core, laser = nil, grip = default_grip }
    end

    local muzzle = type(anchors.muzzle) == "table" and anchors.muzzle or default_muzzle
    local core = type(anchors.core) == "table" and anchors.core or default_core
    local laser = type(anchors.laser) == "table" and anchors.laser or nil
    local grip = type(anchors.grip) == "table" and anchors.grip or default_grip
    return { muzzle = muzzle, core = core, laser = laser, grip = grip }
end

local function rollNewWeapon()
    Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
    ParticleFX = createParticleFX()
    if is_flag_enabled("enable_mte_weapon_gen") and has_weapon_adapter and type(WeaponCompat.rollNewWeapon) == "function" then
        local compat, compat_err = WeaponCompat.rollNewWeapon()
        if compat and compat.image then
            local meta = read_compat_meta(compat)
            local arch_key = tostring(meta.archetype or compat.arch or "assault_rifle"):lower()
            local arch = ARCH_COMPAT_MAP[arch_key] or "AssaultRifle"
            local rarity_key = tostring(meta.rarity or "common"):lower()
            local rarity = RARITY_COMPAT_MAP[rarity_key] or "Common"
            local element = tostring(meta.element or "none"):lower()
            local width = normalize_dimension(compat.w, 96)
            local height = normalize_dimension(compat.h, 48)
            Weapon = {
                image = compat.image,
                anchors = normalize_weapon_anchors(compat.anchors, width, height),
                w = width,
                h = height,
                arch = arch,
                element = PALETTES.spells[element] and element or "none",
                rarity = rarity,
                rData = RARITIES[rarity] or RARITIES.Common,
                skin = meta.skin or "MTE",
                name = compat.name or (rarity .. " " .. arch),
                mods = {},
            }
            return
        end
        if compat_err then
            print("MTE weapon adapter failed; falling back to legacy generator: " .. tostring(compat_err))
        end
    end

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
    ParticleFX = createParticleFX()
    rollNewWeapon()
end

function love.keypressed(key)
    if key == "space" then rollNewWeapon() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.update(dt)
    updateCombatPhysics(dt)
    updateParticleFX(dt)
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

    drawParticleFX()

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