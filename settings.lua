dofile("data/scripts/lib/mod_settings.lua") 

local mod_id = "da_bumpmap"
mod_settings_version = 1
mod_settings = {
	{
		id = "enable_bumpmapping",
		ui_name = "Enable Bump Mapping",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "cave_bump",
		ui_name = "Ambient Cave Bumpmapping",
		value_default = true,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "bump_strength",
		ui_name = "Bump Mapping Strength",
		value_default = 1.0,
		value_min = 0,
		value_max = 10,
		value_display_multiplier = 100,
		value_display_formatting = " $0%",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "bump_lightness",
		ui_name = "Bump Mapping Highlights",
		value_default = 1.0,
		value_min = 0,
		value_max = 10,
		value_display_multiplier = 100,
		value_display_formatting = " $0%",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "bump_darkness",
		ui_name = "Bump Mapping Shadows",
		value_default = 1.0,
		value_min = 0,
		value_max = 10,
		value_display_multiplier = 100,
		value_display_formatting = " $0%",
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
	{
		id = "debug_mode",
		ui_name = "Debug",
		value_default = 0,
		value_min = 0,
		value_max = 6,
		scope = MOD_SETTING_SCOPE_RUNTIME,
	},
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) 
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return mod_settings_gui_count( mod_id, mod_settings )
end

function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )
end
