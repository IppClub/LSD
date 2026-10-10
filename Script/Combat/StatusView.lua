-- Uses the existing HP/AP bar artwork. Only authoritative damage results update
-- feedback; this view neither selects hit regions nor changes combat state.
local D=require('Dora')
local View={};View.__index=View
function View.new(damage,title,partNames)
 local self=setmetatable({damage=damage,partNames=partNames or {},effects={},closed=false},View)
 self.node=D.Node();self.node.size=D.Size(360,110)
 local name=assert(D.Label('SourceHanSansCN-Regular',22));name.text=title;name.position=D.Vec2(0,88);name:addTo(self.node)
 local bar,hp,ap=require('UI.View.StatusBar').default(1,0,0xffffff)
 self.hpBar=hp;self.apBar=ap;bar.scaleX=3.2;bar.position=D.Vec2(0,38);bar:addTo(self.node)
 self.health=assert(D.Label('SourceHanSansCN-Regular',18));self.health.position=D.Vec2(0,68);self.health:addTo(self.node)
 self.armor=assert(D.Label('SourceHanSansCN-Regular',18));self.armor.position=D.Vec2(0,18);self.armor:addTo(self.node)
 self:refresh();self.node:slot('Cleanup',function()self:close()end);return self
end
-- Opt-in per-part memory: update only from actual damage events, never from
-- unobserved geometry or aggregate armor. Existing single-part users stay compact.
function View:observeParts(ids)
 self.observedParts={};self.partLabels={};self.partOrder=ids
 local backdrop=D.DrawNode();backdrop.order=-1
 backdrop:drawPolygon({D.Vec2(-245,-64),D.Vec2(245,-64),D.Vec2(245,114),D.Vec2(-245,114)},D.Color(0xeb101b28))
 backdrop:addTo(self.node)
 for i,id in ipairs(ids)do
  assert(self.damage.parts[id],'Unknown observed part')
  local label=assert(D.Label('SourceHanSansCN-Regular',16))
  label.alignment='Left';label.anchor=D.Vec2(0,1)
  label.position=D.Vec2(-175+((i-1)%3)*155,-4-math.floor((i-1)/3)*26)
  label:addTo(self.node);self.partLabels[id]=label
 end
 self:updateObservedParts()
end
function View:updateObservedParts()
 if not self.partLabels then return end
 for _,id in ipairs(self.partOrder)do
  local label=self.partLabels[id];local observed=self.observedParts[id]
  local name=self.partNames[id]or id
  local text=name..(not observed and ' · 未观察'or observed.ap<=0 and ' · 已破甲'or string.format(' · 护甲 %.0f',observed.ap))
  if label.text~=text then label.text=text end
  label.color3=D.Color3(not observed and 0xb9c7da or observed.ap<=0 and 0xffd074 or 0xffffff)
 end
end
function View:refresh(part)
 if self.closed then return end
 if part and self.damage.parts[part]then self.part=part end
 local d=self.damage;local p=self.part and d.parts[self.part]
 self.hpBar.scaleX=math.max(0,math.min(1,d.hp/d.maxHP))
 self.hpBar.color3=D.Color3(d.hp/d.maxHP<=.25 and 0xff6b6b or 0xffffff)
 local health=string.format('生命 %.0f / %.0f',d.hp,d.maxHP)
 if self.health.text~=health then self.health.text=health end
 self.apBar.visible=p~=nil and p.maxAP>0
 if p then
  self.apBar.scaleX=p.maxAP>0 and math.max(0,math.min(1,p.ap/p.maxAP)) or 0
  local armor=(self.partNames[self.part] or self.part)..(p.maxAP==0 and ' · 无护甲' or p.ap<=0 and ' · 已破甲' or string.format(' · 护甲 %.0f / %.0f',p.ap,p.maxAP))
  if self.armor.text~=armor then self.armor.text=armor end
 elseif self.armor.text~='命中部位后显示局部护甲'then self.armor.text='命中部位后显示局部护甲' end
end
function View:hit(event,world)
 if self.closed or event.target~=self.damage.id then return end
 if self.observedParts and self.damage.parts[event.part]then
  self.observedParts[event.part]={ap=event.apAfter,at=D.App.runningTime}
  self:updateObservedParts()
 end
 self:refresh(event.part)
 -- Bounded short-lived contact feedback. Armour and health stay distinct.
 if #self.effects>=24 then local old=table.remove(self.effects,1);if old.parent then old:removeFromParent()end end
 local root=D.Node();root.position=D.Vec2(event.position.x,event.position.y);root:addTo(world)
 local label=assert(D.Label('SourceHanSansCN-Regular',18));label:addTo(root)
 local text={};if event.armorDamage>0 then text[#text+1]=string.format('护甲 -%.0f',event.armorDamage)end
 if event.healthDamage>0 then text[#text+1]=string.format('生命 -%.0f',event.healthDamage)end
 if event.armorBroken then text[#text+1]='破甲' end
 label.text=#text>0 and table.concat(text,'  ') or '阻挡'
 local sparks=D.DrawNode();sparks:addTo(root)
 local color=D.Color(event.armorBroken and 0xffffd074 or event.healthDamage>0 and 0xffff8a8a or 0xff8dbef3)
 for i=0,5 do local a=i*math.pi/3;sparks:drawSegment(D.Vec2(math.cos(a)*5,math.sin(a)*5),D.Vec2(math.cos(a)*16,math.sin(a)*16),2,color)end
 self.effects[#self.effects+1]=root;local elapsed=0
 root:schedule(function(dt)
  elapsed=elapsed+dt;label.y=20+elapsed*25;root.opacity=math.max(0,1-elapsed/.65)
  if elapsed>=.65 then root:removeFromParent();for i,n in ipairs(self.effects)do if n==root then table.remove(self.effects,i);break end end;return true end
  return false
 end)
end
function View:close()
 if self.closed then return end;self.closed=true
 for _,n in ipairs(self.effects)do if n.parent then n:removeFromParent()end end
 self.effects={}
end
return View
