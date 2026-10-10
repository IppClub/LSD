-- Native regression of capped dialogue review, with actual production UI nodes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/optimization-review-ui-result.json'
local r={status='RUNNING',controlledFixture=true,osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local view=require('UI.Story')(require('Story.Catalog')['factory-encounter'].file)
  view:addTo(D.Director.ui3D);view.visible=true;view.reviewVisible=true;D.sleep(.1)
  for i=1,150 do view:pushReview('回顾检查',tostring(i))end
  view:alignLayout();D.sleep(.05)
  local first=view.reviewArea.view.children:get(1)
  local oldChildren=view.reviewArea.view.children.count
  view:alignLayout();assert(view.reviewArea.view.children:get(1)==first,'Unchanged review rebuilt')
  view:pushReview('回顾检查','151');view:alignLayout();D.sleep(.05)
  assert(#view._reviews==150 and view._reviews[1].text=='2')
  local function contains(text)
   local found=false
   view.reviewArea.view.children:each(function(row)
    if row.children then row.children:each(function(n)if n.text==text then found=true end end)end
   end)
   return found
  end
  assert(contains('151'),'Newest capped review not rendered');assert(not contains('1'),'Evicted review still rendered')
  assert(view.reviewArea.view.children.count==oldChildren)
  r.rows=#view._reviews;r.renderedNewest='151';r.unchangedLayoutKeptChildren=true
  view:removeFromParent()
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
