-- Actual native widget, controlled emitted events; does not prove OS/IME delivery.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/input-box-buffer-result.json'
local r={status='RUNNING',diagnosticOnly=true,osInput=false,syntheticWidgetEvents=true,cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local make=require('UI.InputBox')
  local tests={
   {'initial-text-survives-attach',function(v)v.box:emit('AttachIME');assert(v.text=='原有姓名','Initial text lost on attach')end,{text='原有姓名'}},
   {'hint-is-not-committed-text',function(v)assert(v.text=='','Hint exposed as committed text')end,{hint='请输入姓名'}},
   {'programmatic-text-setter',function(v)v.text='星河旅人';assert(v.text=='星河旅人');v.box:emit('AttachIME');assert(v.text=='星河旅人')end,{}},
   {'composition-commit-replaces-preedit',function(v)v.box:emit('AttachIME');v.box:emit('TextInput','星');v.box:emit('TextEditing','he',0);v.box:emit('TextEditing','河',0);v.box:emit('TextInput','河');assert(v.text=='星河')end,{}},
   {'detach-discards-uncommitted-preedit',function(v)v.box:emit('AttachIME');v.box:emit('TextInput','星');v.box:emit('TextEditing','he',0);v.box:emit('DetachIME');assert(v.text=='星');v.box:emit('AttachIME');assert(v.text=='星')end,{}},
   {'unicode-backspace-and-submit',function(v)local result;v:slot('Inputed',function(x)result=x end);v.box:emit('AttachIME');v.box:emit('TextInput','星河旅人');v.box:emit('KeyPressed','BackSpace');v.box:emit('KeyPressed','Return');assert(result=='星河旅','UTF8 backspace/submit mismatch')end,{}}
  }
  for _,test in ipairs(tests)do
   local view=make(test[3]);view:addTo(D.Director.ui3D);D.sleep(.1)
   local passed,error=xpcall(function()test[2](view)end,debug.traceback)
   r.cases[#r.cases+1]={name=test[1],passed=passed,error=not passed and error or nil};view:removeFromParent();view=nil;D.sleep(.2);save()
  end
  r.bufferContractPassed=true;for _,case in ipairs(r.cases)do if not case.passed then r.bufferContractPassed=false end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
