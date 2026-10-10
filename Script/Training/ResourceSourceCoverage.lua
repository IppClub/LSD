-- Describe validated candidate sources, not training success or state coverage.
local M={}
function M.build(records)
 if not records then return nil end
 local counts={}
 for _,record in ipairs(records)do local id=record.source.profile;counts[id]=(counts[id]or 0)+1 end
 return counts
end
function M.text(counts,profile)
 if not counts then return '来源场景尚未读取。'end
 local lines={}
 for _,id in ipairs(require('Training.FlowerScenarios').resourceIds)do
  if counts[id]then lines[#lines+1]=require('Training.FlowerScenarios').get(id).name..'×'..counts[id]end
 end
 local text='训练来源场景：'..(#lines>0 and table.concat(lines,'、')or '无')
 if profile then text=text..'\n'..(counts[profile]and '当前场景已有来源；不代表同配装状态已覆盖或已学会。'or '当前场景没有直接训练来源，正在检验泛化。')end
 return text
end
return M
