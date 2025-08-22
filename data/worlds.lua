
if __DebugAdapter and __DebugAdapter.dumpIgnore then
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_atlantic.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_pacific.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_olde_world.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_americas.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_africa.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_europe.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_oceania.lua")
  __DebugAdapter.dumpIgnore("@__EarthMaps__/data/world_united_states.lua")
end

local Config = require("config")
local Utils = require("scripts/utils")

local debug_ignore = { __debugline = "Compressed Map Data", __debugchildren = false }

local Worlds = {
  ["Earth - Africa"] = {
    data = setmetatable(require("data/world_africa"), debug_ignore),
    cities = require("data/cities_africa"),
    settings = { spawn = "em_spawn_city_africa", silo = "em_silo_city_africa" }
  },
  ["Earth - Americas"] = {
    data = setmetatable(require("data/world_americas"), debug_ignore),
    cities = require("data/cities_americas"),
    settings = { spawn = "em_spawn_city_americas", silo = "em_silo_city_americas" }
  },
  ["Earth - Atlantic"] = {
    data = setmetatable(require("data/world_atlantic"), debug_ignore),
    cities = require("data/cities_atlantic"),
    settings = { spawn = "em_spawn_city_atlantic", silo = "em_silo_city_atlantic" }
  },
  ["Earth - Europe"] = {
    data = setmetatable(require("data/world_europe"), debug_ignore),
    cities = require("data/cities_europe"),
    settings = { spawn = "em_spawn_city_europe", silo = "em_silo_city_europe" }
  },
  ["Earth - Oceania"] = {
    data = setmetatable(require("data/world_oceania"), debug_ignore),
    cities = require("data/cities_oceania"),
    settings = { spawn = "em_spawn_city_oceania", silo = "em_silo_city_oceania" }
  },
  ["Earth - Olde World"] = {
    data = setmetatable(require("data/world_olde_world"), debug_ignore),
    cities = require("data/cities_olde_world"),
    settings = { spawn = "em_spawn_city_olde_world", silo = "em_silo_city_olde_world" }
  },
  ["Earth - Pacific"] = {
    data = setmetatable(require("data/world_pacific"), debug_ignore),
    cities = require("data/cities_pacific"),
    settings = { spawn = "em_spawn_city_pacific", silo = "em_silo_city_pacific" }
  },
  ["Earth - United States"] = {
    data = setmetatable(require("data/world_united_states"), debug_ignore),
    cities = require("data/cities_united_states"),
    settings = { spawn = "em_spawn_city_united_states", silo = "em_silo_city_united_states" }
  }
}

--- Crete a list of city_names for settings
--- Add name and full name to the cities
for _, world in pairs( Worlds ) do
  world.city_names = { Config.RANDOM_CITY }
  for full_name, city in pairs( world.cities ) do
    table.insert( world.city_names, full_name )
    city.full_name = full_name
    city.name = Utils.parseCityName( full_name )
  end
end

return Worlds
