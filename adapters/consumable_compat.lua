local MTE = require("mte")

local Compat = {}

local function title_case(input)
  return (input:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end))
end

function Compat.rollNewConsumable(opts)
  opts = opts or {}
  local archetype = opts.archetype or opts.arch
  local asset, err = MTE.random("consumable", {
    archetype = archetype,
    id = opts.id,
    seed = opts.seed,
    allow_placeholder = opts.allow_placeholder == true,
  })
  if not asset then
    return nil, err
  end

  local meta = type(asset.meta) == "table" and asset.meta or {}
  local resolved_arch = meta.archetype or archetype or "consumable"
  local stats = type(asset.stats) == "table" and asset.stats or {}
  local tags = type(asset.tags) == "table" and asset.tags or {}
  return {
    image = asset.image,
    w = asset.w,
    h = asset.h,
    anchors = asset.anchors,
    id = asset.id,
    kind = asset.kind,
    meta = meta,
    stats = stats,
    tags = tags,
    arch = resolved_arch,
    effect = (meta.effect or meta.effect_type) or nil,
    rarity = meta.rarity or nil,
    name = title_case((resolved_arch or "consumable"):gsub("_", " ")),
  }
end

return Compat
