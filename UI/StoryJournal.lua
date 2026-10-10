-- [xml]: UI/StoryJournal.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local SolidRect = require("UI.View.Shape.SolidRect") -- 3
local PhoneMessageTab = require("UI.PhoneMessageTab") -- 4
local PropButton = require("UI.PropButton") -- 5
local FullScreenMask = require("UI.FullScreenMask") -- 6
return function(args) -- 1
local _ENV = Dora(args) -- 1
local journal = AlignNode{isRoot = true, inUI = true} -- 7
local item1 = FullScreenMask{} -- 8
journal:addChild(item1) -- 8
local panel = AlignNode{vAlign = "Center", hAlign = "Center"} -- 9
journal:addChild(panel) -- 9
local item2 = SolidRect{color = 0xef101b28, width = 2940, y = -665, height = 1330, x = -1470} -- 10
panel:addChild(item2) -- 10
local sprite1 = Sprite("phone.clip|phone_bg") -- 11
sprite1.x = -950 -- 11
sprite1.scaleX = 0.8 -- 11
sprite1.scaleY = 0.8 -- 11
panel:addChild(sprite1) -- 11
local label1 = Label("SourceHanSansCN-Regular",62) -- 12
label1.x = -950 -- 12
label1.y = 520 -- 12
label1.text = panelTitle or '通讯与调查' -- 12
panel:addChild(label1) -- 12
local mailButton = PhoneMessageTab{scaleY = 0.8, scaleX = 0.8, x = -950, msg = row1Status or mailStatus or '', avatar = "phone.clip|phone_icon_com_3", y = 310, username = row1Title or '羽凌灵'} -- 13
panel:addChild(mailButton) -- 13
journal.mailButton = mailButton -- 13
local researchButton = PhoneMessageTab{scaleY = 0.8, scaleX = 0.8, username = row2Title or '妮妮莉特', y = 155, msg = row2Status or researchStatus or '', avatar = "phone.clip|phone_icon_com_3", x = -950} -- 14
panel:addChild(researchButton) -- 14
journal.researchButton = researchButton -- 14
local archiveButton = PhoneMessageTab{scaleY = 0.8, scaleX = 0.8, username = row3Title or '暗格资料', y = 0, msg = row3Status or archiveStatus or '', avatar = "phone.clip|phone_icon_collect_3", x = -950} -- 15
panel:addChild(archiveButton) -- 15
journal.archiveButton = archiveButton -- 15
local stationButton = PhoneMessageTab{scaleY = 0.8, scaleX = 0.8, username = row4Title or '站台部署', y = -155, msg = row4Status or stationStatus or '', avatar = "phone.clip|phone_icon_collect_3", x = -950} -- 16
panel:addChild(stationButton) -- 16
journal.stationButton = stationButton -- 16
for _,button in ipairs({mailButton,researchButton,archiveButton,stationButton}) do -- 17
button.scaleX=0.8; button.scaleY=0.8 -- 18
-- The legacy tab paints around (0,0); move art inside its actual touch bounds. -- 19
local offset=Vec2(button.width/2,button.height/2) -- 20
button.children:each(function(child) child.position=child.position+offset end) -- 21
end -- 22
mailButton.visible=row1Visible~=false; researchButton.visible=row2Visible~=false; archiveButton.visible=row3Visible~=false; stationButton.visible=row4Visible~=false -- 23
local previousButton = PropButton{scaleY = 0.8, scaleX = 0.8, y = -400, x = -1140, text = "上一页"} -- 24
panel:addChild(previousButton) -- 24
journal.previousButton = previousButton -- 24
local nextButton = PropButton{scaleY = 0.8, scaleX = 0.8, y = -400, x = -730, text = "下一页"} -- 25
panel:addChild(nextButton) -- 25
journal.nextButton = nextButton -- 25
local pageLabel = Label("SourceHanSansCN-Regular",36) -- 26
pageLabel.x = -950 -- 26
pageLabel.y = -505 -- 26
pageLabel.text = pageText or '记录 1 / 1' -- 26
panel:addChild(pageLabel) -- 26
journal.pageLabel = pageLabel -- 26
local detail = Label("SourceHanSansCN-Regular",43) -- 27
detail.anchor = Vec2(0,1) -- 27
detail.x = -380 -- 27
detail.y = 510 -- 27
detail.alignment = "Left" -- 27
detail.textWidth = 1620 -- 27
detail.text = journalText or '' -- 27
panel:addChild(detail) -- 27
journal.detail = detail -- 27
local closeButton = PropButton{y = -530, x = 950, text = closeText or '关闭通讯'} -- 28
panel:addChild(closeButton) -- 28
journal.closeButton = closeButton -- 28
journal:slot("AlignLayout",function(w, h) -- 30
local scale=math.min(h/1563,w/3100); panel.scaleX=scale; panel.scaleY=scale -- 31
end) -- 31
return journal -- 31
end