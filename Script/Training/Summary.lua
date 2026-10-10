-- Presentation and report identity for both supported learning algorithms.
-- Q updates are not human demonstrations and have no imitation accuracy.
local S={}
function S.record(model)
 if not require('Training.Model').validate(model)then return nil end
 return {characterId=model.characterId,algorithm=model.algorithm or 'c45',count=model.algorithm=='qlearning' and model.updates or model.sampleCount,
  featureSchemaVersion=model.featureSchemaVersion,actionSetVersion=model.actionSetVersion,rewardPolicy=model.rewardPolicy}
end
function S.short(model)
 local r=S.record(model);if not r then return '训练记录不可用'end
 return r.algorithm=='qlearning' and ('自主训练 '..r.count..' 步') or (r.count..' 条示范')
end
function S.detail(model)
 local r=S.record(model);if not r then return '训练记录不可用'end
 if r.algorithm=='qlearning'then
  local count=0;for _ in pairs(model.values)do count=count+1 end
  return S.short(model)..'\n已学习情境：'..count..' 种\n请通过试战比较表现。'
 end
 return '成功示范：'..r.count..' 条\n示范准确率：'..math.floor(model.trainingAccuracy*100+.5)..'%'
end
function S.matches(report,model)
 if type(report)~='table' or type(model)~='table'then return false end
 local r=S.record(model);if not r then return false end
 local recorded=report.training
 if recorded==nil then
  -- Preserve existing C4.5 mission reports, but never accept nil == nil for Q.
  return r.algorithm=='c45' and report.samples==r.count
 end
 if type(recorded)~='table'then return false end
 return recorded.characterId==r.characterId and recorded.algorithm==r.algorithm and recorded.count==r.count and recorded.featureSchemaVersion==r.featureSchemaVersion
  and recorded.actionSetVersion==r.actionSetVersion and recorded.rewardPolicy==r.rewardPolicy
end
return S
