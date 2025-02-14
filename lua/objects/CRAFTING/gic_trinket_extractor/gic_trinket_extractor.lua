require "/scripts/util.lua"

function craftingRecipe(items)
  if #items ~= 1 then return end
  local item = items[1]
  
  --local validItems = config.getParameter("validArmors")
  --if not item or not validItems[item] then return end
  local itemConfig = root.itemConfig({name = item.name,count = 1})
  local tooltipKind = itemConfig.config.tooltipKind
  --sb.logInfo(sb.printJson(tooltipKind))
  
  if (tooltipKind ~= "gic_largebase_armor" and tooltipKind ~= "gic_largebase_platecarrier") or itemConfig.config.acceptsAugmentType == nil then return end
  
  if item.parameters and item.parameters.currentAugment then
	  --local augmentParameters = copy(item.parameters) or {}
	  --jremove(healedParams, "inventoryIcon")
	  --jremove(healedParams, "currentPets")
	  --for _,pet in pairs(healedParams.pets) do
		--jremove(pet, "status")
	  --end
	  --healedParams.podItemHasPriority = true
	  local resType = item.parameters.currentAugment.name
	  jremove(item.parameters, "currentAugment")

	  local res = {
		  name = resType,
		  count = 1
		}
	  
	  self.storedItem = items[1]
	  self.shouldRespawnItem = true
	  return {
		  input = items,
		  output = res,
		  duration = 1.0
		}
  else return end
end

function update(dt)
  script.setUpdateDelta(1)
  --local powerOn = false

  --for _,item in pairs(world.containerItems(entity.id())) do
    --if item.parameters and item.parameters.podUuid then
      --powerOn = true
      --break
    --end
  --end
  --sb.logInfo("---")
  --sb.logInfo(sb.printJson(world.containerItemAt(entity.id(), 0)))
  --sb.logInfo(sb.printJson(world.containerItemAt(entity.id(), 1)))
  --sb.logInfo("---")
  
  -- after crafting the item, the original source item (in slot 0) disappears and output spawns in slot 1. we have to respawn the old armor item back in slot 0.
  if self.shouldRespawnItem and world.containerItemAt(entity.id(), 0) == nil and world.containerItemAt(entity.id(), 1) ~= nil then
	world.containerPutItemsAt(entity.id(), self.storedItem, 0)
	self.shouldRespawnItem = false
  end

  --if powerOn then
    --animator.setAnimationState("powerState", "on")
  --else
    --animator.setAnimationState("powerState", "off")
  --end
end
