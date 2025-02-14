require "/items/active/weapons/ranged/ews_weapon.lua"

Disposable = GunFire:new()

function Disposable:init()
  GunFire.init(self)
end

function Disposable:update(dt, fireMode, shiftHeld)
  GunFire.update(self, dt, fireMode, shiftHeld)
end

function Disposable:reload()
	self.magazineProjectile = config.getParameter("magazineProjectile")
	world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
	item.consume(1) --literally just deletes the item upon recieving a reload prompt
end

function Disposable:motion6()
	GunFire.motion6(self)
	self.magazineProjectile = config.getParameter("magazineProjectile")
	world.spawnProjectile(self.magazineProjectile, firePosition or self:firePosition(), activeItem.ownerEntityId(),    self:aimVector(inaccuracy or self.finalInaccuracy),false,config.getParameter( "magazineProjectileConfig" ) or {})
	item.consume(1) --literally just deletes the item when finishing item
end