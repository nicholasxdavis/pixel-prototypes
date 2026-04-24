local MTE = require("mte")

local Compat = {}

local function titleCase(input)
    return (input:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

function Compat.rollNewWeapon(opts)
    opts = opts or {}
    local archetype = opts.archetype or opts.arch
    local weapon, err = MTE.random("weapon", {
        archetype = archetype,
        id = opts.id,
        seed = opts.seed,
        allow_placeholder = opts.allow_placeholder == true,
    })
    if not weapon then
        return nil, err
    end

    local meta = type(weapon.meta) == "table" and weapon.meta or {}
    local resolved_arch = meta.archetype or archetype or "weapon"
    local stats = type(weapon.stats) == "table" and weapon.stats or {}
    local tags = type(weapon.tags) == "table" and weapon.tags or {}
    local anchors = type(weapon.anchors) == "table" and weapon.anchors or {}

    -- Backward-compatible facade for older prototype callers.
    return {
        image = weapon.image,
        w = weapon.w,
        h = weapon.h,
        anchors = anchors,
        arch = resolved_arch,
        kind = weapon.kind,
        id = weapon.id,
        meta = meta,
        stats = stats,
        tags = tags,
        name = titleCase((resolved_arch or "weapon"):gsub("_", " ")),
    }
end

return Compat
