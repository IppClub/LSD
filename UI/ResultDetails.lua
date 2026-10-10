-- Populate the authored success/failure layouts; never invent reward items.
local D=require('Dora');local M={}
function M.economyText(e,mode)
 if not e then return '资源账单尚未接入\n本场未启用行动物资扣费' end
 if mode=='virtual' then return string.format('虚拟演练账单\n模拟消耗  %d（含整备）\n未用补给价值  %d\n不扣真实物资，不发放任务收入',e.cost,e.refund)end
 return string.format('任务收入  %+d\n实际成本  -%d\n净收益  %+d%s\n未用补给退回  %d\n结余物资  %d',e.income,e.cost,e.net,e.net<0 and '（亏损）' or '',e.refund,e.balanceAfter)
end
local actors={mentor='导师',ninilite='妮妮莉特',wuyun='乌云'}
local items={smoke='烟雾',flare='火光',kinetic='实弹',emp='EMP',laser='激光',blade='近战',grenade='手雷',medical='医疗'}
function M.breakdown(e,mode)
 if not e or not e.lines then return ''end
 local rows={'消耗明细（含整备费）'}
 for _,line in ipairs(e.lines)do
  rows[#rows+1]=string.format('%s · %s：%d×%d + 整备%d = %d',actors[line.actor]or line.actor,items[line.item]or line.item,line.used,line.unit,line.deployment,line.cost)
  rows[#rows+1]=string.format(mode=='virtual' and '余量%d，未用价值%d%s' or '余量%d，返还%d%s',line.remaining,line.refund,line.usedByOthers>0 and string.format('；其中他人消耗%d',line.usedByOthers)or '')
 end
 return table.concat(rows,'\n')
end
local function label(parent,text,size,width,x,y)
 local l=assert(D.Label('SourceHanSansCN-Regular',size));l.textWidth=width;l.alignment='Left';l.anchor=D.Vec2(0,1);l.text=text;l.position=D.Vec2(x,y);l:addTo(parent);return l
end
function M.success(view,rewardArea,memberArea,args)
 view.resultLayout='Settlement';view.economy=args.economy;view.economyMode=args.economyMode
 local text=M.economyText(args.economy,args.economyMode)
 local detail=M.breakdown(args.economy,args.economyMode);if detail~=''then text=text..'\n\n'..detail end
 view.economyLabel=label(rewardArea.view,text,42,900,20,480)
 rewardArea.viewSize=D.Size(964,math.max(500,view.economyLabel.height+40));view.economyArea=rewardArea
 local report=(args.reportText or '')..'\n\n'..(args.storyText or '')
 view.reportLabel=label(memberArea.view,report,42,1050,25,810)
 view.reportArea=memberArea
 -- Run after the authored viewport has been laid out. Horizontal member-card
 -- alignment centers a long label and resets its scroll height to 843.
 function view:layoutResultDetails(memberWidth)
  local width=math.max(1,memberWidth-50)
  view.reportLabel.textWidth=width
  memberArea:resetSize(memberWidth,843,memberWidth,math.max(843,view.reportLabel.height+40))
  view.reportLabel.position=D.Vec2(25+memberArea.offset.x,823+memberArea.offset.y)
  -- The resource breakdown also extends below the initial viewport.
  rewardArea:resetSize(964,500,964,math.max(500,view.economyLabel.height+40))
  view.economyLabel.position=D.Vec2(20+rewardArea.offset.x,480+rewardArea.offset.y)
 end
end
function M.failure(view,center,args)
 view.resultLayout='MissionFail';view.economy=args.economy;view.economyMode=args.economyMode
 local e=args.economy
 local text=e and string.format('任务收入 %+d　消耗 -%d　净收益 %+d\n退回 %d　结余 %d',e.income,e.cost,e.net,e.refund,e.balanceAfter)or '资源账单尚未接入，本场未启用行动物资扣费'
 if e and args.economyMode=='virtual' then text=string.format('虚拟演练：模拟消耗 %d（含整备）　未用补给价值 %d\n不扣真实物资，不发放任务收入',e.cost,e.refund)end
 view.economyLabel=label(center,text,38,1800,-900,-430)
 -- Show the actual outcome cause before the player opens the detailed report.
 if type(args.storyText)=='string'and args.storyText~=''then
  view.failureReasonLabel=label(center,args.storyText,38,1800,-900,170)
  view.failureReasonLabel.color3=D.Color3(0xffcf72)
 end
 -- Preserve the authored failure artwork; open the full report on demand.
 local detail=M.breakdown(e,args.economyMode)
 local report=(args.reportText or '')..'\n'..(args.storyText or '')..(detail~=''and '\n\n'..detail or '')
 local Button=require('UI.PropButton')
 view.reportButton=Button({text='查看战报',x=-300,y=610});view.reportButton:addTo(center)
 local popup
 popup=require('UI.DisarmComparison')({title=(args.missionTitle or '任务')..' · 战斗复盘',backText='返回结算',summary=report,closed=function()
  popup:removeFromParent(false);popup.visible=false;popup:addTo(view)
  view.reportPanel=nil;view.visible=true
 end})
 -- Keep one real report label/area for existing result controllers and retries.
 popup.visible=false;popup:addTo(view);view.reportLabel=popup.label;view.reportArea=popup.area
 function view:setReportText(text)popup:setText(text)end
 view.reportButton:slot('Tapped',function()
  if view.reportPanel then return end
  popup:removeFromParent(false);popup.visible=true
  view.visible=false;view.reportPanel=popup;popup:addTo(D.Director.ui3D);popup:alignLayout()
 end)
 view:slot('Cleanup',function()if popup.parent then popup:removeFromParent()end;view.reportPanel=nil end)
 view.againButton=Button({text=args.againText or '重新配置',x=-600,y=-650});view.againButton:addTo(center)
 view.baseButton=Button({text=args.baseText or '返回基地',x=300,y=-650});view.baseButton:addTo(center)
end
return M
