-- Combat / VFX from weapons/main.lua, runnable as a module (virtual world coords).
local weapon_gen = require("weapon_gen")
local PALETTES = weapon_gen.PALETTES
local WEAPON_ARCHETYPES = weapon_gen.WEAPON_ARCHETYPES

local M = {}

local Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
local CombatState = {
    shake = 0, recoilX = 0, recoilRot = 0, fireTimer = 0, crosshairSpread = 0, flashLight = 0
}
local ParticleFX = { systems = {}, blendModes = {} }

local bounds = { worldW = 250, floorY = 130 }
-- love.graphics.scale(s,s) is applied in the character demo; VFX + slugs must use 1/s
-- so on-screen size matches weapons/main.lua (800×600, no extra world scale).
local drawScale = 4

function M.setBounds(worldW, floorY)
    bounds.worldW = worldW or bounds.worldW
    bounds.floorY = floorY or bounds.floorY
end

local function worldSpeedMul()
    return (bounds.worldW or 250) / 800
end

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
    local s = 1 / drawScale
    local muzzleFlash = love.graphics.newParticleSystem(tex, 80)
    muzzleFlash:setParticleLifetime(0.04, 0.08)
    muzzleFlash:setLinearAcceleration(-40, -20, 40, 20)
    muzzleFlash:setSizes(1.3 * s, 0.7 * s, 0.0)
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
    muzzleSmoke:setSizes(0.4 * s, 1.1 * s, 1.6 * s)
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
    impactSparks:setSizes(0.35 * s, 0.1 * s)
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
    impactSmoke:setSizes(0.3 * s, 0.8 * s, 1.2 * s)
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

function M.setDrawScale(pixelScale)
    drawScale = math.max(1, tonumber(pixelScale) or 4)
    ParticleFX = createParticleFX()
end

local function emitFX(system, x, y, count, colors)
    if not system then return end
    system:setPosition(x, y)
    if colors then
        system:setColors(unpack(colors))
    end
    system:emit(count)
end

function M.init()
    Particles, Projectiles, Casings, Flashes = {}, {}, {}, {}
    CombatState = {
        shake = 0, recoilX = 0, recoilRot = 0, fireTimer = 0, crosshairSpread = 0, flashLight = 0
    }
    ParticleFX = createParticleFX()
end

function M.resetSession()
    M.init()
end

local function updateParticleFX(dt)
    for _, system in pairs(ParticleFX.systems) do
        system:update(dt)
    end
end

local function spawnDebris(x, y, color)
    table.insert(Flashes, {
        x = x, y = y, life = love.math.random(0.02, 0.04), size = love.math.random(2, 4), rot = 0, color = {1, 1, 1}
    })
    for _i = 1, love.math.random(1, 3) do
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

local function spawnProjectile(x, y, spellData, archData, baseAngle)
    local sm = worldSpeedMul()
    local speed = love.math.random(1500, 2400) * sm
    local p = {
        x = x, y = y, speed = speed,
        angle = baseAngle + (love.math.random() - 0.5) * archData.spread, life = 2.0,
        color = spellData.highlight, baseColor = spellData.base, style = spellData.style, history = {}
    }
    p.vx = math.cos(p.angle) * p.speed
    p.vy = math.sin(p.angle) * p.speed
    table.insert(Projectiles, p)
end

