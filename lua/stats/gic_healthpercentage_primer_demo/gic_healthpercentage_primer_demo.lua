function generateStats(input)
	local res = {}
	for _, val in ipairs(input) do
		local base = {}
		base.stat = val.stat
		
		if val.amount then
			base.amount = val.amount
		elseif val.baseMultiplier then
			base.baseMultiplier = val.baseMultiplier
		elseif val.effectiveMultiplier then
			base.effectiveMultiplier = val.effectiveMultiplier
		end
		
		res[#res+1] = base
	end
	
	--sb.logInfo(sb.printJson(res))
	
	return res
end

function generateEffect(input)
	local res = {}
	for _, val in ipairs(input) do
		res[#res+1] = val
	end
	
	return res
end

function init()
  self.stats = generateStats(effect.getParameter("stats", {}))
  self.mcontrollerModifiers = effect.getParameter("mcontrollerModifiers", {})
  --self.statModifierGroup = effect.addStatModifierGroup(self.stats)
  --effect.addStatModifierGroup({{stat = "protection", amount = config.getParameter("protection", 100)}})
  
  self.active = false
  
  --local triggerStatusEffect = effect.getParameter("triggerStatusEffect")
  --self.toggleTriggerStatusEffect = triggerStatusEffect.enabled
  --self.triggerStatusEffects = generateEffect(triggerStatusEffect.statusEffects)
  
  self.triggerAtAbove = effect.getParameter("triggerAtAbove")
  
  --sb.logInfo(sb.printJson(self.triggerStatusEffects))
  
  script.setUpdateDelta(1)
end

function activateEffects()
	if self.triggerAtAbove then
		return (status.resourcePercentage("health") >= effect.getParameter("healthTriggerPercentage"))
	else
		return (status.resourcePercentage("health") < effect.getParameter("healthTriggerPercentage"))
	end
end

function update(dt)
	if self.active == false and activateEffects() then
		self.statModifierGroup = effect.addStatModifierGroup(self.stats)
		self.active = true
		
		-- if self.toggleTriggerStatusEffect then
			-- sb.logInfo("toggleEffectsOn")
			-- status.setPersistentEffects("statusEffect", self.triggerStatusEffects)
		-- end
		
	elseif self.active and not activateEffects() then
		self.active = false
		effect.removeStatModifierGroup(self.statModifierGroup)
		self.statModifierGroup = nil
		mcontroller.clearControls()
		
		-- if self.toggleTriggerStatusEffect then
			-- sb.logInfo("toggleEffectsOff")
			-- status.clearPersistentEffects("statusEffect")
		-- end
	end
	
	
	if self.active then
		mcontroller.controlModifiers(self.mcontrollerModifiers)
	else
		--do nothing
	end
	
end

function uninit()
  if self.active then
	if self.statModifierGroup then
		effect.removeStatModifierGroup(self.statModifierGroup)
	end
	
	--if self.toggleTriggerStatusEffect then
		--status.clearPersistentEffects("statusEffect")
	--end
  end
end
