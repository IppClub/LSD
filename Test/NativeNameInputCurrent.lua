-- Actual OS actions supplied only by CUA. No emitted input/IME events.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/native-name-input-current-result.json'
local r={status='RUNNING',osInput=true,syntheticWidgetEvents=false,expected='星河旅人',textInputs={},textEditing={},keys={},started=D.App.totalTime,fullImeCompositionProven=false,fullGameComplete=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.Director.clearColor=D.Color(0xff172235)
local view=require('UI.InputBox')({hint='原生中文输入测试：输入星河旅人，回车确认'});view.tag='native-name-qa';view:addTo(D.Director.ui3D)
view.box:slot('TextInput',function(text)r.textInputs[#r.textInputs+1]={text=text,at=D.App.totalTime};save()end)
view.box:slot('TextEditing',function(text,start)r.textEditing[#r.textEditing+1]={text=text,start=start,at=D.App.totalTime};save()end)
view.box:slot('KeyPressed',function(key)r.keys[#r.keys+1]={key=key,at=D.App.totalTime};save()end)
view:slot('Inputed',function(name)
 r.submitted=name;r.committedGetter=view.text;r.elapsed=D.App.totalTime-r.started;save()
 D.thread(function()
  local path=D.Path(D.Content.writablePath,'native-name-submitted.tga');D.App:saveScreenshot(path);D.sleep(.4);r.screenshot=path
  r.status=name==r.expected and view.text==r.expected and'PASS'or'FAIL';save()
 end)
end)
