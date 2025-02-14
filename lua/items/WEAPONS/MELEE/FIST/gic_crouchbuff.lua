require "/scripts/util.lua"

local oldInit = init
local oldUpdate = update
local oldUnInit = uninit

function init()
  oldInit()
  --status.setPersistentEffects("onEquiptStatus", { "gic_light_weight" })
end

function update(dt, fireMode, shiftHeld)
  oldUpdate(dt, fireMode, shiftHeld)
  
  if mcontroller.crouching() then
	status.setPersistentEffects("crouchStatus", { "gic_duckandweave" })
  else
	status.clearPersistentEffects("crouchStatus")
  end
end

function uninit()
  oldUnInit()
  status.clearPersistentEffects("crouchStatus")
end
