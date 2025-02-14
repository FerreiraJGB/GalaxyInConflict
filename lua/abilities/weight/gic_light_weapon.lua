require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

function init()
  oldInit()
  status.setPersistentEffects("gic_light_weight", { "gic_light_weight" })
end

function update(dt, fireMode, shiftHeld)
  oldUpdate(dt, fireMode, shiftHeld)
end

function uninit()
  oldUnInit()
  status.clearPersistentEffects("gic_light_weight")
end
