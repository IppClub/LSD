local D=require('Dora');local Distance={}
function Distance.openAsync(world,arrival,player)
 local service=arrival.service;local facts,why=service:summary();if not facts then return nil,why end
 if not facts.mission.unlocks['twins-rescued']then return nil,'MISSION_LOCKED'end
 local c={report={version=1,playerX=player.unit.x,wardClosed=not arrival.ward.active,twinsAtExit=arrival.twins[1].model.x>=5400 and arrival.twins[2].model.x>=5560}};world.jadeDistance=c
 arrival.phase='opening'
 local flow,why=require('Story.Flow').openAsync('jade-distance',world,function()
  arrival.phase='ready';arrival.label.text='玉留下了有限的撤离窗口';require('Final.Gate').attach(world)
 end,facts.completed['jade-distance']or false)
 if not flow then arrival.phase='ready'end
 return flow,why
end
return Distance
