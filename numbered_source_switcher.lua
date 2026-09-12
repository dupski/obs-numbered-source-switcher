-- Numbered Source Switcher for OBS Studio
--
-- This script cycles through scene items whose source names are whole numbers,
-- such as "1", "2", "3", and "4". It makes one numbered source visible at a
-- time and exposes Next and Previous hotkeys through OBS.
--
-- To use it, add the script in OBS under Tools > Scripts, name the sources in
-- the current scene with consecutive numbers, and configure the two hotkeys
-- under Settings > Hotkeys. Set ENABLE_CYCLING to true to wrap from the first
-- numbered source to the last, or from the last to the first.

obs = obslua

ENABLE_CYCLING = false

hotkey_next = obs.OBS_INVALID_HOTKEY_ID
hotkey_previous = obs.OBS_INVALID_HOTKEY_ID
hotkey_show_first = obs.OBS_INVALID_HOTKEY_ID
hotkey_hide = obs.OBS_INVALID_HOTKEY_ID
hotkey_show = obs.OBS_INVALID_HOTKEY_ID

last_shown_number = nil


-- Get all scene items whose source names are numbers
function get_numbered_items()
    local scene_source = obs.obs_frontend_get_current_scene()

    if scene_source == nil then
        return {}
    end

    local scene = obs.obs_scene_from_source(scene_source)
    local items = obs.obs_scene_enum_items(scene)

    local numbered = {}

    if items ~= nil then
        for _, item in ipairs(items) do
            local source = obs.obs_sceneitem_get_source(item)
            local name = obs.obs_source_get_name(source)

            local number = tonumber(name)

            if number ~= nil and tostring(math.floor(number)) == name then
                table.insert(numbered, {
                    number = number,
                    item = item
                })
            end
        end
    end

    -- Sort 1, 2, 3, 4... rather than alphabetically
    table.sort(numbered, function(a, b)
        return a.number < b.number
    end)

    obs.obs_source_release(scene_source)

    return numbered, items
end


function switch_source(direction)
    local numbered, items = get_numbered_items()

    if numbered == nil or #numbered == 0 then
        if items ~= nil then
            obs.sceneitem_list_release(items)
        end
        return
    end

    -- Find the currently visible numbered source
    local current_index = nil

    for i, entry in ipairs(numbered) do
        if obs.obs_sceneitem_visible(entry.item) then
            current_index = i
            break
        end
    end

    local target_index

    if current_index == nil then
        target_index = (direction > 0) and 1 or #numbered
    else
        target_index = current_index + direction

        if target_index > #numbered then
            if ENABLE_CYCLING then
                target_index = 1
            else
                if items ~= nil then
                    obs.sceneitem_list_release(items)
                end
                return
            end
        elseif target_index < 1 then
            if ENABLE_CYCLING then
                target_index = #numbered
            else
                if items ~= nil then
                    obs.sceneitem_list_release(items)
                end
                return
            end
        end
    end

    -- Make only the target source visible
    for i, entry in ipairs(numbered) do
        obs.obs_sceneitem_set_visible(entry.item, i == target_index)
    end

    last_shown_number = numbered[target_index].number

    if items ~= nil then
        obs.sceneitem_list_release(items)
    end
end


function show_first()
    local numbered, items = get_numbered_items()

    if numbered == nil or #numbered == 0 then
        if items ~= nil then
            obs.sceneitem_list_release(items)
        end
        return
    end

    for i, entry in ipairs(numbered) do
        obs.obs_sceneitem_set_visible(entry.item, i == 1)
    end

    last_shown_number = numbered[1].number

    if items ~= nil then
        obs.sceneitem_list_release(items)
    end
end


function hide_sources()
    local numbered, items = get_numbered_items()

    if numbered == nil or #numbered == 0 then
        if items ~= nil then
            obs.sceneitem_list_release(items)
        end
        return
    end

    for _, entry in ipairs(numbered) do
        if obs.obs_sceneitem_visible(entry.item) then
            last_shown_number = entry.number
            break
        end
    end

    for _, entry in ipairs(numbered) do
        obs.obs_sceneitem_set_visible(entry.item, false)
    end

    if items ~= nil then
        obs.sceneitem_list_release(items)
    end
end


function show_source()
    local numbered, items = get_numbered_items()

    if numbered == nil or #numbered == 0 then
        if items ~= nil then
            obs.sceneitem_list_release(items)
        end
        return
    end

    local target_index = 1

    if last_shown_number ~= nil then
        for i, entry in ipairs(numbered) do
            if entry.number == last_shown_number then
                target_index = i
                break
            end
        end
    end

    for i, entry in ipairs(numbered) do
        obs.obs_sceneitem_set_visible(entry.item, i == target_index)
    end

    last_shown_number = numbered[target_index].number

    if items ~= nil then
        obs.sceneitem_list_release(items)
    end
