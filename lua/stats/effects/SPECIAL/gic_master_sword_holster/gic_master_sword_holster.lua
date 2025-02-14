require "/scripts/util.lua"
require "/scripts/interp.lua"
require "/scripts/vec2.lua"

local deg2rad = math.pi / 180
local transformOffset = {-1.175,-1.2}

function init()
	local crouching = 0
	if mcontroller.crouching() == true then
		crouching = 1
	else
	    crouching = 0
	end
	
	if mcontroller.facingDirection() == 1 then 
		animator.setGlobalTag("facingDirection", "?flipx")
		
		
		local finOffset = {transformOffset[1],transformOffset[2] - crouching}
		
		animator.resetTransformationGroup("holster")
		animator.translateTransformationGroup("holster",finOffset)
		animator.rotateTransformationGroup("holster", -260*deg2rad, finOffset)
	else
		animator.setGlobalTag("facingDirection", "")
		
		local finOffset = {-1 * transformOffset[1],transformOffset[2] - crouching}
		
		
		animator.resetTransformationGroup("holster")
		animator.translateTransformationGroup("holster",finOffset)
		animator.rotateTransformationGroup("holster", 260*deg2rad, finOffset)
	end
end

local tickTmp = 0
local runOffset = 0
function update(dt)

	local crouching = 0
	if mcontroller.crouching() == true then
		crouching = 1
	else
	    crouching = 0
	end
	
	
	
	--if mcontroller.running() == true then
		--tickTmp = tickTmp + 1
		--runOffset = util.round(3.0*math.sin(tickTmp*10*deg2rad))
		--runOffset = runOffset
	--else
		--tickTmp = 0
		--runOffset = 0
	--end
	
	
	
	
	if mcontroller.facingDirection() == 1 then 
		animator.setGlobalTag("facingDirection", "?flipx")
		
		
		local finOffset = {transformOffset[1],runOffset + transformOffset[2] - crouching}
		
		animator.resetTransformationGroup("holster")
		animator.translateTransformationGroup("holster",finOffset)
		animator.rotateTransformationGroup("holster", -260*deg2rad, finOffset)
	else
		animator.setGlobalTag("facingDirection", "")
		
		local finOffset = {-1 * transformOffset[1],runOffset + transformOffset[2] - crouching}
		
		
		animator.resetTransformationGroup("holster")
		animator.translateTransformationGroup("holster",finOffset)
		animator.rotateTransformationGroup("holster", 260*deg2rad, finOffset)
	end
end

function uninit()

end
