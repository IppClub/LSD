-- Reuse the game's Yarn/portrait/review UI, then persist only at a safe dialogue boundary.
local D=require("Dora")
local Flow={}
function Flow.freeze(world,value)
 D.Group({"player","unit"}):each(function(e)
  if e.unit.world==world then
   e.keyLeft=false; e.keyRight=false; e.busy=value
   if value then
    if e.unit:isDoing("fmove") or e.unit:isDoing("bmove") then e.unit:stop(); e.unit:start("idle") end
    e.unit.velocityX=0
   end
  end
 end)
 D.emit("HUD.DisplayMove",not value)
end
function Flow.openAsync(id,world,onClosed,replay)
 if world.data.storyBusy then return nil,"STORY_BUSY" end
 local service,err=require("Story.Service").open(); if not service then return nil,err end
 local allowed,reason=service:canRead(id,world.tag,replay); if not allowed then return nil,reason end
 local node=require("Story.Catalog")[id]
 if node.discoveryTag and not service:summary().completed[id] then
  local marker=world:getChildByTag(node.discoveryTag)
  local p=D.Group({"player","unit"}):find(function(e) return e.player and e.unit.world==world end)
  if not marker or not p or math.abs(p.unit.x-marker.x)>=180 then return nil,"DISCOVERY_LOCATION_REQUIRED" end
 end
 local replayCommands={};local commands=require("System.Command")
 if replay and service:summary().completed[id] then
  for _,name in ipairs(node.replayCommands or {}) do
   local replacement=function() end;replayCommands[name]={previous=rawget(commands,name),replacement=replacement};commands[name]=replacement
  end
 end
 local function restoreCommands()
  for name,entry in pairs(replayCommands) do if commands[name]==entry.replacement then commands[name]=entry.previous end end
 end
 world:slot("Cleanup",restoreCommands)
 world.data.storyBusy=true; Flow.freeze(world,true)
 local controller={id=id,phase="dialogue",service=service}
 local story=require("UI.Story")(require("Story.Catalog")[id].file)
 story.tag="story-dialogue"; controller.view=story; world.storyFlow=controller; story:addTo(D.Director.ui3D)
 local function finish()
  restoreCommands(); controller.phase="complete"; world.data.storyBusy=false; Flow.freeze(world,false)
  D.emit("Story.Recorded",id,world)
  if onClosed then onClosed(controller) end
 end
 local function save()
  if controller.phase=="saving" or controller.phase=="complete" then return end
  controller.phase="saving"
  D.thread(function()
   local proof
   if node.finalBetrayalCompletion and world.finalBetrayal then proof=world.finalBetrayal.report;proof.rows=#story._reviews end
   if node.jadeDistanceCompletion and world.jadeDistance then proof=world.jadeDistance.report;proof.rows=#story._reviews end
   if node.jadeArrivalCompletion and world.jadeArrival then proof=world.jadeArrival.report;proof.rows=#story._reviews end
   if node.academyLossCompletion and world.academyLoss then proof=world.academyLoss.report;proof.rows=#story._reviews end
   if node.interrogationCompletion and world.interrogation then
    proof=world.interrogation.report;proof.rows=#story._reviews
   end
   if node.controlPodCompletion and world.controlPodDialogue then proof=world.controlPodDialogue.report;proof.rows=#story._reviews end
   if node.roofCompletion and world.roofDialogue then proof=world.roofDialogue.report;proof.rows=#story._reviews end
   if node.roofAftermathCompletion and world.roofAftermath then proof=world.roofAftermath.report;proof.rows=#story._reviews end
   local ok,saveError=service:completeAsync(id,world.tag,replay,proof)
   if ok then if controller.retry then controller.retry:removeFromParent() end; finish()
   else
    controller.phase="save-error"; controller.error=saveError
    if not controller.retry then
     local retry=D.Node(); retry.tag="story-save-retry"; retry.size=D.App.bufferSize; retry:addTo(D.Director.ui3D); controller.retry=retry
     local message=D.Label("SourceHanSansCN-Regular",30); message.text="资料尚未保存，请重试；已完成的其他进度会保留。"; message.position=D.Vec2(retry.width/2,retry.height/2+70); message:addTo(retry)
     local button=require("UI.InputButton")({text="重试保存",textBG=""}); button.position=D.Vec2(retry.width/2-154,retry.height/2-30); button:slot("Tapped"):clear(); button:slot("Tapped",save); button:addTo(retry); controller.retryButton=button
    end
   end
  end)
 end
 story:slot("Ended",save)
 story:showAsync()
 return controller
end
return Flow
