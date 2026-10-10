-- Native playback contract test. Run only after the ongoing training soak.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),audibleReview=false}
local out=D.Path(root,'Test/music-lifecycle-result.json')
D.Content:save(out,D.json.encode(report))
D.thread(function()
 local music=require('System.Music');local owners={};local voices={}
 -- Retain native sources only in this test, so isPlaying proves voice shutdown
 -- independently of the service clearing its own current record.
 local function capture()
  for i=1,20 do
   local name,value=debug.getupvalue(music.inspect,i)
   if not name then break end
   if name=='current' and value then
    voices[#voices+1]=value.source;return value.source
   end
  end
  error('Cannot inspect native music source')
 end
 local function owner()local n=D.Node();n:addTo(D.Director.entry);owners[#owners+1]=n;return n end
 local ok,why=xpcall(function()
  local a=owner();local first=assert(music.acquire(a,'Music/探索.mp3',{fade=.15}))
  D.sleep(.25);local initial=music.inspect();local exploreVoice=capture();assert(exploreVoice.playing and initial.playing and initial.volume>.99)
  a:removeFromParent()
  local b=owner();assert(music.acquire(b,'Music/探索.mp3',{fade=.15}))
  assert(music.inspect().started==initial.started,'Same song restarted')
  first:release(0);D.sleep(.2);assert(music.inspect().playing,'Old owner stopped current lease')
  local c=owner();assert(music.acquire(c,'Music/训练场.mp3',{fade=.15}))
  b:removeFromParent();D.sleep(.25)
  local training=music.inspect();local trainingVoice=capture();assert(not exploreVoice.playing,'Old song still audible after fade');assert(training.playing and training.path=='Music/训练场.mp3')
  assert(math.abs(training.volume-.343)<.005,'Music level not applied')
  c:removeFromParent();D.sleep(.7);assert(not music.inspect().playing and not trainingVoice.playing,'Cleanup left native voice playing')
  local d=owner()
  for _,path in ipairs({'Music/战斗1.mp3','Music/战斗2.mp3','Music/探索.mp3'})do
   assert(music.acquire(d,path,{fade=.1}));capture();D.sleep(.02)
  end
  D.sleep(.2);assert(music.inspect().path=='Music/探索.mp3' and music.inspect().playing)
  d:removeFromParent();D.sleep(.7);assert(not music.inspect().playing)
  for _,source in ipairs(voices)do assert(not source.playing,'Native voice survived rapid switching/cleanup')end
  report.nativeVoicesStopped=#voices
  report.sameTrackContinues=true;report.staleOwnerIgnored=true;report.levelApplied=true
  report.rapidSwitchLatest=true;report.cleanupReleased=true;report.status='PASS'
 end,debug.traceback)
 music.stop(0)
 for _,source in ipairs(voices)do source:stop(0)end
 for _,n in ipairs(owners)do if n.parent then n:removeFromParent()end end
 if not ok then report.status='FAIL';report.error=why end
 D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
