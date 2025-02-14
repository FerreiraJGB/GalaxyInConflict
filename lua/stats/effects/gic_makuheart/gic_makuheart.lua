function init()
end

function update(dt)
  
  if mcontroller.onGround() and self.statModifierGroup ~= nil then
	effect.removeStatModifierGroup(self.statModifierGroup)
    self.statModifierGroup = nil

  --this elseif statement could be replaced with one else statement, but i want to be safe.
  elseif not mcontroller.onGround() and self.statModifierGroup == nil then
    self.statModifierGroup = effect.addStatModifierGroup({
        {stat = "gic_dodge_stat", amount = 0.50},
		
        {stat = "ews_bleedResistance", amount = -0.50},
        {stat = "ews_meleeResistance", amount = -0.50},		
        {stat = "ews_smallarmsResistance", amount = -0.50},
		{stat = "ews_heavyarmsResistance", amount = -0.50},		
		{stat = "ews_explosiveResistance", amount = -0.50},		
		{stat = "ews_antitankResistance", amount = -0.50},
		
		{stat = "physicalResistance", amount = -0.50},		
		{stat = "fireResistance", amount = -0.50},		
		{stat = "iceResistance", amount = -0.50},		
		{stat = "electricResistance", amount = -0.50},		
		{stat = "poisonResistance", amount = -0.50},		
		
		{stat = "novaResistance", amount = -0.50},		
		{stat = "holyResistance", amount = -0.50},		
		{stat = "demonicResistance", amount = -0.50},		
		{stat = "bleedResistance", amount = -0.50},		
		
		{stat = "shadowResistance", amount = -0.50},		
		{stat = "cosmicResistance", amount = -0.50},		
		{stat = "radioactiveResistance", amount = -0.50},		
		{stat = "linerifleResistance", amount = -0.50},		
		{stat = "centensianenergyResistance", amount = -0.50},

		{stat = "xanafianResistance", amount = -0.50},		
		{stat = "akkimariacidResistance", amount = -0.50},		
		{stat = "silverResistance", amount = -0.50}
    })
  end

end

function uninit()
    if self.statModifierGroup then
        effect.removeStatModifierGroup(self.statModifierGroup)
    end
end