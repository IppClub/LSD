local P={}
function P.validate(p)
 if type(p)~='table'or p.version~=1 or p.rows~=5 or math.abs((p.playerX or 0)-2520)>160 then return false,'ROOF_AFTERMATH_REQUIRED'end
 local a=p.raise;if not a or not a.nativeEvent or (a.seconds or 0)<.78 or (a.height or 0)<60 then return false,'ROOF_ARM_RAISE_REQUIRED'end
 local v=p.vortex;if not v or not v.visible or (v.frames or 0)<60 or (v.seconds or 0)<1.5 then return false,'ROOF_VORTEX_REQUIRED'end
 local d=p.departure;if not d or not d.jumpCompleted or (d.jumpDuration or 0)<=0 or (d.seconds or 0)<1.5 or (d.flightFrames or 0)<50 or (d.maxFrameStep or 100)>25 or not d.hidden or d.endX~=2820 or d.endY~=1530 then return false,'ROOF_DEPARTURE_REQUIRED'end
 return true
end
return P
