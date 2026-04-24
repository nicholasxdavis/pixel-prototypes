local MTE = require("mte")

local Compat = {}

function Compat.rollNewAmmo(opts)
  opts = opts or {}
  local archetype = opts.archetype or opts.kind or "light_round"
  local asset, err = MTE.random("ammo", {
    archetype = archetype,
    id = opts.id,
    seed = opts.seed,
    allow_placeholder = opts.allow_placeholder == true,
  })
  if not asset then
    return nil, err
  end

  local meta = type(asset.meta) == "table" and asset.meta or {}
  local resolved_arch = meta.archetype or archetype
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
    caliber = meta.caliber or nil,
    arch = resolved_arch,
    name = meta.label or "Ammo",
    box_image = meta.box_image or meta.boxImage or asset.image,
  }
end

return Compat
