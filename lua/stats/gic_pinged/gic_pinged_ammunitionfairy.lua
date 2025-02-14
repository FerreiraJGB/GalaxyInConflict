function init()
  effect.addStatModifierGroup({
     {stat = "ews_infammo", amount = 1.0},   
  })
end

function update(dt)
end

function uninit()
  effect.addStatModifierGroup({
     {stat = "ews_infammo", amount = 0.0},   
  })
end
