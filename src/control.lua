local event = require("__flib__.event")

event.on_init(function()
  --- @type table<string, LuaEntity[]>
  global.stations = {}
end)

event.on_train_changed_state(function(e)
  local train = e.train
  local end_stop = train.path_end_stop
  if end_stop then
    local name = end_stop.backer_name
    local stations = global.stations[name]
    if stations then
      for _, station in pairs(global.stations[name]) do
        -- Check if it's enabled
        if station.status ~= defines.entity_status.disabled_by_control_behavior then
          -- Check if the train limit is satisfied
          if station.trains_limit then
            -- TODO: Expose an API to count this on the C++ side?
            local count = 0
            for _, train in pairs(station.get_train_stop_trains()) do
              if train.path_end_stop and train.path_end_stop.backer_name == name then
                count = count + 1
              end
            end

            if count >= station.trains_limit then
              return
            end
          end

          -- Create a temporary stop to path to that station
          local schedule = train.schedule
          table.insert(schedule.records, schedule.current, { rail = station.connected_rail, temporary = true })
          train.schedule = schedule
        end
      end
    end
  end
end)

-- TEMPORARY:
event.on_built_entity(function(e)
  local entity = e.created_entity
  if not global.stations[entity.backer_name] then
    global.stations[entity.backer_name] = {}
  end
  table.insert(global.stations[entity.backer_name], entity)
end, { { filter = "type", type = "train-stop" } })
