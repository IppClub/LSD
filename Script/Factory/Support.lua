-- Reuse the ground machine; a medical injury is not cured by its life field.
local D=require('Dora');local Support={}
function Support.create(world,hp,supplied)
 local variant=world.auxiliaryVariant
 if not variant then
  local store,why=require('Ground.AuxiliarySelection').open();assert(store,why)
  local saved,why=store:load();assert(saved,why);variant=saved.variant or 'defence'
 end
 local s=supplied or require('Ground.LifeSupport').new(nil,variant)
 if not supplied then
  s.hp={hp[1],hp[2],hp[3]}
  local rows=D.DB:query("SELECT id FROM lsd.Game0MissionAttempts WHERE mission='c0-m05' AND status='won' LIMIT 1")
  local treated=D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id='medical-recovery'")
  if rows and rows[1] and not(treated and treated[1])then s.maxHP={100,math.min(90,hp[2]),100}end
 end
 world.auxiliaryVariant=s.variant;world.groundSupport=s
 local view=require('Ground.SupportView').create(world,s.variant)
 return s,view
end
function Support.report(s)
 return {lifeRuleVersion=s.ruleVersion or 1,variant=s.variant,gold=s.gold,machineHP=s.machineHP,spent=s.spent,healed=s.healed,hazardDamage=s.hazardDamage,collectionSerial=s.collectionSerial}
end
function Support.resultText(report)
 local a=report.auxiliary;if not a then return end
 -- Final evacuation keeps transport and life-field evidence separately.
 local energy=report.support or a;local hp=a.machineHP or a.hp
 if energy.gold~=nil and energy.spent~=nil and hp~=nil then
  return string.format('辅助机能源 %.1f · 消耗 %.1f · 机体 %.0f',energy.gold,energy.spent,hp)
 end
 if hp~=nil then return string.format('辅助机机体 %.0f',hp)end
end
return Support
