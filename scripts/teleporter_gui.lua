
local TeleporterGUI = {}

local Config = require("config")
local Utils = require("scripts/utils")
local Teleporter = require("scripts/teleporter")

local format_number = Utils.factorio.format_number

local MAIN_FRAME_NAME = "em_teleporter_gui"
local EMPTY_SPRITE = "em_empty_sprite"
-- local CURRENT_CITY_SPRITE = "virtual-signal/signal-anything"
local CURRENT_CITY_SPRITE = "virtual-signal/signal-star"
-- graphics/icons/signal/signal-star.png
local EMPTY_SPRITE_BUTTON = { 
  type = "sprite", 
  sprite = "em_empty_sprite", 
  enabled = false 
}
local HIDDEN_CITY_BUTTON = {
  type    = "sprite-button",
  sprite  = "em_empty_sprite",
  enabled = false,
  style   = "slot_button",
  tooltip = { "em-teleporter-gui.not-charted-tooltip" }
}
-- =============================================================================

---@param player LuaPlayer
---@return LuaGuiElement
local function destroy_teleporter_gui(player)
  local screen = player.gui.screen
  if screen[MAIN_FRAME_NAME] then
    screen[MAIN_FRAME_NAME].destroy()
  end
  local pdata = storage.players[player.index]
  pdata.grid = nil
  pdata.current_teleporter = nil
  return screen
end

-------------------------------------------------------------------------------

---@param destinations_frame LuaGuiElement
---@param opened_teleporter LuaEntity
---@return LuaGuiElement
local function buildGrid( destinations_frame, opened_teleporter )
  local pane = destinations_frame.add({
    type = "scroll-pane",
    horizontal_scroll_policy = "dont-show-but-allow-scrolling",
    vertical_scroll_policy = "dont-show-but-allow-scrolling"
  })

  local button_table = pane.add({
    type = "table",
    name = "button_table",
    column_count = 20,
    style = "filter_slot_table",
    tooltip = {"em-teleporter-gui.title"}
  })

  local grid            = storage.world.gui_grid
  local teleporter      = storage.teleporters[opened_teleporter.unit_number]
  local requires_energy = storage.settings.startup.em_source_teleporters_require_power.value

  for row = 1, 10 do
    for column = 1, 20 do
      local city = grid[column] and grid[column][row]
      if city and city.charted and city.teleporter and city.teleporter.valid then
        local is_current_city = city.teleporter == teleporter
        local sprite = "virtual-signal/signal-" .. city.name:sub(1, 1)
        local distance = math.floor( Utils.positionDistance(teleporter.position, city.teleporter.position) / 32 )
        local required_energy = requires_energy and math.min( Config.TP_ENERGY_PER_CHUNK * distance, Config.TP_MAX_ENERGY ) or 0
        local required_energy_watts = format_number(required_energy * 60, true)
        local available_energy = format_number(teleporter.energy * 60, true)
        local enabled = not is_current_city
        local tooltip = { "em-teleporter-gui.target-tooltip", city.full_name, available_energy, required_energy_watts }

        local tags = {
          city_name         = city.name,
          current_city_name = teleporter.city.name,
          required_energy   = required_energy,
          required_energy_watts = required_energy_watts,
          full_name         = city.full_name,
          enabled_sprite    = sprite
        }

        button_table.add {
          name    = "em_tpb_" .. city.name,
          type    = "sprite-button",
          tooltip = tooltip,
          sprite  = (is_current_city and CURRENT_CITY_SPRITE) or (enabled and sprite) or 'em_empty_sprite',
          style   = "slot_button",
          tags    = tags,
          enabled = enabled
        }
      else
        if city and city.teleporter then
          button_table.add(HIDDEN_CITY_BUTTON)
        else
          button_table.add(EMPTY_SPRITE_BUTTON).style.size = 32
        end
      end
    end
  end
  return button_table
end

-------------------------------------------------------------------------------

---@param main_frame LuaGuiElement
---@param teleporter? LuaEntity
local function buildFooter(main_frame, teleporter)
  local city = teleporter and storage.teleporters[teleporter.unit_number] and storage.teleporters[teleporter.unit_number].city
  if not city then return end
  return main_frame.add {
    type = "label",
    caption = "Current City: " .. city.full_name,
  }
end

-------------------------------------------------------------------------------

