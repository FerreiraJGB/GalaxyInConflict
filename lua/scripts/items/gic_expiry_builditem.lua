function build(directory, config, parameters, level, seed)
  if not parameters.timeToexpiry then
    local expiryMultiplier = parameters.expiryMultiplier or config.expiryMultiplier or 1.0
    parameters.timeToexpiry = root.assetJson("/items/gic_expiry.config:baseTimeToexpiry") * expiryMultiplier
  end

  config.tooltipFields = config.tooltipFields or {}
  config.tooltipFields.expiryTimeLabel = getexpiryTimeDescription(parameters.timeToexpiry)

  return config, parameters
end

function getexpiryTimeDescription(expiryTime)
  local descList = root.assetJson("/items/gic_expiry.config:expiryTimeDescriptions")
  for i, desc in ipairs(descList) do
    if expiryTime <= desc[1] then return desc[2] end
  end
  return descList[#descList]
end
