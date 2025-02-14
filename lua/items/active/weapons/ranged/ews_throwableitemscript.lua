require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/items/active/weapons/ews_weaponinit.lua"

function init()
  activeItem.setCursor("/cursors/reticle0.cursor")
  animator.setGlobalTag("paletteSwaps", config.getParameter("paletteSwaps", ""))

  self.weapon = Weapon:new()

  self.weapon:addTransformationGroup("weapon", {0,0}, 0)
  self.weapon:addTransformationGroup("muzzle", self.weapon.muzzleOffset, 0)

  local primaryAbility = getPrimaryAbility()
  self.weapon:addAbility(primaryAbility)

  local secondaryAbility = getAltAbility(self.weapon.elementalType)
  if secondaryAbility then
    self.weapon:addAbility(secondaryAbility)
  end
  

  self.debug = ""
  
  
  
  --self.ammoMax = config.getParameter("ammoMax") or 1
  --self.ammoAmount = config.getParameter("ammoAmount") or 1
  self.weapon.ammoMax = config.getParameter("ammoMax") or 1
  self.weapon.ammoAmount = config.getParameter("ammoAmount") or 1
  self.weapon.altAmmoMax = config.getParameter("altAmmoMax") or 1
  self.weapon.altAmmoAmount = config.getParameter("altAmmoAmount") or 1
  
  
  
  
  self.weapon:init()
end

function update(dt, fireMode, shiftHeld)
  self.weapon:update(dt, fireMode, shiftHeld)
	
	
	if self.weapon.ammoAmount == 0 then
		if animator.animationState("gunState") == "armed" then
			animator.setAnimationState("gunState","empty")
		end
	elseif animator.animationState("gunState") == "empty" then
		animator.setAnimationState("gunState","armed")
	end
	
	self.weapon.ammoMax = config.getParameter("ammoMax") or 1
	self.weapon.ammoAmount = config.getParameter("ammoAmount") or 1
	self.weapon.altAmmoMax = config.getParameter("altAmmoMax") or 1
	self.weapon.altAmmoAmount = config.getParameter("altAmmoAmount") or 1
	
	
end

function uninit()
  self.weapon:uninit()
end
