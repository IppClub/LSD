local D=require('Dora');local Records={}
local residents={{'liyena','李叶娜','侧翼防线'},{'moling','忍冬','诊疗区'},{'moyu','半夏','诊疗区'},{'villywan','万薇莉','计算机操作室'},{'dahuli','狐狸','侦察通道'}}
function Records.build()
 local rows=D.DB:query('SELECT role,duty FROM lsd.Game0StoryAssignments ORDER BY role');if not rows then return nil,'READ_FAILED'end
 local assigned={};for _,row in ipairs(rows)do assigned[row[1]]=row[2]end
 local records={}
 for _,r in ipairs(residents)do if assigned[r[1]]then records[#records+1]={role=r[1],name=r[2],place=r[3],status='deceased',detail='生命信号停止 · 已确认牺牲',duty=assigned[r[1]]}end end
 -- The monitoring dialogue establishes Yu Zijiang's presence in the research area.
 local nodes=D.DB:query("SELECT id FROM lsd.Game0StoryNodes WHERE id IN ('network-warning','ayan-recovery','roof-aftermath')")
 if not nodes then return nil,'READ_FAILED'end
 local facts={};for _,r in ipairs(nodes)do facts[r[1]]=true end
 if facts['network-warning']then records[#records+1]={role='yuzijiang',name='余子绛',place='研发监测区',status='deceased',detail='生命信号停止 · 已确认牺牲'}end
 for _,r in ipairs({{'vika','烛参'},{'vivi','烛商'}})do if assigned[r[1]]then records[#records+1]={role=r[1],name=r[2],place='研究区',status='awaiting-rescue',detail='生命信号仍在 · 等待救援',duty=assigned[r[1]]}end end
 records[#records+1]={role='sunborn',name='林睿哲',place='外部防线',status='active',detail='通讯仍在 · 接手外部防线'}
 if facts['roof-aftermath']then records[#records+1]={role='wuyun',name='乌云',place='后世界',status='departed',detail='此前已离场 · 不在本次伤亡名单'}end
 if facts['ayan-recovery']then records[#records+1]={role='ayan',name='阿岩',place='遗迹城市',status='previously-deceased',detail='此前已牺牲 · 手环记录保留'}end
 return records
end
function Records.saved()
 local rows=D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='academy-loss'")
 if not rows or not rows[1]then return nil,'NOT_RECORDED'end
 local ok,p=pcall(D.json.decode,rows[1][1],32)
 if not ok or not require('Story.AcademyLossProof').validate(p)then return nil,'INVALID_LOSS_RECORD'end
 return p.roster
end
-- Present-day roster overlays earned rescue facts without rewriting the loss snapshot.
function Records.current()
 local roster,why=Records.saved();if not roster then return nil,why end
 local rows=D.DB:query("SELECT id FROM lsd.Game0MissionUnlocks WHERE id='twins-rescued'");if not rows then return nil,'READ_FAILED'end
 if rows[1]then for _,r in ipairs(roster)do if r.role=='vika'or r.role=='vivi'then r.status='rescued';r.place='研究区出口';r.detail='已获救 · 已穿过两段危险区'end end end
 local ending=D.DB:query("SELECT u.id FROM lsd.Game0StoryUnlocks u JOIN lsd.Game0StoryNodes n ON n.id=u.node WHERE u.id='final-story-complete' AND n.id='final-betrayal'")
 if not ending then return nil,'READ_FAILED'end
 if ending[1]then for _,r in ipairs(roster)do if r.role=='sunborn'then r.status='betrayed';r.place='撤离终端';r.detail='袭击导师 · 试图掌握世界的决定权'end end end
 return roster
end
function Records.rescueHint(roster)
 local rescued,waiting=0,false
 for _,r in ipairs(roster)do
  if r.role=='vika'or r.role=='vivi'then
   if r.status=='rescued'then rescued=rescued+1 elseif r.status=='awaiting-rescue'then waiting=true end
  end
 end
 if rescued==2 then return '研究区的双子已获救，救援记录已保存。'end
 if waiting then return '研究区仍有同伴等待救援。'end
 return '研究区人员状态以当前记录为准。'
end
return Records
