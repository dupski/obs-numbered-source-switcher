-- Import Text Into Duplicates for OBS Studio
--
-- Splits a block of text into sections and spreads them across a numbered
-- sequence of duplicated Text sources in the current scene.
--
-- To use it, add the script under Tools > Scripts, select it in the script
-- list, then fill in the Source Name Prefix, Starting Number, and Text
-- fields shown in the panel and click Import. The prefix and starting
-- number together must name an existing Text source; a space is added
-- automatically between them (for example, prefix "Slide" and number 1
-- identify a source named "Slide 1"). Sections in the
-- text are separated by a line that contains only "---" (surrounding
-- whitespace on that line is fine). The first section replaces the text of
-- that source; each remaining section is placed on a duplicate of that
-- source, named with the next whole number, with the same position, size,
-- rotation, and crop as the original, but hidden.

obs = obslua

SEPARATOR_PATTERN = "^%s*%-%-%-%s*$"

g_settings = nil


-- Deliberately undefined; calling it raises an error so OBS surfaces its
-- Script Log window, since obslua has no message box function of its own.
function alert(props, message)
    local status_prop = obs.obs_properties_get(props, "status")

    if status_prop ~= nil then
        obs.obs_property_text_set_info_type(status_prop, obs.OBS_TEXT_INFO_ERROR)
        obs.obs_property_set_description(status_prop, message)
    end

    print("")
    print("----------------------------------------")
    print("ERROR: " .. message)
    print("----------------------------------------")
    print("")
    print("")
    force_popup_window()
    print("")
end


function build_source_name(prefix, number)
    if prefix == "" then
        return tostring(number)
    end

    return prefix .. " " .. tostring(number)
end


function set_source_text(source, text)
    local data = obs.obs_data_create()
    obs.obs_data_set_string(data, "text", text)
    obs.obs_source_update(source, data)
    obs.obs_data_release(data)
end


function copy_transform(from_item, to_item)
    local pos = obs.vec2()
    obs.obs_sceneitem_get_pos(from_item, pos)
    obs.obs_sceneitem_set_pos(to_item, pos)

    obs.obs_sceneitem_set_rot(to_item, obs.obs_sceneitem_get_rot(from_item))

    local scale = obs.vec2()
    obs.obs_sceneitem_get_scale(from_item, scale)
    obs.obs_sceneitem_set_scale(to_item, scale)

    obs.obs_sceneitem_set_alignment(to_item, obs.obs_sceneitem_get_alignment(from_item))
    obs.obs_sceneitem_set_bounds_type(to_item, obs.obs_sceneitem_get_bounds_type(from_item))

    local bounds = obs.vec2()
    obs.obs_sceneitem_get_bounds(from_item, bounds)
    obs.obs_sceneitem_set_bounds(to_item, bounds)

    obs.obs_sceneitem_set_bounds_alignment(to_item, obs.obs_sceneitem_get_bounds_alignment(from_item))

    local crop = obs.obs_sceneitem_crop()
    obs.obs_sceneitem_get_crop(from_item, crop)
    obs.obs_sceneitem_set_crop(to_item, crop)

    local show_transition = obs.obs_sceneitem_get_transition(from_item, true)
    if show_transition ~= nil then
        local show_transition_copy = obs.obs_source_duplicate(show_transition, obs.obs_source_get_name(show_transition), true)
        obs.obs_sceneitem_set_transition(to_item, true, show_transition_copy)
        obs.obs_source_release(show_transition_copy)
    end
    obs.obs_sceneitem_set_transition_duration(to_item, true, obs.obs_sceneitem_get_transition_duration(from_item, true))

    local hide_transition = obs.obs_sceneitem_get_transition(from_item, false)
    if hide_transition ~= nil then
        local hide_transition_copy = obs.obs_source_duplicate(hide_transition, obs.obs_source_get_name(hide_transition), true)
        obs.obs_sceneitem_set_transition(to_item, false, hide_transition_copy)
        obs.obs_source_release(hide_transition_copy)
    end
    obs.obs_sceneitem_set_transition_duration(to_item, false, obs.obs_sceneitem_get_transition_duration(from_item, false))
end


