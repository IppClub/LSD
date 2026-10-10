local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Font'})do D.Content:insertSearchPath(1,p)end
D.Content:save(root..'/Test/ambush-anchor-result.json','{"status":"RUNNING"}')
D.thread(function()
 D.Cache:loadAsync('spine:dashanxiao-release')
 local m=D.Spine('dashanxiao-release');m:addTo(D.Director.entry);m:play('ambush2',false)
 local started=D.App.runningTime;while D.App.runningTime-started<.4 do D.sleep(.01)end;m.speed=0
 local refs=D.json.decode(D.Content:load(root..'/Data/Combat/big-shan-release.json')).front.refs;local x,y=0,0
 for _,ref in ipairs(refs)do local p=m:getKey(ref.key);x=x+p.x*ref.weight;y=y+p.y*ref.weight end
 D.Content:save(root..'/Test/ambush-anchor-result.json',D.json.encode({status='PASS',x=x,y=y,time=D.App.runningTime-started}))
end)
