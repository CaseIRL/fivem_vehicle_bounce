--- Vehicle bounce mode.
-- @script client/main.lua

--- @section Variables 

local is_bounce_mode_active = false
local bounce_height = 0.0
local original_height = {}
local bounce_time = 0
local radius = 50.0
local affect_vehicles_in_range = true
local allowed_vehicle_types = { 0, 1, 2, 3, 4, 5, 6, 7 }
local enable_headlights = true 

--- Enumerate all vehicles
-- @return coroutine wrapping the vehicle enumeration
local function enumerate_vehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end

--- Check if a table contains a value
-- @param table table: the table to check
-- @param element any: the element to look for
-- @return boolean: true if element is in table, false otherwise
local function table_contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

--- Get vehicles in radius of player
-- @param coords table: coordinates of the center
-- @param radius number: radius to search within
-- @return table: list of vehicles within radius
local function get_vehicles_in_radius(coords, radius)
    local vehicles = {}
    for vehicle in enumerate_vehicles() do
        if Vdist(coords.x, coords.y, coords.z, GetEntityCoords(vehicle)) < radius then
            vehicles[#vehicles + 1] = vehicle
        end
    end
    return vehicles
end

--- Toggle bounce for multiple vehicles
-- @param vehicles table: list of vehicles to toggle bounce for
local function toggle_for_multiple_vehicles(vehicles)
    is_bounce_mode_active = not is_bounce_mode_active
    bounce_time = GetGameTimer()
    for _, vehicle in ipairs(vehicles) do
        local vehicle_type = GetVehicleClass(vehicle)
        if table_contains(allowed_vehicle_types, vehicle_type) then
            if is_bounce_mode_active then
                original_height[vehicle] = GetVehicleSuspensionHeight(vehicle)
                SetVehicleLights(vehicle, 2)
                SetVehicleFullbeam(vehicle, true)
            else
                SetVehicleSuspensionHeight(vehicle, original_height[vehicle] or 0)
                SetVehicleLights(vehicle, 0)
                SetVehicleFullbeam(vehicle, false)
            end
        end
    end
end

--- Toggle bounce for single vehicle
-- @param vehicle number: vehicle ID to toggle bounce for
local function toggle_for_single_vehicle(vehicle)
    is_bounce_mode_active = not is_bounce_mode_active
    bounce_time = GetGameTimer()
    if is_bounce_mode_active then
        original_height[vehicle] = GetVehicleSuspensionHeight(vehicle)
        SetVehicleLights(vehicle, 2)
        SetVehicleFullbeam(vehicle, true)
    else
        SetVehicleSuspensionHeight(vehicle, original_height[vehicle] or 0)
        SetVehicleLights(vehicle, 0)
        SetVehicleFullbeam(vehicle, false)
    end
end

--- Toggle vehicle bounce mode on or off
local function toggle_vehicle_bounce_mode()
    local player = PlayerPedId()
    local coords = GetEntityCoords(player)
    local vehicle = GetVehiclePedIsIn(player, false)
    local vehicle_type = GetVehicleClass(vehicle)
    if affect_vehicles_in_range then
        local vehicles = get_vehicles_in_radius(coords, radius)
        toggle_for_multiple_vehicles(vehicles)
    else
        if vehicle ~= 0 and table_contains(allowed_vehicle_types, vehicle_type) then
            toggle_for_single_vehicle(vehicle)
        end
    end
end

--- @section Threads

--- Handles vehicle bouncing.
CreateThread(function()
    while true do
        Wait(0)
        if is_bounce_mode_active then
            local current_time = GetGameTimer()
            local player = PlayerPedId()
            local coords = GetEntityCoords(player)
            local vehicles = get_vehicles_in_radius(coords, radius)
            local time_since_start = (current_time - bounce_time) / 1000.0
            local new_bounce_height = 0.05 * math.sin(2 * math.pi * 1.5 * time_since_start)
            
            for _, vehicle in ipairs(vehicles) do
                local vehicle_type = GetVehicleClass(vehicle)
                if original_height[vehicle] and table_contains(allowed_vehicle_types, vehicle_type) then
                    SetVehicleSuspensionHeight(vehicle, original_height[vehicle] + new_bounce_height)
                end
            end
        end
    end
end)

--- Triggers event from server to ensure bouncing is synced.
RegisterNetEvent('vehicle_bouncemode:cl:start_bounce', function()
    toggle_vehicle_bounce_mode()
end)

--- Sets the in-game time.
-- @param hour The hour to set (0-23).
-- @param minute The minute to set (0-59).
-- @param second The second to set (0-59).
function SetTime(hour, minute)
    -- Ensure the values are within expected ranges to avoid any potential issues.
    hour = math.floor(math.max(0, math.min(23, hour)))
    minute = math.floor(math.max(0, math.min(59, minute)))

    -- Use the native function to set the time.
    NetworkOverrideClockTime(hour, minute, 0)
end

-- Example usage:
RegisterCommand("settime", function(source, args, rawCommand)
    if #args < 2 then
        print("Usage: /settime <hour> <minute>")
        return
    end

    local hour = tonumber(args[1])
    local minute = tonumber(args[2])
    if hour and minute then
        SetTime(hour, minute)
        print(string.format("Time set to %02d:%02d:%02d.", hour, minute))
    else
        print("Invalid time provided.")
    end
end, false)
