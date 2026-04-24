-- Procedural Consumable Engine v3.0 (Polished Juice & Micro-interactions)

local has_flags, FeatureFlags = pcall(require, "game.core.feature_flags")
local has_consumable_adapter, ConsumableCompat = pcall(require, "prototypes.adapters.consumable_compat")

local function is_flag_enabled(name)
    if not has_flags or type(FeatureFlags) ~= "table" or type(FeatureFlags.is_enabled) ~= "function" then
        return false
    end
    return FeatureFlags.is_enabled(name)
end

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
local function clamp(v, lo, hi) return math.max(lo, math.min(hi, v)) end
local function randf(lo, hi) return lo + (hi - lo) * love.math.random() end

--------------------------------------------------------------------------------
-- 1.5 HOT-PARTICLE STYLE FX PRESETS (Data-driven, export-friendly shape)
--------------------------------------------------------------------------------
local HOT_PARTICLE_PRESETS = {
    default = {
        life = 1.0,
        systems = {
            {
                blendMode = "alpha", emitAtStart = 30, kickStartSteps = 2, kickStartDt = 1 / 60,
                particleLifetime = {0.25, 0.6}, speed = {90, 300}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-80, -80, 80, 80}, linearDamping = {0.8, 2.5},
                radialAcceleration = {-20, 10}, tangentialAcceleration = {-40, 40},
                spin = {-4, 4}, spinVariation = 1.0, sizes = {1.2, 0.7, 0.0}, sizeVariation = 0.4
            }
        }
    },
    splash = {
        life = 1.2,
        systems = {
            {
                blendMode = "alpha", emitAtStart = 42, kickStartSteps = 3, kickStartDt = 1 / 60,
                particleLifetime = {0.3, 0.9}, speed = {120, 440}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-30, 400, 30, 1150}, linearDamping = {0.4, 1.3},
                radialAcceleration = {-20, 20}, tangentialAcceleration = {-80, 80},
                spin = {-5, 5}, spinVariation = 1.0, sizes = {1.8, 1.1, 0.2}, sizeVariation = 0.5
            },
            {
                blendMode = "add", emitAtStart = 16, kickStartSteps = 2, kickStartDt = 1 / 60,
                particleLifetime = {0.2, 0.45}, speed = {80, 180}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-20, -20, 20, 20}, linearDamping = {3.0, 6.0},
                radialAcceleration = {-120, -30}, tangentialAcceleration = {-20, 20},
                spin = {-2, 2}, spinVariation = 0.5, sizes = {2.5, 0.0}, sizeVariation = 0.2
            }
        }
    },
    magic = {
        life = 1.5,
        systems = {
            {
                blendMode = "add", emitAtStart = 58, kickStartSteps = 5, kickStartDt = 1 / 120,
                particleLifetime = {0.4, 1.2}, speed = {30, 220}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-60, -220, 60, -30}, linearDamping = {0.4, 1.0},
                radialAcceleration = {-140, -40}, tangentialAcceleration = {-260, 260},
                spin = {-8, 8}, spinVariation = 1.0, sizes = {1.6, 1.1, 0.3}, sizeVariation = 0.6
            },
            {
                blendMode = "add", emitAtStart = 24, kickStartSteps = 1, kickStartDt = 1 / 60,
                particleLifetime = {0.18, 0.35}, speed = {10, 30}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-10, -10, 10, 10}, linearDamping = {5.0, 8.0},
                radialAcceleration = {-200, -80}, tangentialAcceleration = {-40, 40},
                spin = {-4, 4}, spinVariation = 1.0, sizes = {3.2, 0.0}, sizeVariation = 0.1
            }
        }
    },
    metal = {
        life = 1.0,
        systems = {
            {
                blendMode = "alpha", emitAtStart = 34, kickStartSteps = 2, kickStartDt = 1 / 60,
                particleLifetime = {0.3, 0.8}, speed = {140, 380}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-40, 380, 40, 980}, linearDamping = {0.3, 1.2},
                radialAcceleration = {-30, 20}, tangentialAcceleration = {-50, 50},
                spin = {-9, 9}, spinVariation = 1.0, sizes = {1.0, 1.0, 0.4}, sizeVariation = 0.3
            }
        }
    },
    glass = {
        life = 1.1,
        systems = {
            {
                blendMode = "alpha", emitAtStart = 30, kickStartSteps = 2, kickStartDt = 1 / 60,
                particleLifetime = {0.35, 1.0}, speed = {100, 320}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-25, 280, 25, 900}, linearDamping = {0.2, 0.8},
                radialAcceleration = {-20, 20}, tangentialAcceleration = {-30, 30},
                spin = {-12, 12}, spinVariation = 1.0, sizes = {1.0, 0.8, 0.2}, sizeVariation = 0.2
            },
            {
                blendMode = "add", emitAtStart = 12, kickStartSteps = 1, kickStartDt = 1 / 60,
                particleLifetime = {0.15, 0.28}, speed = {40, 90}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-20, -20, 20, 20}, linearDamping = {4.0, 7.0},
                radialAcceleration = {-180, -100}, tangentialAcceleration = {-20, 20},
                spin = {-2, 2}, spinVariation = 0.5, sizes = {2.2, 0.0}, sizeVariation = 0.1
            }
        }
    },
    crumb = {
        life = 0.95,
        systems = {
            {
                blendMode = "alpha", emitAtStart = 45, kickStartSteps = 2, kickStartDt = 1 / 60,
                particleLifetime = {0.2, 0.65}, speed = {70, 250}, spread = math.pi * 2, direction = 0,
                linearAcceleration = {-90, 330, 90, 1100}, linearDamping = {1.4, 3.4},
                radialAcceleration = {-10, 5}, tangentialAcceleration = {-45, 45},
                spin = {-6, 6}, spinVariation = 1.0, sizes = {1.4, 0.8, 0.0}, sizeVariation = 0.5
            }
        }
    }
}

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
local FloatingTexts = {}
local MouseX, MouseY = 400, 300
local ActiveItem = {}
local FXTexture
local FXBursts = {}
local IdleFx = nil
local Scene = {
    motion = 1.0, bgSpeed = 10, bobSpeed = 2.2, bobAmount = 7,
    tilt = 0.15, consumeIntensity = 1.0, accent = {0.2, 0.6, 1.0}, rarityBias = 0
}

