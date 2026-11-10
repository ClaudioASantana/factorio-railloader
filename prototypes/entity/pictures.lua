local M = {}

local function flatten(ts)
  local out = {}
  for _, t in ipairs(ts) do
    for _, elem in ipairs(t) do
      out[#out+1] = elem
    end
  end
  return out
end

local base_straight_rail_pictures = data.raw["straight-rail"]["straight-rail"].pictures

local function triple_rail_pictures(direction, layers)
  local dir_key = (direction == "horizontal") and "east" or "north"
  local rail_pics = base_straight_rail_pictures and base_straight_rail_pictures[dir_key]
  local out = {}
  if not rail_pics then
    return out
  end
  for _, layer in ipairs(layers) do
    local l = rail_pics[layer]
    if l then
      for i=-1,1 do
        local shift = { i * 2, 0 }
        if direction == "vertical" then
          shift = { 0, i * 2 }
        end
        local l_shift = l.shift or {0, 0}

        out[#out+1] = {
          filename = l.filename,
          width = l.width,
          height = l.height,
          x = l.x,
          y = l.y,
          frame_count = 1,
          shift = { l_shift[1] + shift[1], l_shift[2] + shift[2] },
          scale = l.scale or 0.5,
          priority = l.priority or "extra-high",
          flags = l.flags,
        }
      end
    end
  end
  return out
end

local all_layers = {"stone_path_background", "stone_path", "ties", "backplates", "metals"}
local rail_only_layers = {"backplates", "metals"}

local cargo_wagon = data.raw["cargo-wagon"]["cargo-wagon"]
local wheels_layer = cargo_wagon.wheels and (cargo_wagon.wheels.rotated or cargo_wagon.wheels)
local wagon_layer = cargo_wagon.pictures and (
  (cargo_wagon.pictures.rotated and cargo_wagon.pictures.rotated.layers and cargo_wagon.pictures.rotated.layers[1])
  or (cargo_wagon.pictures.layers and cargo_wagon.pictures.layers[1])
)

local cargo_wagon_layers = {
  horizontal = {
    -- left wheel
    {
      filename = wheels_layer.filenames and wheels_layer.filenames[3] or wheels_layer.filename,
      width = wheels_layer.width,
      height = wheels_layer.height,
      frame_count = 1,
      shift = {-2, -0.25},
      scale = wheels_layer.scale or 0.5,
    },
    -- right wheel
    {
      filename = wheels_layer.filenames and wheels_layer.filenames[7] or wheels_layer.filename,
      width = wheels_layer.width,
      height = wheels_layer.height,
      frame_count = 1,
      shift = {2, -0.25},
      scale = wheels_layer.scale or 0.5,
    },
    -- wagon body
    {
      filename = wagon_layer.filenames and wagon_layer.filenames[3] or wagon_layer.filename,
      width = wagon_layer.width,
      height = wagon_layer.height,
      frame_count = 1,
      shift = wagon_layer.shift or {0, -25/32},
      scale = wagon_layer.scale or 0.5,
    },
  },
  vertical = {
    {
      filename = wheels_layer.filenames and wheels_layer.filenames[1] or wheels_layer.filename,
      width = wheels_layer.width,
      height = wheels_layer.height,
      frame_count = 1,
      shift = {0, 2.5},
      scale = wheels_layer.scale or 0.5,
    },
    {
      filename = wagon_layer.filenames and wagon_layer.filenames[1] or wagon_layer.filename,
      width = wagon_layer.width,
      height = wagon_layer.height,
      frame_count = 1,
      shift = {0, 0},
      scale = wagon_layer.scale or 0.5,
    }
  },
}

M.railloader_structure_horizontal = {
  filename = "__railloader__/graphics/railloader/structure-horizontal.png",
  priority = "extra-high",
  width = 188,
  height = 210,
  frame_count = 1,
}

M.railloader_structure_vertical = {
  filename = "__railloader__/graphics/railloader/structure-vertical.png",
  priority = "extra-high",
  width = 188,
  height = 210,
  frame_count = 1,
}

local railloader_horizontal = {
  layers = flatten{
    triple_rail_pictures("horizontal", all_layers),
    cargo_wagon_layers.horizontal,
    { M.railloader_structure_horizontal },
  }
}

local railloader_vertical = {
  layers = flatten{
    triple_rail_pictures("vertical", all_layers),
    cargo_wagon_layers.vertical,
    { M.railloader_structure_vertical },
  }
}

M.railloader_proxy_animations = {
  north = railloader_vertical,
  east = railloader_horizontal,
  south = railloader_vertical,
  west = railloader_horizontal,
}

M.railunloader_horizontal = {
  layers = flatten{
    {
      {
        filename = "__railloader__/graphics/railunloader/structure-horizontal.png",
        width = 384,
        height = 256,
        frame_count = 1,
        scale = 0.5,
      }
    },
    triple_rail_pictures("horizontal", rail_only_layers),
  }
}

M.railunloader_vertical = {
  layers = flatten{
    {
      {
        filename = "__railloader__/graphics/railunloader/structure-vertical.png",
        width = 256,
        height = 384,
        frame_count = 1,
        scale = 0.5,
      }
    },
    triple_rail_pictures("vertical", rail_only_layers),
  }
}

local railunloader_proxy_horizontal = {
  layers = flatten{
    M.railunloader_horizontal.layers,
    cargo_wagon_layers.horizontal,
  }
}

local railunloader_proxy_vertical = {
  layers = flatten{
    M.railunloader_vertical.layers,
    cargo_wagon_layers.vertical,
  }
}

M.railunloader_proxy_animations = {
  north = railunloader_proxy_vertical,
  east = railunloader_proxy_horizontal,
  south = railunloader_proxy_vertical,
  west = railunloader_proxy_horizontal,
}

M.empty_sheet = util.empty_sprite()
M.empty_animation = util.empty_animation()

return M