--- weaponData: same table as weapon_gen.rollRandomProceduralWeapon()
--- ctx: { muzzleX, muzzleY, aimAngleWorld } aimAngleWorld = atan2 toward cursor (full circle)
function M.triggerFire(weaponData, ctx)
    if not weaponData or not ctx then return end
    if CombatState.fireTimer > 0 then return end
    local arch = WEAPON_ARCHETYPES[weaponData.arch]
    if not arch then return end

    local speedVar = love.math.random(90, 110) / 100
    CombatState.fireTimer = (arch.fireDelay / weaponData.rData.stats.speed) * speedVar

    local mods = weaponData.mods or {}
    local kickMod = mods.foregrip and 0.5 or 1.0
    local kickVar = love.math.random(85, 115) / 100
    local actualKick = arch.kick * kickMod * kickVar

    CombatState.recoilX = CombatState.recoilX - actualKick
    CombatState.recoilRot = CombatState.recoilRot - (actualKick * 0.005)
    -- Softer than weapons/main.lua: high-kick weapons were too shaky in scaled virtual space.
    local pelletMul = 1 / math.sqrt(math.max(1, arch.pellets or 1))
    CombatState.shake = math.min(3.2, actualKick * 0.16 * pelletMul)
    CombatState.crosshairSpread = math.min(30, CombatState.crosshairSpread + actualKick)
    CombatState.flashLight = love.math.random(50, 90) / 100

    local mX, mY = ctx.muzzleX, ctx.muzzleY
    local elementKey = weaponData.element or "none"
    local spellData = PALETTES.spells[elementKey] or PALETTES.spells.none

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
        rot = ctx.aimAngleWorld + love.math.random(-0.2, 0.2), color = spellData.base
    })

    if love.math.random() > 0.6 then
        table.insert(Particles, {
            x = mX + love.math.random(-2, 2), y = mY + love.math.random(-2, 2),
            vx = love.math.random(-15, 15), vy = love.math.random(-20, -5),
            life = love.math.random(0.4, 0.7), maxLife = 0.7, size = love.math.random(2, 5),
            color = {0.6, 0.6, 0.6}, blend = "alpha", style = "smoke",
            wobble = love.math.random() * math.pi * 2, wobbleSpeed = love.math.random(-1, 1)
        })
    end

    local baseAngle = ctx.aimAngleWorld
    for _i = 1, arch.pellets do
        spawnProjectile(mX, mY, spellData, arch, baseAngle)
    end

    local a = weaponData.anchors or {}
    local gpx = (a.grip and a.grip.x) or (weaponData.w * 0.38)
    local gpy = (a.grip and a.grip.y) or (weaponData.h * 0.52)
    local cpx = (a.core and a.core.x) or gpx
    local cpy = (a.core and a.core.y) or gpy
    if arch.shell > 0 then
        local ca, sa = math.cos(ctx.gunAngle or baseAngle), math.sin(ctx.gunAngle or baseAngle)
        local dx = (cpx - weaponData.w / 2) * (ctx.gunScale or 0.35)
        local dy = (cpy - weaponData.h / 2) * (ctx.gunScale or 0.35)
        local cX = ctx.gripX + (dx * ca - dy * sa)
        local cY = ctx.gripY + (dx * sa + dy * ca)
        local wm = worldSpeedMul()
        table.insert(Casings, {
            x = cX, y = cY,
            vx = love.math.random(-150, -60) * wm, vy = love.math.random(-300, -180) * wm,
            rot = love.math.random() * math.pi * 2, rotV = love.math.random(-12, 12),
            size = arch.shell, life = 2.0
        })
    end
end

function M.update(dt)
    CombatState.fireTimer = math.max(0, CombatState.fireTimer - dt)
    CombatState.recoilX = CombatState.recoilX + (0 - CombatState.recoilX) * 12 * dt
    CombatState.recoilRot = CombatState.recoilRot + (0 - CombatState.recoilRot) * 12 * dt
    CombatState.shake = math.max(0, CombatState.shake - dt * 45)
    CombatState.crosshairSpread = CombatState.crosshairSpread + (0 - CombatState.crosshairSpread) * 15 * dt
    CombatState.flashLight = math.max(0, CombatState.flashLight - dt * 12)

    local floorY = bounds.floorY
    for i = #Casings, 1, -1 do
        local c = Casings[i]
        c.life = c.life - dt
        c.vy = c.vy + 750 * dt
        c.x = c.x + c.vx * dt
        c.y = c.y + c.vy * dt
        c.rot = c.rot + c.rotV * dt
        if c.y > floorY then
            c.y = floorY
            c.vy = -c.vy * love.math.random(0.3, 0.5)
            c.vx = c.vx * 0.5
            c.rotV = c.rotV * 0.5
        end
        if c.life <= 0 then table.remove(Casings, i) end
    end

    local worldW = bounds.worldW
    for i = #Projectiles, 1, -1 do
        local p = Projectiles[i]
        p.life = p.life - dt
        table.insert(p.history, 1, { x = p.x, y = p.y })
        if #p.history > 12 then table.remove(p.history) end
        p.x = p.x + p.vx * dt
        p.y = p.y + p.vy * dt
        local oob = p.x > worldW + 30 or p.x < -30 or p.life <= 0
        if oob then
            local hx = math.max(-20, math.min(worldW + 20, p.x))
            spawnDebris(hx, p.y, p.color)
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
            p.vx = p.vx * (1 - 2 * dt)
            p.x = p.x + p.vx * dt
            p.y = p.y + p.vy * dt
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

    updateParticleFX(dt)
end

function M.getRecoilX()
    return CombatState.recoilX
end

function M.getRecoilRot()
    return CombatState.recoilRot
end