-- Juice State
local Anim = {
    shake = 0, scaleX = 0, scaleY = 0, targetScale = 1.0, 
    popT = 0, isConsumed = false, screenFlash = 0, itemAlpha = 1.0
}

local function makeFxPixelTexture()
    local c = love.graphics.newCanvas(4, 4)
    love.graphics.setCanvas(c)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", 0, 0, 4, 4)
    love.graphics.setCanvas()
    c:setFilter("nearest", "nearest")
    return c
end

local function setParticleSystemFromPreset(ps, cfg)
    ps:setDirection(cfg.direction or 0)
    ps:setSpread(cfg.spread or (math.pi * 2))
    ps:setParticleLifetime(cfg.particleLifetime[1], cfg.particleLifetime[2])
    ps:setSpeed(cfg.speed[1], cfg.speed[2])
    ps:setLinearAcceleration(cfg.linearAcceleration[1], cfg.linearAcceleration[2], cfg.linearAcceleration[3], cfg.linearAcceleration[4])
    ps:setLinearDamping(cfg.linearDamping[1], cfg.linearDamping[2])
    ps:setRadialAcceleration(cfg.radialAcceleration[1], cfg.radialAcceleration[2])
    ps:setTangentialAcceleration(cfg.tangentialAcceleration[1], cfg.tangentialAcceleration[2])
    ps:setSpin(cfg.spin[1], cfg.spin[2])
    ps:setSpinVariation(cfg.spinVariation or 0)
    ps:setSizes(unpack(cfg.sizes))
    ps:setSizeVariation(cfg.sizeVariation or 0)
    ps:setEmitterLifetime(0.05)
end

local function particleColorsForStyle(style, liquidColor)
    if style == "crumb" then
        return PALETTES.paper.dark, PALETTES.paper.highlight
    elseif style == "metal" then
        return PALETTES.metal.base, PALETTES.metal.highlight
    elseif style == "glass" then
        return PALETTES.glass.base, PALETTES.glass.highlight
    elseif style == "magic" then
        return liquidColor, PALETTES.liquids.mana.highlight
    elseif style == "spark" then
        return PALETTES.metal.highlight, liquidColor
    elseif style == "splat" then
        return liquidColor, PALETTES.flesh.base
    end
    return liquidColor, PALETTES.liquids.health.highlight
end