local function create_main_frame( event )
  local power_required = storage.settings.startup.em_source_teleporters_require_power.value
  local player = game.get_player(event.player_index)
  local screen = destroy_teleporter_gui(player)

  if power_required and event.entity and event.entity.energy <= 0 then
    player.opened = defines.gui_type.none
    Utils.showFailMessage( player, event.entity.position, {"em-teleporter-gui.no-power"} )
    return
  end

  local pdata = storage.players[event.player_index]

  local main_frame = screen.add {
    type = "frame",
    name = MAIN_FRAME_NAME,
    direction = "vertical",
  }
  main_frame.auto_center = true

  -- Header flow
  local header_flow = main_frame.add {
    type = "flow",
    direction = "horizontal",
  }.add {
    type = "label",
    style = "frame_title",
    ignored_by_interaction = true,
    caption = { "em-teleporter-gui.title" }
  }.parent.add {
    type = "empty-widget",
    ignored_by_interaction = true,
    style = "em_titlebar_drag_handle"
  }.parent.add {
    name = MAIN_FRAME_NAME .. "_close",
    type = "sprite-button",
    style = "frame_action_button",
    hovered_sprite = "utility/close_black",
    clicked_sprite = "utility/close_black",
    sprite = "utility/close",
  }.parent
  header_flow.drag_target = main_frame

  -- Inner Frame
  local inner_frame = main_frame.add {
    type = "frame",
    name = "em_destinations_frame",
    direction = "vertical",
    style = "inside_shallow_frame_with_padding"
  }

  pdata.grid = buildGrid(inner_frame, event.entity)
  buildFooter(main_frame, event.entity)
  pdata.current_teleporter = event.entity
  player.opened = main_frame
  return main_frame
end

-- =============================================================================

function TeleporterGUI.onGuiOpened(event)
  if storage.world.cities_to_generate > 0 then -- this is a support check in case a city position is outside the boundary of the world.
    error( "! Not all cities were generated." )
  end

  if event.gui_type == defines.gui_type.entity and event.entity and event.entity.name == Config.TELEPORTER then
    return create_main_frame(event)
  end
end

-------------------------------------------------------------------------------

function TeleporterGUI.onGuiClosed(event)
  if event.gui_type ~= defines.gui_type.custom then return end
  local player = game.get_player(event.player_index)
  destroy_teleporter_gui(player)
  return true
end

-------------------------------------------------------------------------------

function TeleporterGUI.onGuiClick( event )
  local player = game.get_player( event.player_index )
  if event.element.name == "em_teleporter_gui_close" then
    return destroy_teleporter_gui( player )
  elseif string.sub( event.element.name, 1, 7 ) == "em_tpb_" then
    local tags = event.element.tags

    local target_city = storage.world.cities[tags.city_name]
    if not target_city then
      return destroy_teleporter_gui( player )
    end

    local current_city = storage.world.cities[tags.current_city_name] or {}
    if not settings.global.em_teleporting_enabled.value then
      Utils.showFailMessage( player, player.position, {"em-teleporter-gui.teleporting-disabled"} )
      return destroy_teleporter_gui( player )
    end

    local dest_power_required = storage.settings.startup.em_dest_teleporters_require_power.value
    local dest_power = target_city.teleporter.energy
    if dest_power_required and dest_power <= 0 then
      Utils.showFailMessage( player, player.position, {"em-teleporter-gui.target-not-powered"} )
      return destroy_teleporter_gui( player )
    end

    if current_city.teleporter.energy >= tags.required_energy then
      Teleporter.teleport(player, target_city, current_city.teleporter, tags.required_energy)
    else
      Utils.showFailMessage( player, player.position, {"em-teleporter-gui.not-enough-power"} )
    end

    return destroy_teleporter_gui( player )
  end
end


-------------------------------------------------------------------------------

function TeleporterGUI.onNthTick()
  for _, pdata in pairs(storage.players) do
    local grid = pdata.grid
    if not grid then return end
    local player = game.get_player(pdata.index)
    local teleporter = pdata.current_teleporter
    if not (grid.valid and teleporter and teleporter.valid and player.can_reach_entity(teleporter)) then
      return destroy_teleporter_gui(player) and nil
    end

    local teleporter_city = storage.teleporters[teleporter.unit_number].city
    local available_energy = format_number(teleporter.energy * 60, true)
    for _, button in pairs(pdata.grid.children) do
      local tags = button.tags
      if tags and tags.required_energy then
        local is_current_city = teleporter_city.name == tags.city_name
        local enabled = not is_current_city

        button.tooltip = { "em-teleporter-gui.target-tooltip", tags.full_name, available_energy, tags.required_energy_watts }
        button.enabled = enabled
        button.sprite = (is_current_city and CURRENT_CITY_SPRITE) or (enabled and tags.enabled_sprite) or EMPTY_SPRITE
      end
    end
  end
end

-- =============================================================================

return TeleporterGUI
