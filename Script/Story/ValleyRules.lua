-- Original 2-12 lists five optional activities; mechanics below are adaptation choices.
local R={ids={'fish','farm','peach','chicken','language'},growthSeconds=5}
R.specs={fish={title='鱼塘摸鱼',x=3400,item='valley-fish',amount=3},farm={title='田间劳作',x=4700,item='valley-grain',amount=3},peach={title='桃林赏花',x=6100,item='peach-memento',amount=1},chicken={title='追逐野鸡',x=7800,item='valley-eggs',amount=2},language={title='学习怪物语',x=9300,item='monster-language',amount=1}}
R.lessons={
 {speech='叽里咕噜安布拉斯……',answers={'你这个外乡人从哪里来？','现在很饿，想去吃饭。','要离开桃源谷。'},correct=1},
 {speech='密卡斯密卡斯……',answers={'第一次见面的客人。','现在很饿，想去吃饭。','向族人道别。'},correct=2},
 {speech='斯密卡斯，乌路利亚……',answers={'邀请大家去桃林赏花。','好朋友留下来吃饭。','地面同类受实验的情绪污染。'},correct=3}
}
function R.initial(id)
 if id=='fish' or id=='peach' then return {marks={false,false,false}} end
 if id=='chicken' then return {marks={false,false}} end
 if id=='farm' then return {plots={0,0,0},watered={0,0,0}} end
 if id=='language' then return {correct=0} end
end
local function integer(n,lo,hi) return type(n)=='number' and n%1==0 and n>=lo and n<=hi end
function R.validate(id,s)
 if not R.specs[id] or type(s)~='table' then return false end
 if id=='language' then return integer(s.correct,0,3) end
 if id=='farm' then
  if type(s.plots)~='table' or #s.plots~=3 or type(s.watered)~='table' or #s.watered~=3 then return false end
  for i=1,3 do if not integer(s.plots[i],0,3) or not integer(s.watered[i],0,9007199254740991) or (s.plots[i]<2 and s.watered[i]~=0) or (s.plots[i]>=2 and s.watered[i]==0) then return false end end
 else
  local n=id=='chicken' and 2 or 3
  if type(s.marks)~='table' or #s.marks~=n then return false end
  for i=1,n do if type(s.marks[i])~='boolean' then return false end end
 end
 return true
end
function R.progress(id,s)
 if not R.validate(id,s) then return nil end
 if id=='language' then return s.correct,3 end
 local n=0
 if id=='farm' then for _,v in ipairs(s.plots) do n=n+v end;return n,9 end
 for _,v in ipairs(s.marks) do if v then n=n+1 end end;return n,id=='chicken' and 2 or 3
end
function R.complete(id,s) local n,total=R.progress(id,s);return n~=nil and n==total end
function R.monotonic(id,old,new)
 if not R.validate(id,old) or not R.validate(id,new) then return false end
 if id=='language' then return new.correct>=old.correct end
 if id=='farm' then for i=1,3 do if new.plots[i]<old.plots[i] or (old.watered[i]>0 and new.watered[i]~=old.watered[i]) then return false end end
 else for i,v in ipairs(old.marks) do if v and not new.marks[i] then return false end end end
 return true
end
return R