local function makeBurst(style, itemData, x, y)
    local preset = HOT_PARTICLE_PRESETS[style] or HOT_PARTICLE_PRESETS.default
    local liq = PALETTES.liquids[itemData.liquid]
    local cA, cB = particleColorsForStyle(style, liq.highlight)
    local burst = { x = x, y = y, life = preset.life, systems = {} }

    for _, cfg in ipairs(preset.systems) do
        local ps = love.graphics.newParticleSystem(FXTexture, 256)
        setParticleSystemFromPreset(ps, cfg)
        local hueJitter = randf(-0.08, 0.12)
        local satJitter = randf(0.9, 1.1)
        local function tint(c)
            return clamp((c[1] + hueJitter) * satJitter, 0, 1), clamp((c[2] + hueJitter * 0.4) * satJitter, 0, 1), clamp((c[3] - hueJitter * 0.3) * satJitter, 0, 1)
        end
        local a1, a2, a3 = tint(cA)
        local b1, b2, b3 = tint(cB)
        ps:setColors(
            a1, a2, a3, 0.92,
            b1, b2, b3, 0.75,
            b1, b2, b3, 0
        )
        ps:start()
        for _ = 1, (cfg.kickStartSteps or 0) do
            ps:update(cfg.kickStartDt or (1 / 60))
        end
        local emit = math.floor((cfg.emitAtStart or 0) * randf(0.75, 1.2) * Scene.consumeIntensity)
        ps:emit(emit)
        table.insert(burst.systems, { ps = ps, blendMode = cfg.blendMode or "alpha" })
    end

    burst.life = burst.life * randf(0.85, 1.25)
    table.insert(FXBursts, burst)
end

local function makeIdleFx(itemData)
    local liq = PALETTES.liquids[itemData.liquid]
    local ps = love.graphics.newParticleSystem(FXTexture, 96)
    ps:setDirection(-math.pi / 2)
    ps:setSpread(math.pi / 4)
    ps:setParticleLifetime(0.6, 1.35)
    ps:setSpeed(6, 20)
    ps:setLinearAcceleration(-8, -42, 8, -16)
    ps:setLinearDamping(0.2, 0.6)
    ps:setRadialAcceleration(-6, 6)
    ps:setTangentialAcceleration(-8, 8)
    ps:setSpin(-2, 2)
    ps:setSpinVariation(1.0)
    ps:setSizes(1.8, 0.8, 0.0)
    ps:setSizeVariation(0.4)
    ps:setEmitterLifetime(-1)
    ps:setEmissionRate(10 + itemData.rData.mult * 1.5 + Scene.rarityBias)
    ps:setColors(
        liq.highlight[1], liq.highlight[2], liq.highlight[3], 0.35,
        liq.highlight[1], liq.highlight[2], liq.highlight[3], 0.15,
        liq.highlight[1], liq.highlight[2], liq.highlight[3], 0
    )
    ps:start()
    return { ps = ps, blendMode = "add" }
end

local function triggerConsume(itemData)
    if Anim.isConsumed then return end
    Anim.isConsumed = true
    Anim.shake = 12 * Scene.consumeIntensity
    Anim.screenFlash = 1.0
    Anim.scaleX = randf(1.25, 1.55) * Scene.consumeIntensity
    Anim.scaleY = randf(0.55, 0.8)
    Anim.targetScale = 0.08
    Anim.itemAlpha = 1.0

    local liq = PALETTES.liquids[itemData.liquid]
    local arch = ITEM_ARCHETYPES[itemData.arch]
    local cX, cY = 400, 300

    -- Explosive Combat Text
    local val = math.floor(love.math.random(25, 100) * itemData.rData.mult)
    local textLabel = string.gsub(liq.text, "%+", "")
    table.insert(FloatingTexts, {
        x = cX, y = cY, targetY = cY - 80, 
        text = "+" .. val .. " " .. textLabel,
        color = liq.highlight, life = 2.5, scale = 0.1, pulse = 0
    })
    makeBurst(arch.particle, itemData, cX, cY)
    if itemData.rData.glow > 0.4 then
        makeBurst("magic", itemData, cX, cY)
    end
end

