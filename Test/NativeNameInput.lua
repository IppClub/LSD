-- Actual native input is supplied through CUA, never a synthetic TextInput/Inputed event.
local D=require("Dora")
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,"Script"),D.Path(root,"Image"),D.Path(root,"Font")}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time()); local out=D.Path(root,"Test","native-name-input-result.txt")
D.Content:save(out,"LSD_NATIVE_NAME_RUNNING runId="..id.."\n")
D.Director.clearColor=D.Color(0xff172235)
local view=require("UI.InputBox")({hint="请输入中文测试姓名，回车确认"}); view.tag="native-name-qa"; view:addTo(D.Director.ui3D)
view:slot("Inputed",function(name)
 local ok=name=="星河旅人"
 local result="LSD_NATIVE_NAME_"..(ok and "PASS clipboardChinese=true utf8Text=true nativeSubmit=true" or "FAIL submitted="..tostring(name)).." runId="..id
 print(result); D.Content:save(out,result.."\n")
end)
