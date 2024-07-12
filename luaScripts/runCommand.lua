--[[
      OBS Studio Lua script : ZoomCuts with hotkeys
      Author: Jonathan Wood
      Version: 0.1
      Released: 2024-06-26
      references: https://obsproject.com/forum/resources/hotkeyrotate.723/, https://obsproject.com/forum/threads/command-runner.127662/
--]]

local obs = obslua

local debug
source_name = ""
result_name = ""
--uvcUtil_Location = ""

output = ""

-- if you are extending the script, you can add more hotkeys here
-- then add actions in the 'onHotKey' function further below
-- OBS HotKey codes https://github.com/obsproject/obs-studio/blob/master/libobs/obs-hotkeys.h
local hotkeys = {
    {id = "RUN_ZoomCuts", description = "Run a ZoomCuts command", HK = '{"RUN_ZoomCuts": [ { "key": "OBS_KEY_F1", "control": false, "alt": false, "shift": false, "command": true } ]}'},
--	{id = "STOP_uvcUtil", description = "Stop getting Camera 1 USB PTZ values", HK = '{"STOP_uvcUtil": [ { "key": "OBS_KEY_F1", "control": false, "alt": false, "shift": false, "command": false  } ]}'},
}

--Run the command and return its output
function os.capture(cmd)
    local f = assert(io.popen(cmd, 'r'))
    local s = assert(f:read('*a'))
    f:close()
    return s
end

function run_command()
    --Run a ZoomCuts command
    --get source text
    local source = obs.obs_get_source_by_name(source_name)
    if source ~= nil then
        local settings = obs.obs_data_create()
        settings = obs.obs_source_get_settings(source)
        command = obs.obs_data_get_string(settings, "text")
        obs.obs_data_release(settings)
        obs.obs_source_release(source)
    end
    obs.script_log(obs.LOG_INFO, "Executing command: " .. command)
    output = os.capture(command)
    obs.script_log(obs.LOG_INFO, "Output: " .. output)
    set_result_text()
   return
end

function set_result_text()
    local result = obs.obs_get_source_by_name(result_name)
    local settings = obs.obs_data_create()
    obs.obs_data_set_string(settings, "text", output)
    obs.obs_source_update(result, settings)
    obs.obs_data_release(settings)
    obs.obs_source_release(result)
    --script_load() 
    return
end

-- add any custom actions here
local function onHotKey(action)
    obs.script_log(obs.LOG_INFO,"hotkey pressed")
	--obs.timer_remove(run_command)
	if debug then obs.script_log(obs.LOG_INFO, string.format("Hotkey : %s", action)) end
	obs.script_log(obs.LOG_INFO, string.format("Hotkey : %s", action))
	if action == "RUN_ZoomCuts" then
		--direction = 1
		run_command()
	end
 return
end

----------------------------------------------------------
-- Script start up
----------------

function script_load()
    --obs.script_log(obs.LOG_INFO, OBS_KEY_2)
    --load hotkeys
	for _, v in pairs(hotkeys) do
        jsonHK = obs.obs_data_create_from_json(v.HK)
		hk = obs.obs_hotkey_register_frontend(v.id, v.description, function(pressed) if pressed then onHotKey(v.id) end end)
		local hotkeyArray = obs.obs_data_get_array(jsonHK, v.id)
		obs.obs_hotkey_load(hk, hotkeyArray)
		obs.obs_data_array_release(hotkeyArray)
        obs.obs_data_release(jsonHK)
	end
end

-- called when settings changed
function script_update(settings)
    --uvcUtil_Location = obs.obs_data_get_string(settings, "uvcUtil_Location") 
    source_name = obs.obs_data_get_string(settings, "source_name")
    result_name = obs.obs_data_get_string(settings, "result_name")
    obs.script_log(obs.LOG_INFO,"settings loaded")
	--interval = obs.obs_data_get_int(settings, "interval")
end

-- return description shown to user
function script_description()
	return "Run a ZoomCuts command"
end

-- define properties that user can change
function script_properties()
	local props = obs.obs_properties_create()
    --uvc-util location
    --obs.obs_properties_add_text(props, "output", "Output from ZoomCuts", obs.OBS_TEXT_DEFAULT)
    --list of text sources
    local property_list = obs.obs_properties_add_list(props, "source_name", "Select a Text Source to store ZoomCuts command", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
            source_id = obs.obs_source_get_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" or source_id == "text_ft2_source_v2" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(property_list, name, name)
			end
		end
	end
	obs.source_list_release(sources)

    local property_list = obs.obs_properties_add_list(props, "result_name", "Select a Text Source to store ZoomCuts results", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local results = obs.obs_enum_sources()
	if results ~= nil then
		for _, result in ipairs(results) do
            result_id = obs.obs_source_get_id(result)
			if result_id == "text_gdiplus" or result_id == "text_ft2_source" or result_id == "text_ft2_source_v2" then
				local resultName = obs.obs_source_get_name(result)
				obs.obs_property_list_add_string(property_list, resultName, resultName)
			end
		end
	end
	obs.source_list_release(results)

    --refresh interval
	--obs.obs_properties_add_int(props, "interval", "Refresh Interval (ms)", 2, 60000, 1)
	--debug option
    obs.obs_properties_add_bool(props, "debug", "Debug")
	return props
end

function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "source", "")
    obs.obs_data_set_default_string(settings, "result", "")
	--obs.obs_data_set_default_int(settings, "interval", 1000)
end
