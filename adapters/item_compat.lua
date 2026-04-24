local MTE = require("mte")

local Compat = {}

local function title_case(input)
  return (input:gsub("(%a)([%w_']*)", function(first, rest)
    return first:upper() .. rest:lower()
  end))
end

function Compat.rollNewItem(opts)
  opts = opts or {}
  local archetype = opts.archetype or opts.arch
  local asset, err = MTE.random("item", {
    archetype = archetype,
    id = opts.id,
    seed = opts.seed,
    allow_placeholder = opts.allow_placeholder == true,
  })
  if not asset then
    return nil, err
  end

  local meta = type(asset.meta) == "table" and asset.meta or {}
  local resolved_arch = meta.archetype or archetype or "item"
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
    category = meta.category or nil,
    rarity = meta.rarity or nil,
    name = title_case((resolved_arch or "item"):gsub("_", " ")),
  }
end

return Compat
