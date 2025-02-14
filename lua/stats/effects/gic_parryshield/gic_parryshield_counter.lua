require "/scripts/status.lua"

function init()
  self.listener = damageListener("damageTaken", function(notifications)
	for _,notification in pairs(notifications) do
      if not (notification.damageSourceKind == "hidden" or notification.damageSourceKind == "noDamage") then
		animator.setAnimationState("shield", "hit")
		animator.playSound("perfectBlock")
		world.spawnProjectile("gic_counterflash_long", mcontroller.position(), entity.id(), {0,0}, false, {})
	  end
	end
  end)

  self.statModifierGroup = effect.addStatModifierGroup({
    {stat = "protection", amount = 200.0},
    {stat = "fireResistance", amount = 200.0},
    {stat = "iceResistance", amount = 200.0},
    {stat = "poisonResistance", amount = 200.0},
    {stat = "electricResistance", amount = 200.0},
    {stat = "physicalResistance", amount = 200.0},
    {stat = "radioactiveResistance", amount = 200.0},
    {stat = "shadowResistance", amount = 200.0},
    {stat = "cosmicResistance", amount = 200.0},
	
    {stat = "ews_meleeResistance", amount = 200.0},
    {stat = "ews_smallarmsResistance", amount = 200.0},
    {stat = "ews_heavyarmsResistance", amount = 200.0},
	
	
	
	
	
    {stat = "novaResistance", amount = 200.0},
    {stat = "holyResistance", amount = 200.0},
    {stat = "demonicResistance", amount = 200.0},
    {stat = "bleedResistance", amount = 200.0},
    {stat = "shadowResistance", amount = 200.0},
    {stat = "cosmicResistance", amount = 200.0},
    {stat = "radioactiveResistance", amount = 200.0},
    {stat = "linerifleResistance", amount = 200.0},
    {stat = "centensianenergyResistance", amount = 200.0},
    {stat = "xanafianResistance", amount = 200.0},
    {stat = "akkimariacidResistance", amount = 200.0},
    {stat = "silverResistance", amount = 200.0}	
	
	
  })
end

function update(dt)
  self.listener:update()
end

function uninit()
	effect.removeStatModifierGroup(self.statModifierGroup)
end