function M.getShake()
    return CombatState.shake
end

function M.getFlashLight()
    return CombatState.flashLight
end

function M.getElementForFlash(weaponData)
    if not weaponData then return PALETTES.spells.none end
    return PALETTES.spells[weaponData.element or "none"] or PALETTES.spells.none
end

--- Texture point (lx, ly) to world, matching love.graphics.draw(img, x,y,r,sx,sy,ox,oy).
local function gunAnchorWorld(ctx, lx, ly)
    local ox, oy = ctx.pivotX or 0, ctx.pivotY or 0
    local sx, sy = ctx.gGsx or 1, ctx.gGsy or 1
    local r = ctx.aim or 0
    local dx = (lx - ox) * sx
    local dy = (ly - oy) * sy
    local c, s = math.cos(r), math.sin(r)
    local x, y = ctx.ghX or 0, ctx.ghY or 0
    return x + dx * c - dy * s, y + dx * s + dy * c
end

--- weapons/main.lua: laser under gun, soft red beam with flicker (call before gun sprite).
function M.drawLaser(weaponData, ctx)
    if not weaponData or not ctx then return end
    local anchors = weaponData.anchors
    if not anchors or not anchors.laser then return end
    local inv = 1 / drawScale
    local lx, ly = anchors.laser.x, anchors.laser.y
    local lX, lY = gunAnchorWorld(ctx, lx, ly)
    -- Sprite rotation (ctx.aim) keeps the socket on the gun; beam must follow world aim
    -- (cursor from muzzle), not aimDraw — flipped guns aim left while aimDraw stays in (-π/2, π/2).
    local beam = ctx.beamAngle or ctx.aimAngleWorld or ctx.aim or 0
    local flicker = love.math.random(8, 10) / 10
    local reach = math.max((bounds.worldW or 250) * 3, 600 * inv)
    local ex = lX + math.cos(beam) * reach
    local ey = lY + math.sin(beam) * reach
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(1, 0, 0, 0.1 * flicker)
    love.graphics.setLineWidth(math.max(0.5, 4 * inv))
    love.graphics.line(lX, lY, ex, ey)
    love.graphics.setColor(1, 0, 0, 0.3 * flicker)
    love.graphics.setLineWidth(math.max(0.5, 2 * inv))
    love.graphics.line(lX, lY, ex, ey)
    love.graphics.setBlendMode("alpha")
    love.graphics.setLineWidth(1)
end

--- Floor wash when firing (weapons/main.lua polygon over lower screen).
function M.drawFloorFlash(weaponData, floorY, worldW, worldH)
    if CombatState.flashLight <= 0 or not weaponData then return end
    local spell = M.getElementForFlash(weaponData)
    local c = spell.base
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(c[1], c[2], c[3], CombatState.flashLight * 0.08)
    local w = worldW or bounds.worldW or 250
    local fy = floorY or bounds.floorY or 130
    local H = worldH or fy + 80
    local inset = w * 0.125
    love.graphics.polygon("fill", 0, fy, w, fy, w - inset, H, inset, H)
    love.graphics.setBlendMode("alpha")
end

local function drawParticleFX()
    for key, system in pairs(ParticleFX.systems) do
        local blendMode = ParticleFX.blendModes[key] or "alpha"
        love.graphics.setBlendMode(blendMode, "alphamultiply")
        love.graphics.draw(system)
    end
    love.graphics.setBlendMode("alpha")
end