-- Split text on lines that contain only "---", trimming blank lines (not
-- spaces/tabs) from the start and end of each resulting section
function split_into_segments(text)
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")

    local segments = {}
    local current_lines = {}

    for line in (text .. "\n"):gmatch("(.-)\n") do
        if line:match(SEPARATOR_PATTERN) then
            table.insert(segments, current_lines)
            current_lines = {}
        else
            table.insert(current_lines, line)
        end
    end

    table.insert(segments, current_lines)

    local results = {}

    for _, lines in ipairs(segments) do
        while #lines > 0 and lines[1] == "" do
            table.remove(lines, 1)
        end

        while #lines > 0 and lines[#lines] == "" do
            table.remove(lines)
        end

        table.insert(results, table.concat(lines, "\n"))
    end

    return results
end


function do_import(props)
    local prefix = obs.obs_data_get_string(g_settings, "prefix")
    local start_number = obs.obs_data_get_int(g_settings, "start_number")
    local text = obs.obs_data_get_string(g_settings, "text")

    if text == nil or text:match("^%s*$") then
        alert(props, "Enter some text to import.")
        return false
    end

    local segments = split_into_segments(text)

    if #segments < 2 then
        alert(props, "Add at least one --- separator line to split the text into multiple sections.")
        return false
    end

    local names = {}

    for i = 1, #segments do
        names[i] = build_source_name(prefix, start_number + i - 1)
    end

    local scene_source = obs.obs_frontend_get_current_scene()

    if scene_source == nil then
        alert(props, "No active scene was found.")
        return false
    end

    local scene = obs.obs_scene_from_source(scene_source)
    local first_item = obs.obs_scene_find_source(scene, names[1])

    if first_item == nil then
        obs.obs_source_release(scene_source)
        alert(props, "No source named '" .. names[1] .. "' was found in the current scene.")
        return false
    end

    local first_source = obs.obs_sceneitem_get_source(first_item)
    local source_id = obs.obs_source_get_id(first_source)

    if source_id ~= "text_gdiplus_source" and source_id ~= "text_gdiplus_v3" and source_id ~= "text_ft2_source" then
        obs.obs_source_release(scene_source)
        alert(props, "'" .. names[1] .. "' is not a Text source (it is a '" .. source_id .. "').")
        return false
    end

    for i = 2, #segments do
        local existing_source = obs.obs_get_source_by_name(names[i])

        if existing_source ~= nil then
            obs.obs_source_release(existing_source)
            obs.obs_source_release(scene_source)
            alert(props, "A source named '" .. names[i] .. "' already exists. Choose a different prefix or starting number.")
            return false
        end
    end

    set_source_text(first_source, segments[1])

    local all_items = { first_item }

    for i = 2, #segments do
        local new_source = obs.obs_source_duplicate(first_source, names[i], false)
        set_source_text(new_source, segments[i])

        local new_item = obs.obs_scene_add(scene, new_source)
        copy_transform(first_item, new_item)
        obs.obs_sceneitem_set_visible(new_item, false)
        table.insert(all_items, new_item)

        obs.obs_source_release(new_source)
    end

    -- Assign final positions bottom-to-top in one pass, since a higher
    -- order position appears further up the Sources list
    for i = #all_items, 1, -1 do
        obs.obs_sceneitem_set_order_position(all_items[i], #all_items - i)
    end

    obs.obs_source_release(scene_source)

    local message = "Imported " .. #segments .. " text segments."
    local status_prop = obs.obs_properties_get(props, "status")

    obs.obs_property_text_set_info_type(status_prop, obs.OBS_TEXT_INFO_NORMAL)
    obs.obs_property_set_description(status_prop, message)
    print(message)

    return true
end


function on_import_clicked(props, property)
    return do_import(props)
end


function script_description()
    return [[
Duplicate Text Source and Import Text

Duplicates a text source and imports blocks of text into each duplicate from the text provided below.

Use "---" on its own line to separate the text to be imported into each duplicate.
]]
end


function script_defaults(settings)
    obs.obs_data_set_default_string(settings, "prefix", "")
    obs.obs_data_set_default_int(settings, "start_number", 1)
end


function script_update(settings)
    g_settings = settings
end


function script_properties()
    local props = obs.obs_properties_create()

    obs.obs_properties_add_text(props, "prefix", "Source Name Prefix", obs.OBS_TEXT_DEFAULT)
    obs.obs_properties_add_int(props, "start_number", "Starting Number", 0, 1000000, 1)
    obs.obs_properties_add_text(props, "text", "Text to Import", obs.OBS_TEXT_MULTILINE)
    obs.obs_properties_add_text(props, "status", "", obs.OBS_TEXT_INFO)
    obs.obs_properties_add_button(props, "import_button", "Import", on_import_clicked)

    return props
end
