local Utils = require("scripts/utils")
local Teleporter = require("scripts/teleporter")

if Utils.getStartupSetting("dev_mode") then
  commands.add_command("Teleport", "", function(command)
    local player = game.get_player(command.player_index)

    if not command.parameter then
      local random_city_name = storage.world.city_names[math.random(1, #storage.world.city_names)]
      return Teleporter.teleport(player, storage.world.cities[random_city_name], nil)
    end

    local city_name = Utils.titleCase(command.parameter)
    if storage.world.cities[city_name] then
      return Teleporter.teleport(player, storage.world.cities[city_name], nil)
    end

    if city_name == "All" then
      for _, target_city in pairs(storage.world.cities) do
        Teleporter.teleport(player, target_city, nil)
      end
      return
    end
    player.print("Invalid teleport target " .. command.parameter .. " no parameter for random teleport, or city name, or All")
  end)

  commands.add_command("ChartWorld", "", function(command)
    local mgs = storage.world.surface.map_gen_settings
    if not command.parameter then
      storage.world.force.chart(storage.world.surface, { { -mgs.width / 2, -mgs.height / 2 }, { mgs.width / 2, mgs.height / 2 } })
    else
      local ltq = { { -mgs.width / 2, -mgs.height / 2 }, { -1, -1 } }
      local lbq = { { -mgs.width / 2, 0 }, { -1, mgs.height / 2 - 1 } }
      local rtq = { { 0, -mgs.height / 2 }, { mgs.width / 2 - 1, -1 } }
      local rbq = { { 0, 0 }, { mgs.width / 2 - 1, mgs.height / 2 - 1 } }

      storage.world.force.chart(storage.world.surface, ltq)
      storage.world.force.chart(storage.world.surface, lbq)
      storage.world.force.chart(storage.world.surface, rtq)
      storage.world.force.chart(storage.world.surface, rbq)
    end
  end)
end

-------------------------------------------------------------------------------
