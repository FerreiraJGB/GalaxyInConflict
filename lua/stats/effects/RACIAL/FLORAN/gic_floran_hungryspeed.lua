function init()
  local bounds = mcontroller.boundBox()
end

function update(dt)
  if status.stat("hungry") == 1 then
  mcontroller.controlModifiers({
      speedModifier = 1.4
    })
end
end


function uninit()
  
end
