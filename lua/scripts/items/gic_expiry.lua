function ageItem(baseItem, expiry)
  if baseItem.parameters.timeToexpiry then
    baseItem.parameters.timeToexpiry = baseItem.parameters.timeToexpiry - expiry

    baseItem.parameters.tooltipFields = baseItem.parameters.tooltipFields or {}
    baseItem.parameters.tooltipFields.expiryTimeLabel = getexpiryTimeDescription(baseItem.parameters.timeToexpiry)

    if baseItem.parameters.timeToexpiry <= 0 then
      local itemConfig = root.itemConfig(baseItem.name)
      return {
        name = itemConfig.config.expirytedItem or root.assetJson("/scripts/gic_expiry.config:expirytedItem"),
        count = baseItem.count,
        parameters = {}
      }
    end
  end

  return baseItem
end

function getexpiryTimeDescription(expiryTime)
  local descList = root.assetJson("/scripts/gic_expiry.config:expiryTimeDescriptions")
  for i, desc in ipairs(descList) do
    if expiryTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
