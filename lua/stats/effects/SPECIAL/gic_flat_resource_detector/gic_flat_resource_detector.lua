function init()

	self.resourceName = config.getParameter("resourceName")
	self.resourceValue = config.getParameter("flatValue")
	
	self.resourceStatModifiers = config.getParameter("statModifiers")
	-- self.resourceEffects = config.getParameter("statusEffects")
	
	-- self.resourceEffects = { "gic_floran_gunfirespeed" }
	
	-- self.resourceEffectTitle = "gic_flat_resource_example"
	
	self.finalStatModifiers = {}
	
	for index, value in ipairs(self.resourceStatModifiers) do
		if (value.amount) then
			self.finalStatModifiers[index] = {stat = value.stat, amount = value.amount}
		else
			self.finalStatModifiers[index] = {stat = value.stat, effectiveMultiplier = value.effectiveMultiplier}
		end
	end
	
	-- self.statModifierGroup = effect.addStatModifierGroup(finalStatModifiers)
	
	self.tick = 0;
	
	-- status.clearPersistentEffects(self.resourceEffectTitle)
	-- status.clearPersistentEffects("statusEffect")
end

function update(dt)
  self.tick = self.tick + 1
  
  if (self.tick % 2 == 0) then	-- run only once every other tick for performance reasons
	if (status.resource(self.resourceName) >= self.resourceValue) then -- if detected resource is above/equal a flat value
		if not (self.statModifierGroup) then
			self.statModifierGroup = effect.addStatModifierGroup(self.finalStatModifiers)
			-- status.setPersistentEffects(self.resourceEffectTitle, self.resourceEffects)
		end
	else
		if (self.statModifierGroup) then
			effect.removeStatModifierGroup(self.statModifierGroup)
			self.statModifierGroup = nil
		end
	end
  end
end

function uninit()
  -- status.setPersistentEffects(self.resourceEffectTitle, {})
  -- status.clearPersistentEffects(self.resourceEffectTitle)
  
  if (self.statModifierGroup) then
    -- status.clearPersistentEffects(self.resourceEffectTitle)
	effect.removeStatModifierGroup(self.statModifierGroup)
  end
end
