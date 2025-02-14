-- demo file of a universal hook

if (beforeInit) then
	local bInitOld = beforeInit
end

function beforeInit(self)
	if (bInitOld) then
		bInitOld(self)
	end
	
	-- sb.logInfo("beforeInit")
end


if (afterInit) then
	local aInitOld = afterInit
end

function afterInit(self)
	if (aInitOld) then
		aInitOld(self)
	end
	
	-- sb.logInfo("afterInit")
end


if (beforeUpdate) then
	local bUpdateOld = beforeUpdate
end

function beforeUpdate(self, dt, fireMode, shiftHeld)
	if (bUpdateOld) then
		bUpdateOld(self, dt, fireMode, shiftHeld)
	end
	
	-- sb.logInfo("beforeUpdate")
end


if (afterUpdate) then
	local aUpdateOld = afterUpdate
end

function afterUpdate(self, dt, fireMode, shiftHeld)
	if (aUpdateOld) then
		aUpdateOld(self, dt, fireMode, shiftHeld)
	end
	
	-- sb.logInfo("afterUpdate")
end


if (ewsUninit) then
	local uninitOld = uninit
end

function ewsUninit(self)
	if (uninitOld) then
		uninitOld(self)
	end
	
	-- sb.logInfo("uninit")
end