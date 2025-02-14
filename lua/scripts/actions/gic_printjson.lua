
function printJson(args,board)
  local output = sb.printJson(args.input)
  --sb.logInfo(sb.printJson(args))
  return true, {text = output}
end