local function updateInteractions(dt)
    dt = math.min(dt, 1 / 30)
    -- Physics Spring for Squash & Stretch
    Anim.shake = math.max(0, Anim.shake - dt * (30 + 20 * Scene.motion))
    Anim.screenFlash = math.max(0, Anim.screenFlash - dt * (1.6 + Scene.motion))
    
    Anim.scaleX = lerp(Anim.scaleX, Anim.targetScale, dt * (7 + 4 * Scene.motion))
    Anim.scaleY = lerp(Anim.scaleY, Anim.targetScale, dt * (8 + 4 * Scene.motion))
    if Anim.isConsumed then
        Anim.itemAlpha = math.max(0, Anim.itemAlpha - dt * 2.4)
    else
        Anim.itemAlpha = lerp(Anim.itemAlpha, 1.0, dt * 10)
    end

    -- Combat Text Easing
    for i = #FloatingTexts, 1, -1 do
        local ft = FloatingTexts[i]
        ft.life = ft.life - dt
        ft.y = lerp(ft.y, ft.targetY, dt * 4.5)
        ft.scale = lerp(ft.scale, 1.0, dt * 7.5)
        ft.pulse = (ft.pulse or 0) + dt * 12
        if ft.life <= 0 then table.remove(FloatingTexts, i) end
    end

    if IdleFx then
        IdleFx.ps:update(dt)
    end

    for i = #FXBursts, 1, -1 do
        local burst = FXBursts[i]
        burst.life = burst.life - dt
        for _, layer in ipairs(burst.systems) do
            layer.ps:update(dt)
        end
        if burst.life <= 0 then
            table.remove(FXBursts, i)
        end
    end
end

--------------------------------------------------------------------------------
-- 4. GAME STATE & MAIN LOOP
--------------------------------------------------------------------------------
local renderScale = 4

local CONSUMABLE_ARCH_COMPAT_MAP = {
    med_syringe = "Injector",
    shield_cell = "RoundVial",
    stim_pack = "Can",
}

