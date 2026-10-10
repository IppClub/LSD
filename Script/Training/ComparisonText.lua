local C={}
function C.verdict(candidate,baseline)
 local function compare(a,b,tolerance)if math.abs(a-b)<=tolerance then return 0 end;return a>b and 1 or -1 end
 local scores={compare(candidate.wins,baseline.wins,0),compare(candidate.health,baseline.health,.5),compare(baseline.seconds,candidate.seconds,.05)}
 local better,worse=false,false
 for _,score in ipairs(scores)do better=better or score>0;worse=worse or score<0 end
 if better and not worse then return '本轮候选整体优于基础 AI，可结合动作表现决定是否采用。'end
 if worse and not better then return '本轮基础 AI 表现更好，建议继续训练后再比较。'end
 if not better and not worse then return '本轮结果接近，可结合动作表现决定是否采用。'end
 return '胜率、生命与用时各有取舍，请结合动作表现选择。'
end
return C
