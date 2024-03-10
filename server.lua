--- Vehicle bounce mode.
-- @script server/main.lua

--- @section Variables
local active_bounce_modes = {}

--- @section Local functions

--- Retrieves all players within a certain range of a point or a player.
-- @param coords_or_source Either the coordinates or a player identifier to define the center point.
-- @param range The range within which to find players.
-- @param include_source Whether to include the player (if coords_or_source is a player identifier) in the result.
-- @return A table of player identifiers within the specified range.
-- @usage local players_in_range = utils.scope.get_players_in_range(coords_or_source, range, include_source)
local function get_players_in_range(coords_or_source, range, include_source)
    local players_in_range = {}
    local source_coords
    if type(coords_or_source) == 'number' then
        source_coords = GetEntityCoords(GetPlayerPed(coords_or_source))
    else
        source_coords = coords_or_source
    end
    local players = GetPlayers()
    for _, player_id in ipairs(players) do
        local ped_coords = GetEntityCoords(GetPlayerPed(player_id))
        local distance = #(source_coords - ped_coords)
        if distance <= range then
            if player_id ~= coords_or_source or include_source then
                players_in_range[#players_in_range + 1] = player_id
            end
        end
    end
    return players_in_range
end

--- @section Events

--- Server event to stop bouncing vehicles
RegisterServerEvent('vehicle_bouncemode:sv:stop_bounce', function()
    local _src = source
    local vehicle = GetVehiclePedIsIn(GetPlayerPed(_src), false)
    if vehicle and vehicle ~= 0 then
        local veh_netid = NetworkGetNetworkIdFromEntity(vehicle)
        if active_bounce_modes[veh_netid] then
            active_bounce_modes[veh_netid] = nil
            --scope.trigger_scope_event('vehicle_bouncemode:cl:start_bounce', _src, veh_netid, false)
            local players_in_range = get_players_in_range(_src, 50.0, true)
            for _, players in ipairs(players_in_range) do
                TriggerClientEvent('vehicle_bouncemode:cl:start_bounce', players)
            end
        end
    end
end)

--- @section Commands

--- Registers command to toggle vehicle bounce.
RegisterCommand('veh_bounce', function(source, args, raw)
    local player = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(player, false)
    if vehicle and vehicle ~= 0 then
        local veh_netid = NetworkGetNetworkIdFromEntity(vehicle)
        local is_bounce_mode_active = not active_bounce_modes[veh_netid]
        active_bounce_modes[veh_netid] = is_bounce_mode_active
        --scope.trigger_scope_event('vehicle_bouncemode:cl:start_bounce', source, veh_netid, is_bounce_mode_active)
        local players_in_range = get_players_in_range(source, 50.0, true)
        for _, players in ipairs(players_in_range) do
            TriggerClientEvent('vehicle_bouncemode:cl:start_bounce', players)
        end
    end
end)
