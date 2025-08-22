if not (settings.startup.em_dev_mode and settings.startup.em_dev_mode.value) then return end

data:extend{
  { type = "custom-input", name = "em-reload-mods", key_sequence = "SHIFT + PAGEDOWN", localised_name = "Reload Mods" },
  { type = "custom-input", name = "em-run-function", key_sequence = "SHIFT + PAGEUP", localised_name = "Run Function" }
}
