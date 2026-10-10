-- Standalone native validation entry: no save access, no fabricated combat.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
D.thread(function()
 local report={status='RUNNING',assets={},scope='Native load, finite playback and authored events only'}
 local out=D.Path(root,'Test/all-enemy-assets-result.json')
 local function save()D.Content:save(out,D.json.encode(report))end
 save()
 local ok,err=xpcall(function()
  local catalog=require('Enemy.Assets');local names={};for name in pairs(catalog)do names[#names+1]=name end;table.sort(names)
  local node=D.Node();node:addTo(D.Director.entry)
  for _,asset in ipairs(names)do
   D.Cache:loadAsync('spine:'..asset)
   local m=assert(D.Spine(asset),asset);m.recovery=.2;m.position=D.Vec2(D.App.visualSize.width/2,250);m:addTo(node)
   local item={asset=asset,animations={},looks=D.Spine:getLooks(asset)};report.assets[#report.assets+1]=item
   local available={};for _,name in ipairs(D.Spine:getAnimations(asset))do available[name]=true end
   for _,required in ipairs({'idle','hit','lose',catalog[asset].move})do assert(available[required],asset..' missing '..required)end
   for _,parts in pairs(catalog[asset].skills)do for _,name in ipairs(parts)do assert(available[name],asset..' missing '..name)end end
   D.sleep(.1)
   local anims={};for name in pairs(available)do anims[#anims+1]=name end;table.sort(anims)
   for _,name in ipairs(anims)do
    local entry={name=name,events={}};item.animations[#item.animations+1]=entry
    local done=false;local started=D.App.runningTime
    m:slot('attack'):set(function()entry.events[#entry.events+1]={name='attack',time=D.App.runningTime-started}end)
    m:slot('AnimationEnd'):set(function(n)if n==name then done=true;entry.completed=D.App.runningTime-started end end)
    entry.duration=m:play(name,false);assert(entry.duration>0,asset..'/'..name..' zero duration')
    while not done do assert(D.App.runningTime-started<entry.duration+2,asset..'/'..name..' never ended');D.sleep(.01)end
    assert(entry.completed>=entry.duration-.05,asset..'/'..name..' ended early')
    m:play('idle',true);D.sleep(.22);save()
   end
   m:removeFromParent();save()
  end
  node:removeFromParent()
 end,debug.traceback)
 report.status=ok and 'PASS' or 'FAIL';report.error=ok and nil or err;save();print('LSD_ALL_ENEMY_ASSETS_'..report.status)
end)
