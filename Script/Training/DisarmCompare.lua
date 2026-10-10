-- Three registered initial distances; every arm uses the same frozen team,
-- budget and mentor rule. This is observation, never adoption approval.
local D=require('Dora');local M={profiles={{id='near',enemyX=2200},{id='middle',enemyX=2500},{id='far',enemyX=2800}}}
local equal=require('Training.FlowerIdentity').equal
local function copy(v)return D.json.decode(D.json.encode(v,false,true),32)end
local function finite(n)return type(n)=='number'and n==n and n>=0 and n<1e9 end
local function review(record)
 if type(record)~='table'or record.schemaVersion~=1 or type(record.setup)~='table'or record.setup.mentor~='nearest450-kinetic-v1'or record.setup.magic~='disabled-v1'or record.setup.decisionSeconds~=.25 or not equal(record.setup.profiles,M.profiles)or type(record.runs)~='table'or #record.runs~=6 then return nil,'INCOMPLETE_COMPARISON'end
 local setup=record.setup;local candidate=setup.candidate
 if type(candidate)~='table'or not require('Training.DisarmPolicy').validate(candidate.model)then return nil,'INVALID_CANDIDATE'end
 for _,id in ipairs({'ninilite','wuyun'})do if not require('Training.Model').validate(setup.models and setup.models[id],id)then return nil,'INVALID_BASELINE'end end
 local result={pairs={},adoptionEligible=false,wins={baseline=0,candidate=0},cost={baseline=0,candidate=0},damage={baseline=0,candidate=0},seconds={baseline=0,candidate=0}};local episodes={}
 for i,profile in ipairs(M.profiles)do
  local pair={profile=profile.id}
  for j,controller in ipairs({'baseline','candidate'})do
   local run=record.runs[(i-1)*2+j];local t=run and run.trace
   if not t or run.profile~=profile.id or run.controller~=controller or t.demonstrator or (t.status~='won'and t.status~='failed')or not finite(run.seconds)then return nil,'INVALID_RUN'end
   if not equal(t.comparisonSetup,setup)or t.comparisonProfile~=profile.id or t.comparisonController~=controller then return nil,'SETUP_MISMATCH'end
   if controller=='candidate'and not equal(t.candidate,candidate)or controller=='baseline'and t.candidate~=nil then return nil,'CONTROLLER_MISMATCH'end
   if not finite(t.startedAt)or not finite(t.finishedAt)or math.abs(run.seconds-(t.finishedAt-t.startedAt))>1e-6 then return nil,'TIME_MISMATCH'end
   if episodes[t.resources and t.resources.attempt]then return nil,'REUSED_EPISODE'end
   local credit,why=require('Training.DisarmCredit').rebuild(t);if not credit then return nil,why end
   local loadout={};for _,line in ipairs(t.resources.quote.lines)do loadout[#loadout+1]={actor=line.actor,item=line.item,quantity=line.quantity}end
   local quote=require('Economy.Ledger').quote(setup.loadout)
   if not quote or not equal(quote,t.resources.quote)then return nil,'BUDGET_MISMATCH'end
   for _,event in ipairs(t.actions)do if event.source~='scripted-mentor'and event.source~='model'and event.source~='baseline'and event.source~='candidate'then return nil,'HUMAN_ACTION_IN_COMPARISON'end end
   for _,step in ipairs(t.executions)do
    local expected=controller=='candidate'and step.actor==candidate.model.characterId and 'candidate'or'model'
    if step.source~=expected and not(expected=='model'and step.source=='baseline')then return nil,'EXECUTION_SOURCE_MISMATCH'end
   end
   episodes[t.resources.attempt]=true
   local v=assert(require('Training.DisarmVitals').review(t.vitals))
   pair[controller]={won=t.status=='won',cost=t.virtualResult.cost,damage=v.damage,seconds=math.floor(run.seconds*1000+.5)/1000}
   local stats=pair[controller];if stats.won then result.wins[controller]=result.wins[controller]+1 end
   for _,key in ipairs({'cost','damage','seconds'})do result[key][controller]=result[key][controller]+stats[key]end
  end
  result.pairs[#result.pairs+1]=pair
 end
 for _,controller in ipairs({'baseline','candidate'})do result.seconds[controller]=math.floor(result.seconds[controller]*1000+.5)/1000 end
 return copy(result)
end
function M.review(record)
 local ok,result,why=pcall(review,record);if not ok then return nil,'INVALID_COMPARISON'end;return result,why
end
function M.runAsync(candidate,models,loadout,hooks)
 hooks=hooks or {};local setup={combatRules=require('Training.DisarmRules').version,profiles=copy(M.profiles),mentor='nearest450-kinetic-v1',magic='disabled-v1',decisionSeconds=.25,candidate=copy(candidate),models=copy(models),loadout=copy(loadout)}
 local record={schemaVersion=1,setup=setup,runs={}}
 for _,profile in ipairs(M.profiles)do for _,controller in ipairs({'baseline','candidate'})do
  if hooks.cancelled and hooks.cancelled()then return record,'CANCELLED'end
  local b=require('Training.DisarmPractice').createAsync(setup.models,setup.loadout,nil,controller=='candidate'and setup.candidate or nil)
  b.enemies[1].enemy.x=profile.enemyX;b.commandOrigin='scripted-mentor'
  b.disarmTrace.comparisonSetup=copy(setup);b.disarmTrace.comparisonProfile=profile.id;b.disarmTrace.comparisonController=controller
  if hooks.onBattle then hooks.onBattle(b,#record.runs+1,6,profile.id,controller)end
  D.sleep(.4);assert(b:start());local nextDecision=b.started
  while b.phase=='playing'or b.phase=='settling'do
   if hooks.cancelled and hooks.cancelled()and b.phase=='playing'then b:finish('aborted','对照已停止，原成果保留。')end
   if b.phase=='playing'and D.App.runningTime>=nextDecision then
    nextDecision=D.App.runningTime+.25
    local target=b:target(b.mentor)
    if target then local dx=target.enemy.x-b.mentor.x;if math.abs(dx)>450 then b:command(dx>0 and 'right'or'left')else b:command('stop');b:command('shoot')end end
   end
   if hooks.update then hooks.update(b)end
   D.sleep(.02)
  end
  local saved,why=require('Training.DisarmPersistence').callback()(b.phase,b.report)
  if not saved then return record,why end
  record.runs[#record.runs+1]={profile=profile.id,controller=controller,seconds=b.disarmTrace.finishedAt-b.disarmTrace.startedAt,trace=copy(b.disarmTrace)}
  if b.phase=='aborted'then return record,'CANCELLED'end
 end end
 local review,why=M.review(record);if not review then return record,why end
 record.review=review;return record
end
local function costBreakdown(record)
 local result={baseline={deployment=0,items={}},candidate={deployment=0,items={}}}
 for _,run in ipairs(record.runs)do
  local group=result[run.controller];local resources=run.trace.resources
  group.deployment=group.deployment+resources.quote.deployment
  for _,event in pairs(resources.events)do
   local key=event.owner..':'..event.item
   local item=group.items[key]or{cost=0,units=0,stolen=0};group.items[key]=item
   item.cost=item.cost+event.cost;item.units=item.units+event.count
   if event.performer~=event.owner then item.stolen=item.stolen+event.cost end
  end
 end
 return result
end
function M.costBreakdown(record)
 local review,why=M.review(record);if not review then return nil,why end
 return costBreakdown(record)
end
function M.text(record)
 local r,why=M.review(record);if not r then return '本轮对照未完成，不能据此判断候选收益。'end
 local candidate=record.setup.candidate
 local name=({ninilite='妮妮莉特',wuyun='乌云'})[candidate.model.characterId]
 local lines={'缴械对照 · '..name..' · 候选 #'..tostring(candidate.id)..'（基础模型 / 候选）',string.format('胜利 %d/3 / %d/3　总消耗 %d / %d　累计承伤 %d / %d',r.wins.baseline,r.wins.candidate,r.cost.baseline,r.cost.candidate,r.damage.baseline,r.damage.candidate)}
 for _,p in ipairs(r.pairs)do lines[#lines+1]=string.format('%s：%s / %s；消耗 %d / %d；承伤 %d / %d；%.1f / %.1f秒',({near='近距',middle='中距',far='远距'})[p.profile],p.baseline.won and '胜利'or'失败',p.candidate.won and '胜利'or'失败',p.baseline.cost,p.candidate.cost,p.baseline.damage,p.candidate.damage,p.baseline.seconds,p.candidate.seconds)end
 local costs=costBreakdown(record)
 lines[#lines+1]='';lines[#lines+1]='费用构成（基础模型 / 候选，含被夺武器消耗）'
 lines[#lines+1]=string.format('三场整备：%d / %d',costs.baseline.deployment,costs.candidate.deployment)
 for _,entry in ipairs({{'mentor:kinetic','导师实弹'},{'ninilite:emp','妮妮莉特EMP'},{'wuyun:emp','乌云EMP'},{'wuyun:blade','乌云近战'}})do
  local a=costs.baseline.items[entry[1]]or{cost=0,units=0,stolen=0};local b=costs.candidate.items[entry[1]]or{cost=0,units=0,stolen=0}
  lines[#lines+1]=string.format('%s：费用%d / %d，用量%d / %d；被夺消耗%d / %d',entry[2],a.cost,b.cost,a.units,b.units,a.stolen,b.stolen)
 end
 lines[#lines+1]='各配置仅一组对照，尚不足以证明稳定提升；未自动采用。'
 return table.concat(lines,'\n')
end
return M
