
function setScriptDt(args, board)
  script.setUpdateDelta(args.scriptDelta)
  sb.logInfo(script.updateDt())
  return true
end