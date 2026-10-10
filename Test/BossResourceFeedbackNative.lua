-- Rebuild player feedback from an actual saved mission episode, without replay
-- or relabelling its decisions and without modifying any database or model.
local D = require('Dora')
local root = D.Path:getPath(D.Path:getScriptPath(...))
local output = root .. '/Test/boss-resource-feedback-result.json'
local result = {status='RUNNING', osInput=false, historicalEpisode=true, policyImprovementProven=false}
local function save() D.Content:save(output, D.json.encode(result, false, true)) end
save()
D.thread(function()
 local ok, why = xpcall(function()
  local source = assert(os.getenv('LSD_QA_BOSS_FEEDBACK_EPISODE'))
  assert(source:match('^/private/tmp/lsd%-boss%-feedback%-record%-%d+/episode%.json$'))
  local raw = assert(D.Content:load(source))
  local episode = assert(D.json.decode(raw, 32))
  result.source = source
  local valid, reason = require('Enemy.BigYingzhaoEvidence').validate(episode)
  assert(valid, reason)
  assert(episode.episode=='mission:5' and episode.boss.status=='failed')
  local contributions = require('Training.YingzhaoContributions')
  local summary = contributions.summarize(episode.boss)
  local nini = summary.actors.ninilite
  assert(nini.empNoEffectBossHits==11 and nini.empNoEffectCost==44)
  assert(nini.armor==35, 'The effective EMP armor contribution must be preserved')
  assert(summary.totalCost==125 and summary.actionCost+summary.deployment==125)
  local text = contributions.text(episode.boss)
  assert(text:find('对应耗材 44', 1, true) and text:find('EMP只削减护甲', 1, true))
  local rewards = require('Training.YingzhaoRewards')
  local reward, reason = rewards.rebuild(episode, 'ninilite', rewards.supportPolicy)
  assert(reward, reason)
  assert(reward.consumption==48 and reward.deployment==3 and reward.components.cost==-51)
  assert(reward.armor==35 and reward.components.armor==8.75)
  assert(reward.trainable==false and reward.terminal)
  assert(D.Content:load(source)==raw, 'Feedback changed its source record')
  result.contributions=summary
  result.reward=reward
  result.feedbackText=text
  result.sourceUnchanged=true
  result.noDatabaseOrModelWrites=true
 end, debug.traceback)
 result.status=ok and 'PASS' or 'FAIL'
 result.error=not ok and why or nil
 save()
 print('LSD_BOSS_RESOURCE_FEEDBACK_' .. result.status)
end)