--- Casings + tracers (before hands so muzzle VFX does not hide both hands).
function M.drawBehindHands()
    local inv = 1 / drawScale
    for _, c in ipairs(Casings) do
        local sz = c.size * inv
        love.graphics.push()
        love.graphics.translate(c.x, c.y)
        love.graphics.rotate(c.rot)
        love.graphics.setColor(PALETTES.brass.base)
        love.graphics.rectangle("fill", -sz * 1.5, -sz, sz * 3, sz * 2)
        love.graphics.setColor(PALETTES.brass.highlight)
        love.graphics.rectangle("fill", -sz * 1.5, -sz, sz * 3, math.max(inv, 0.25))
        love.graphics.pop()
    end

    love.graphics.setBlendMode("alpha")
    for _, p in ipairs(Projectiles) do
        if p.style ~= "void" then love.graphics.setBlendMode("add", "alphamultiply") end
        love.graphics.setColor(p.color)
        -- Pixel slugs (weapon_gen spell styles: float, shatter, void, kinetic, …) — no circles.
        local ang = math.atan2(p.vy, p.vx)
        local rw, rh = 16 * inv, 4 * inv
        if p.style == "void" then
            rw, rh = 11 * inv, 5 * inv
        elseif p.style == "float" or p.style == "plasma" then
            rw, rh = 18 * inv, 3 * inv
        elseif p.style == "shatter" or p.style == "ice" then
            rw, rh = 9 * inv, 6 * inv
        elseif p.style == "burn" or p.style == "zap" then
            rw, rh = 15 * inv, 4 * inv
        elseif p.style == "drip" then
            rw, rh = 5 * inv, 7 * inv
        end
        love.graphics.push()
        love.graphics.translate(p.x, p.y)
        love.graphics.rotate(ang)
        love.graphics.rectangle("fill", -rw * 0.5, -rh * 0.5, rw, rh)
        love.graphics.pop()
        if #p.history > 1 then
            local lwPlasma = math.max(1, 10 * inv)
            local lw = math.max(1, 4 * inv)
            local thickTrail = (p.style == "float" or p.style == "plasma")
            love.graphics.setLineWidth(thickTrail and lwPlasma or lw)
            for hi = 1, #p.history - 1 do
                local alpha = 1 - (hi / #p.history)
                love.graphics.setColor(p.baseColor[1], p.baseColor[2], p.baseColor[3], alpha)
                love.graphics.line(p.history[hi].x, p.history[hi].y, p.history[hi + 1].x, p.history[hi + 1].y)
            end
        end
        love.graphics.setBlendMode("alpha")
    end
    love.graphics.setLineWidth(1)
end

--- Muzzle / impact particles + flashes + smoke (after hands).
function M.drawInFrontOfHands()
    drawParticleFX()

    local invF = 1 / drawScale
    love.graphics.setBlendMode("add", "alphamultiply")
    for _, f in ipairs(Flashes) do
        local alpha = f.life * 15
        love.graphics.setColor(f.color[1], f.color[2], f.color[3], alpha)
        local numSpikes = love.math.random(3, 5)
        for j = 1, numSpikes do
            local ang = f.rot + (math.pi / numSpikes) * j - (math.pi / 2) + love.math.random(-0.3, 0.3)
            local rad = f.size * love.math.random(0.7, 1.3) * invF
            love.graphics.polygon("fill", f.x, f.y,
                f.x + math.cos(ang - 0.2) * rad * 0.3, f.y + math.sin(ang - 0.2) * rad * 0.3,
                f.x + math.cos(ang) * rad, f.y + math.sin(ang) * rad,
                f.x + math.cos(ang + 0.2) * rad * 0.3, f.y + math.sin(ang + 0.2) * rad * 0.3)
        end
        love.graphics.circle("fill", f.x, f.y, f.size * 0.3 * invF)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.circle("fill", f.x, f.y, f.size * 0.15 * invF)
    end

    love.graphics.setBlendMode("alpha")
    for _, p in ipairs(Particles) do
        local alpha = p.life / p.maxLife
        if p.style == "smoke" then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha * 0.3)
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.wobble)
            local s = p.size * invF
            love.graphics.rectangle("fill", -s, -s / 2, s * 2, s)
            love.graphics.rectangle("fill", -s / 2, -s, s, s * 2)
            love.graphics.rectangle("fill", -s * 0.7, -s * 0.7, s * 1.4, s * 1.4)
            love.graphics.pop()
        elseif p.style == "void" then
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            local d = p.size * invF * 1.25
            love.graphics.rectangle("fill", p.x - d * 0.5, p.y - d * 0.5, d, d)
        else
            love.graphics.setColor(p.color[1], p.color[2], p.color[3], alpha)
            local d = p.size * invF
            love.graphics.rectangle("fill", p.x, p.y, d, d)
        end
    end
end

function M.draw(weaponData)
    M.drawBehindHands()
    M.drawInFrontOfHands()
end

--- Screen-space crosshair after love.graphics.pop from scaled world.
function M.drawCrosshair(screenX, screenY)
    local cx, cy = screenX, screenY
    local sp = CombatState.crosshairSpread + 4
    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle("fill", cx - 1, cy - sp - 6, 2, 6)
    love.graphics.rectangle("fill", cx - 1, cy + sp, 2, 6)
    love.graphics.rectangle("fill", cx - sp - 6, cy - 1, 6, 2)
    love.graphics.rectangle("fill", cx + sp, cy - 1, 6, 2)
    love.graphics.setColor(1, 0, 0, 0.8)
    love.graphics.rectangle("fill", cx - 1, cy - 1, 2, 2)
end

return M
