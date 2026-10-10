-- Shared budget panel, retaining the factory's existing level callback.
local M={}
function M.openAsync(models,support,cancelled,started)
 return require('Economy.Preparation').openAsync('c0-m05',models,cancelled,function(service,attempt)
  local level=require('Factory.Level').openAsync(service,attempt,support)
  if started then started(level,attempt)end
 end)
end
return M
