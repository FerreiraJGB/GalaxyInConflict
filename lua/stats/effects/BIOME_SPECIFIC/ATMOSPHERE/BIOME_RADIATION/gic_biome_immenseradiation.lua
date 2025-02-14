function init()
  local bounds = mcontroller.boundBox()
  
  script.setUpdateDelta(2)

  self.tickRate = config.getParameter("tickRate")
  self.tickDamage = config.getParameter("tickDamage")

  self.tickTimer = self.tickRate
  
  world.sendEntityMessage(entity.id(), "queueRadioMessage", "gic_biome_immenseradiation", 5.0)
end

function update(dt)
  self.tickTimer = math.max(0, self.tickTimer - dt)
--  if self.tickTimer == 0 and mcontroller.onGround() then  
  if self.tickTimer == 0 then
  
    self.tickTimer = self.tickRate
	
    status.applySelfDamageRequest({
        damageType = "IgnoresDef",
        damage = self.tickDamage,
        damageSourceKind = "ews_antitank",
        sourceEntityId = entity.id()
      })
	  
  end
end

function uninit()

end
