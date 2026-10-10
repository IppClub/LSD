-- Scene-owned background music. AudioSource cleanup alone does not stop a voice.
local D=require('Dora')
local Music={}
local current
local root=D.Node();root.tag="game-music";root:addTo(D.Director.postNode)
local levels={
 ['Music/军事学园.mp3']=.426,['Music/训练场.mp3']=.343,
 ['Music/探索.mp3']=1,['Music/战斗准备.mp3']=.318,
 ['Music/战斗1.mp3']=.317,['Music/战斗2.mp3']=.309,
 ['Music/L·S·Depart.mp3']=.285,['Music/L·S·DepartII.mp3']=.242,
 ['Music/L·S·Domain（现实世界主题曲）.mp3']=.206
}
local function stop(record,fade)
 if not record then return end
 record.stopped=true
 local duration=fade or .4
 record.source:stop(duration)
 D.thread(function()
  D.sleep(duration+.1)
  if record.source.parent then record.source:removeFromParent() end
 end)
end
function Music.stop(fade)
 local old=current;current=nil;stop(old,fade)
end
function Music.acquire(owner,path,options)
 assert(owner and type(path)=='string','Music requires a scene owner and file path')
 options=options or {}
 local volume=math.max(0,math.min(1,options.volume or levels[path] or .3))
 local fade=math.max(0,options.fade or .6)
 local loop=options.loop~=false
 local record=current
 if not record or record.path~=path or record.loop~=loop or not record.source.playing then
  local source=D.AudioSource(path,false)
  if not source then return nil,'Unable to load music: '..path end
  source:addTo(root)
  source:slot('Cleanup',function()source:stop(0)end)
  source.looping=loop;source.volume=fade>0 and 0 or volume
  if not source:playBackground() then source:removeFromParent();return nil,'Unable to play music: '..path end
  D.Audio:stopStream(fade) -- Hand over from the existing opening cinematic.
  stop(current,fade)
  record={source=source,path=path,loop=loop,volume=volume,started=D.App.runningTime,fading=fade>0}
  current=record
  if fade>0 then
   D.thread(function()
    D.cycle(fade,function(t)
     if not record.stopped then source.volume=record.volume*t end
    end)
    record.fading=false
   end)
  end
 else
  record.volume=volume
  if not record.fading then record.source.volume=volume end
 end
 -- A fresh lease means delayed cleanup from an old scene cannot stop a new one.
 local lease={}
 record.lease=lease
 owner:slot('Cleanup',function()
  D.thread(function()
   D.sleep(.15) -- Allow a doorway to transfer the same song to its new world.
   if current==record and record.lease==lease then Music.stop(.4) end
  end)
 end)
 function lease:release(fadeTime)
  if current==record and record.lease==self then Music.stop(fadeTime) end
 end
 return lease
end
-- Production callers log missing audio without blocking gameplay.
function Music.play(owner,path,options)
 local lease,why=Music.acquire(owner,path,options)
 if not lease then print('[LSD music] '..tostring(why)) end
 return lease
end
function Music.battle(world,battle,path)
 local monitor=D.Node();monitor:addTo(world)
 local phase,lease
 monitor:schedule(function()
  if phase==battle.phase then return false end
  phase=battle.phase
  if phase=='ready' then lease=Music.play(world,'Music/战斗准备.mp3')
  elseif phase=='playing' then lease=Music.play(world,path or 'Music/战斗1.mp3')
  elseif phase=='won' or phase=='failed' or phase=='aborted' or phase=='saving' or phase=='save-error' then
   if lease then lease:release(.7);lease=nil end
  end
  return false
 end)
 return monitor
end
function Music.inspect()
 if not current then return {playing=false} end
 return {playing=current.source.playing,path=current.path,volume=current.source.volume,
  targetVolume=current.volume,started=current.started,looping=current.loop}
end
return Music
