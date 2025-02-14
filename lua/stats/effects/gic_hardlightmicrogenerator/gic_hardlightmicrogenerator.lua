require "/scripts/util.lua"
require "/scripts/status.lua"

-- med, refer to the frostmoon artifact instead of this mess. i purposefully left this largely messy for future reference, or something like that.
function init()

  --[[
  self.statModifierGroup = effect.addStatModifierGroup({

    {stat = "fireResistance", amount = 1.0},
    {stat = "iceResistance", amount = 1.0},
    {stat = "poisonResistance", amount = 1.0},
    {stat = "electricResistance", amount = 1.0},
    {stat = "physicalResistance", amount = 1.0},
    {stat = "radioactiveResistance", amount = 1.0},
    {stat = "shadowResistance", amount = 1.0},
    {stat = "cosmicResistance", amount = 1.0},
	
    {stat = "ews_meleeResistance", amount = 1.0},
    {stat = "ews_smallarmsResistance", amount = 1.0},
    {stat = "ews_heavyarmsResistance", amount = 1.0},
    {stat = "ews_explosiveResistance", amount = 1.0},
    {stat = "ews_antitankResistance", amount = 1.0},	
    {stat = "ews_psychicResistance", amount = 1.0},	
	
    {stat = "novaResistance", amount = 1.0},
    {stat = "holyResistance", amount = 1.0},
    {stat = "demonicResistance", amount = 1.0},
    {stat = "bleedResistance", amount = 1.0},
    {stat = "shadowResistance", amount = 1.0},
    {stat = "cosmicResistance", amount = 1.0},
    {stat = "radioactiveResistance", amount = 1.0},
    {stat = "linerifleResistance", amount = 1.0},
    {stat = "centensianenergyResistance", amount = 1.0},
    {stat = "xanafianResistance", amount = 1.0},
    {stat = "akkimariacidResistance", amount = 1.0},
    {stat = "silverResistance", amount = 1.0}

  })
  ]]--
  
  self.statModifierGroup2 = effect.addStatModifierGroup({
	{stat = "gic_hardlightmicrogenerator", amount = 1}
  })

  animator.setParticleEmitterActive("sparks", true)
  effect.setParentDirectives("fade=FDD700=0.0")

  script.setUpdateDelta(1)

  self.triggerDamageThreshold = config.getParameter("triggerDamageThreshold")

  self.timeUntilActive = config.getParameter("activateDelay")
  
  self.triggered = false
  
  
  local damageNullifiers = status.statusProperty("gic_damageNullifiers",{})
  if not damageNullifiers.microgen then
	-- {stat, activated, nullify damage entirely}
	damageNullifiers.microgen = {"gic_hardlightmicrogenerator",false,true}
  end
  status.setStatusProperty("gic_damageNullifiers",damageNullifiers)
end

function update(dt)
  if self.triggered then
    self.timeUntilExpire = self.timeUntilExpire - dt
    if self.timeUntilExpire <= 0 then
	  --sb.logInfo("restore hardlight gen")
	
	  -- remove stat modifier group if it still exists, shouldn't exist but safeguard??
	  --if self.statModifierGroup2 then effect.removeStatModifierGroup(self.statModifierGroup2) end
	  --self.statModifierGroup2 = effect.addStatModifierGroup({
		--{stat = "gic_hardlightmicrogenerator", amount = 1}
	  --})
	  
      --self.triggered = false
	  --status.setStatusProperty("gic_hardlightmicrogenerator",true)
    end
  elseif self.timeUntilActive > 0 then --or not self.damageListener then
    self.timeUntilActive = self.timeUntilActive - dt
    if self.timeUntilActive <= 0 then
	  --[[
      self.damageListener = damageListener("damageTaken", function(notifications)
        local totalDamage = 0
        for _, notification in pairs(notifications) do
          if notification.hitType == "Hit" then
            totalDamage = totalDamage + notification.damageDealt
            if totalDamage <= self.triggerDamageThreshold then -->=
              trigger()
              break
            end
          end
        end
      end)
	  ]]--
    end
  else
	local damageNullifiers = status.statusProperty("gic_damageNullifiers",{})
	if damageNullifiers.microgen[2] == false then
		-- sb.logInfo("trigger microgen")
		trigger()
	end
    --self.damageListener:update()
  end
end

function uninit()

	--effect.removeStatModifierGroup(self.statModifierGroup)
	if not self.triggered then
		effect.removeStatModifierGroup(self.statModifierGroup2)
	end

end

--[[
function trigger()

	 status.addEphemeralEffect("gic_hardlightmicrogenerator_weakness", 20)

  status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = config.getParameter("explosionDamageAmount"),
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
	
--  world.spawnProjectile(
--      "gic_u500_explosion",
--      mcontroller.position(),
--      entity.id(),
--      {0, 0},
--      true,
--      {}
--    )

  animator.burstParticleEmitter("sparks")
  animator.setParticleEmitterActive("sparks", false)
  animator.setLightActive("glow", false)
  self.timeUntilExpire = config.getParameter("deactivateDelay")
  
  self.triggered = true
end
]]--

function trigger()
	-- update damageNullifiers table
	local damageNullifiers = status.statusProperty("gic_damageNullifiers")
	damageNullifiers.microgen[2] = true
	status.setStatusProperty("gic_damageNullifiers",damageNullifiers)
	
    status.applySelfDamageRequest({
      damageType = "IgnoresDef",
      damage = config.getParameter("explosionDamageAmount"),
      damageSourceKind = "default",
      sourceEntityId = entity.id()
    })
	
	animator.burstParticleEmitter("sparks")
	animator.setParticleEmitterActive("sparks", false)
	animator.setLightActive("glow", false)
	
	-- sb.logInfo("trigger hardlight microgen")
	effect.removeStatModifierGroup(self.statModifierGroup2)
	self.timeUntilExpire = config.getParameter("deactivateDelay")
	self.triggered = true
	
	status.addEphemeralEffect("gic_hardlightmicrogenerator_weakness", 20)
end
