-- Preserve every native attack stage before defeat or encounter withdrawal.
local D=require('Dora');local A=require('CombatAnimation');local Combat=require('Training.EnemyCombat')
local Enemy={};Enemy.__index=Enemy
function Enemy.new(context,skills)
 context.finishActiveAttack=true
 local self=setmetatable({context=context,dead=false,stopping=false},Enemy)
 self.combat=Combat.new(context,skills);return self
end
function Enemy:stop()
 self.stopping=true;self.context.mode='review';self.context.nextEnemy=math.huge
end
function Enemy:update(now)
 local c=self.context
 if self.dead or self.dying then return end
 if self.stopping then c.nextEnemy=math.huge end
 if c.enemyPhase=='attack' or (c.enemyHP>0 and not self.stopping) then self.combat:update(now)end
 self.busy=c.enemyPhase=='attack'
 if not self.busy then
  if c.enemyHP<=0 then
   self.dying=true;c.enemy.velocityX=0;c.enemy:stop();self.loseStarted=now
   D.thread(function()
    self.loseDuration=A.playOnceAsync(c.enemy,'lose');self.loseEnded=D.App.runningTime
    c.enemy.visible=false;c.enemy.group=3;self.dead=true;self.dying=false
   end)
  elseif self.stopping then c.enemy.velocityX=0;A.rest(c.enemy)end
 end
end
return Enemy