end


function next_hotkey(pressed)
    if pressed then
        switch_source(1)
    end
end


function previous_hotkey(pressed)
    if pressed then
        switch_source(-1)
    end
end


function show_first_hotkey(pressed)
    if pressed then
        show_first()
    end
end


function hide_hotkey(pressed)
    if pressed then
        hide_sources()
    end
end


function show_hotkey(pressed)
    if pressed then
        show_source()
    end
end


function script_description()
    return [[
Numbered Source Switcher

Switches between numbered sources in the current scene.

Name your sources:
1
2
3
4
etc.

Numbered Source hotkeys will cycle between them, hide all, or show the first one.
]]
end


function script_load(settings)
    hotkey_next = obs.obs_hotkey_register_frontend(
        "numbered_source_next",
        "Numbered Source: Next",
        next_hotkey
    )

    hotkey_previous = obs.obs_hotkey_register_frontend(
        "numbered_source_previous",
        "Numbered Source: Previous",
        previous_hotkey
    )

    hotkey_show_first = obs.obs_hotkey_register_frontend(
        "numbered_source_show_first",
        "Numbered Source: Show First",
        show_first_hotkey
    )

    hotkey_hide = obs.obs_hotkey_register_frontend(
        "numbered_source_hide",
        "Numbered Source: Hide",
        hide_hotkey
    )

    hotkey_show = obs.obs_hotkey_register_frontend(
        "numbered_source_show",
        "Numbered Source: Show",
        show_hotkey
    )

    local next_hotkey_save_array =
        obs.obs_data_get_array(settings, "numbered_source_next")

    obs.obs_hotkey_load(
        hotkey_next,
        next_hotkey_save_array
    )

    obs.obs_data_array_release(next_hotkey_save_array)


    local previous_hotkey_save_array =
        obs.obs_data_get_array(settings, "numbered_source_previous")

    obs.obs_hotkey_load(
        hotkey_previous,
        previous_hotkey_save_array
    )

    obs.obs_data_array_release(previous_hotkey_save_array)


    local show_first_hotkey_save_array =
        obs.obs_data_get_array(settings, "numbered_source_show_first")

    obs.obs_hotkey_load(
        hotkey_show_first,
        show_first_hotkey_save_array
    )

    obs.obs_data_array_release(show_first_hotkey_save_array)


    local hide_hotkey_save_array =
        obs.obs_data_get_array(settings, "numbered_source_hide")

    obs.obs_hotkey_load(
        hotkey_hide,
        hide_hotkey_save_array
    )

    obs.obs_data_array_release(hide_hotkey_save_array)


    local show_hotkey_save_array =
        obs.obs_data_get_array(settings, "numbered_source_show")

    obs.obs_hotkey_load(
        hotkey_show,
        show_hotkey_save_array
    )

    obs.obs_data_array_release(show_hotkey_save_array)
end


function script_save(settings)
    local next_hotkey_save_array =
        obs.obs_hotkey_save(hotkey_next)

    obs.obs_data_set_array(
        settings,
        "numbered_source_next",
        next_hotkey_save_array
    )

    obs.obs_data_array_release(next_hotkey_save_array)


    local previous_hotkey_save_array =
        obs.obs_hotkey_save(hotkey_previous)

    obs.obs_data_set_array(
        settings,
        "numbered_source_previous",
        previous_hotkey_save_array
    )

    obs.obs_data_array_release(previous_hotkey_save_array)


    local show_first_hotkey_save_array =
        obs.obs_hotkey_save(hotkey_show_first)

    obs.obs_data_set_array(
        settings,
        "numbered_source_show_first",
        show_first_hotkey_save_array
    )

    obs.obs_data_array_release(show_first_hotkey_save_array)


    local hide_hotkey_save_array =
        obs.obs_hotkey_save(hotkey_hide)

    obs.obs_data_set_array(
        settings,
        "numbered_source_hide",
        hide_hotkey_save_array
    )

    obs.obs_data_array_release(hide_hotkey_save_array)


    local show_hotkey_save_array =
        obs.obs_hotkey_save(hotkey_show)

    obs.obs_data_set_array(
        settings,
        "numbered_source_show",
        show_hotkey_save_array
    )

    obs.obs_data_array_release(show_hotkey_save_array)
end