local ews_thermalActive = false

if (afterInit) then
	local aInitOld = afterInit
end

function afterInit(self)
	if (aInitOld) then
		aInitOld(self)
	end
	
	if player then
		local attachmentConfig = config.getParameter( "sightAttachment" ) -- sets the sight data if an attachment is inserted
		  if attachmentConfig and attachmentConfig.attachmentImage and attachmentConfig.attachmentAttached then
				
			if attachmentConfig.specialAttachmentConfig then						--sets up cursor scope stuff
			
				if attachmentConfig.specialAttachmentConfig.type == "thermal" or attachmentConfig.specialAttachmentConfig.type == "thermalScope" then
					ews_thermalActive = true
					
					if attachmentConfig.specialAttachmentConfig.type == "thermalScope" then
						self.scopedIn = attachmentConfig.specialAttachmentConfig.scopedIn or nil
						
						self.scopeAttached = true
						
						self.scopeIn = attachmentConfig.specialAttachmentConfig.scopeIn or nil
						self.scopeInTime = attachmentConfig.specialAttachmentConfig.scopeInTime or 0
						self.scopeOut = attachmentConfig.specialAttachmentConfig.scopeOut or nil
						self.scopeOutTime = attachmentConfig.specialAttachmentConfig.scopeOutTime or 0
					end
				end
			end
		end
		
		if ews_thermalActive then
			-- if thermal sights attached, enable thermals
			status.setStatusProperty("ews_thermalSightActive", true)
			
			-- convert to radians, then divide by two
			local spreadAngle = attachmentConfig.specialAttachmentConfig.spreadAngle * math.pi / 180
			spreadAngle = spreadAngle / 2
			
			
			-- define spread angle (deviate from angle of weapon) of the thermal sight
			-- defined in the attachment
			status.setStatusProperty("ews_thermalSightAngle", spreadAngle)
			
			-- define range of the thermal sight
			-- defined in the attachment
			status.setStatusProperty("ews_thermalSightRange", attachmentConfig.specialAttachmentConfig.range)
			
			-- define color of the thermal sight
			-- defined in the attachment
			status.setStatusProperty("ews_thermalColor", attachmentConfig.specialAttachmentConfig.color)
			
			-- define line of sight status of the thermal sight
			-- defined in the attachment
			status.setStatusProperty("ews_thermalLOS", attachmentConfig.specialAttachmentConfig.lineOfSightCheck)
			
			
			-- define facing direction
			status.setStatusProperty("ews_facingDirection", mcontroller.facingDirection())
			
			-- define initial aiming angle of user
			status.setStatusProperty("ews_aimAngle", self.weapon.aimAngle)
		end
	end
end



if (afterUpdate) then
	local aUpdateOld = afterUpdate
end

function afterUpdate(self, dt, fireMode, shiftHeld)
	if (aUpdateOld) then
		aUpdateOld(self, dt, fireMode, shiftHeld)
	end
	-- sb.logInfo("thermal sight")
	
	-- code for thermal sight and stuff
	if player and ews_thermalActive then
		status.setStatusProperty("ews_thermalSightActive", true)
		status.setStatusProperty("ews_facingDirection", mcontroller.facingDirection())
		status.setStatusProperty("ews_aimAngle", self.weapon.aimAngle)
	end
end


if (ewsUninit) then
	local uninitOld = ewsUninit
end

function ewsUninit(self)
	if (uninitOld) then
		uninitOld(self)
	end
	
	if player and ews_thermalActive then
		status.setStatusProperty("ews_thermalSightActive", false)
	end
end