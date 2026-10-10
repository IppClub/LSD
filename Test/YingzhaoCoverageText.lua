-- Report unavailable controls separately from missing lessons; legacy decisions
-- without observations remain readable and never invent a missing scenario.
package.path='Script/?.lua;'..package.path
package.loaded.Dora={}
package.loaded['Training.YingzhaoMentor']={version='test'}
local M=require('Training.YingzhaoComparison')
local function report(decisions)
 return {candidate={algorithm='yingzhao-c45'},rounds={{mode='candidate',status='failed',seconds=10,armorDamage=35,healthDamage=22.5,cost=10,hp={mentor=100,ninilite=0,wuyun=100},decisions=decisions}}}
end
local s={bossAction='hunt',target='summon',targetDistance='near'}
local text=M.text(report({{reason='NO_MATCH',observation=s},{reason='UNSEEN_STATE',observation=s},{reason='ACTION_UNAVAILABLE',observation=s,blockedActions={laser='DISPLACED'}},{accepted=true,observation=s}}))
assert(text:find('召援 / 援军 / 近距离：2 次',1,true))
assert(text:find('受击恢复 1 次',1,true))
assert(not text:find('近距离：4 次',1,true))
local legacy=M.text(report({{reason='NO_MATCH'}}))
assert(legacy:find('未学过的状态/动作 1 次',1,true))
assert(not legacy:find('优先补练的实际场景',1,true))
local accepted=M.text(report({{accepted=true,observation=s}}))
assert(not accepted:find('优先补练的实际场景',1,true))
print('PASS coverage guidance separates unavailable/accepted actions and preserves legacy reports')