local RARITY_COMPAT_MAP = {
    scrap = "Scrap",
    common = "Common",
    uncommon = "Uncommon",
    rare = "Rare",
    epic = "Epic",
    legendary = "Legendary",
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

local function rollNewItem()
    FloatingTexts, FXBursts = {}, {}
    Scene = {
        motion = randf(0.75, 1.05),
        bgSpeed = randf(5, 12),
        bobSpeed = randf(1.2, 2.3),
        bobAmount = randf(4, 9),
        tilt = randf(0.08, 0.18),
        consumeIntensity = randf(0.8, 1.25),
        accent = {randf(0.15, 0.45), randf(0.25, 0.8), randf(0.45, 1.0)},
        rarityBias = love.math.random(-2, 4)
    }
    Anim = { shake = 0, scaleX = 0.15, scaleY = 1.7, targetScale = 1.0, isConsumed = false, screenFlash = 0, itemAlpha = 1.0 }
    if is_flag_enabled("enable_mte_consumable_gen") and has_consumable_adapter and type(ConsumableCompat.rollNewConsumable) == "function" then
        local compat, compat_err = ConsumableCompat.rollNewConsumable()
        if compat and compat.image then
            local meta = read_compat_meta(compat)
            local arch_key = tostring(meta.archetype or compat.arch or "med_syringe"):lower()
            local arch = CONSUMABLE_ARCH_COMPAT_MAP[arch_key] or "Injector"
            local type_def = ITEM_ARCHETYPES[arch] and ITEM_ARCHETYPES[arch].type or "Potion"
            local effect = tostring(meta.effect or compat.effect or "health"):lower()
            local liquid = PALETTES.liquids[effect] and effect or "health"
            local rarity_key = tostring(meta.rarity or compat.rarity or "common"):lower()
            local rarity = RARITY_COMPAT_MAP[rarity_key] or "Common"
            ActiveItem = {
                image = compat.image,
                w = normalize_dimension(compat.w, 24),
                h = normalize_dimension(compat.h, 32),
                arch = arch,
                liquid = liquid,
                rarity = rarity,
                rData = RARITIES[rarity] or RARITIES.Common,
                skin = meta.skin or "MTE",
                name = compat.name or (rarity .. " " .. arch),
                type = type_def,
            }
            IdleFx = makeIdleFx(ActiveItem)
            return
        end
        if compat_err then
            print("MTE consumable adapter failed; falling back to legacy generator: " .. tostring(compat_err))
        end
    end

    local archs = { "MRE", "Can", "AlienMeat", "EnergyCan", "Canteen", "Medkit", "Injector", "RoundVial", "TriFlask", "Scroll", "RuneStone" }
    local liquids = {"health", "health", "shield", "mana", "stamina", "toxin"}
    local rarities = {"Scrap", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
    
    local arch = archs[love.math.random(1, #archs)]
    local typeDef = ITEM_ARCHETYPES[arch].type
    
    local liquid = liquids[love.math.random(1, #liquids)]
    if typeDef == "Heal" then liquid = "health" end
    if typeDef == "Food" and love.math.random()>0.8 then liquid = "toxin" end
    if typeDef == "Spell" then liquid = (love.math.random()>0.5 and "mana" or "shield") end

    local rarityRoll = love.math.random(1, 100) + Scene.rarityBias
    local rarity = "Common"
    if rarityRoll <= 14 then rarity = "Scrap"
    elseif rarityRoll <= 50 then rarity = "Common"
    elseif rarityRoll <= 74 then rarity = "Uncommon"
    elseif rarityRoll <= 90 then rarity = "Rare"
    elseif rarityRoll <= 98 then rarity = "Epic"
    else rarity = "Legendary" end
    local data = generateItem(arch, rarity, liquid)

    ActiveItem = {
        image = data.img, w = data.w, h = data.h,
        arch = arch, liquid = liquid, rarity = rarity, rData = RARITIES[rarity], skin = data.skinName,
        name = string.format("%s %s", rarity, arch),
        type = typeDef
    }
    IdleFx = makeIdleFx(ActiveItem)
end

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    love.mouse.setVisible(false)
    FXTexture = makeFxPixelTexture()
    rollNewItem()
end

function love.keypressed(key)
    if key == "space" then rollNewItem() end
    if key == "escape" then love.event.quit() end
end

function love.mousemoved(x, y) MouseX, MouseY = x, y end

function love.mousepressed(x, y, button)
    if button == 1 then triggerConsume(ActiveItem) end
    if button == 2 then rollNewItem() end
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
    local gridScroll = (time * Scene.bgSpeed) % 40
    for x = 0, 800, 40 do love.graphics.line(x, 0, x, 600) end
    for y = 0, 600, 40 do love.graphics.line(0, y + gridScroll, 800, y + gridScroll) end
    love.graphics.setBlendMode("add", "alphamultiply")
    love.graphics.setColor(Scene.accent[1], Scene.accent[2], Scene.accent[3], 0.08)
    love.graphics.ellipse("fill", 400, 120, 300, 100)
    love.graphics.setBlendMode("alpha")
    
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
    local idleY = math.sin(time * Scene.bobSpeed) * Scene.bobAmount
    local mNormX = (MouseX - 400) / 400
    local tilt = mNormX * Scene.tilt
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

    love.graphics.setColor(1, 1, 1, Anim.itemAlpha)
    local sX = renderScale * Anim.scaleX
    local sY = renderScale * Anim.scaleY
    love.graphics.draw(ActiveItem.image, finalX, finalY, tilt, sX, sY, ActiveItem.w/2, ActiveItem.h/2)

    -- Ambient and burst particle systems (HotParticles export-style architecture)
    if IdleFx and not Anim.isConsumed then
        love.graphics.setBlendMode(IdleFx.blendMode, "alphamultiply")
        love.graphics.draw(IdleFx.ps, finalX, finalY + 14)
        love.graphics.setBlendMode("alpha")
    end
    for _, burst in ipairs(FXBursts) do
        for _, layer in ipairs(burst.systems) do
            love.graphics.setBlendMode(layer.blendMode, "alphamultiply")
            love.graphics.draw(layer.ps, burst.x, burst.y)
        end
        love.graphics.setBlendMode("alpha")
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
        local alpha = clamp(ft.life * 1.2, 0, 1)
        local wobble = math.sin(ft.pulse or 0) * 1.2
        love.graphics.push()
        love.graphics.translate(ft.x + wobble, ft.y)
        love.graphics.scale(ft.scale, ft.scale)
        -- Shadow
        love.graphics.setColor(0, 0, 0, alpha)
        love.graphics.print(ft.text, -20 + 2, 2, 0, 1.5, 1.5)
        -- Text
        love.graphics.setColor(ft.color[1], ft.color[2], ft.color[3], alpha)
        love.graphics.print(ft.text, -20, 0, 0, 1.5, 1.5)
        love.graphics.pop()
    end

    -- Custom Cursor
    local cx, cy = MouseX, MouseY
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.circle("line", cx, cy, 8)
    love.graphics.circle("fill", cx, cy, 2)
    love.graphics.setColor(ActiveItem.rData.color)
    love.graphics.circle("line", cx, cy, 4)
end