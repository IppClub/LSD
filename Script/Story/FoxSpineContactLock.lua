-- Candidate-only foot anchor. Call update AFTER native Spine animation updates.
-- The settling displacement is real model movement; scene controllers must account
-- for it before adopting this in production. It does not solve the other foot's step.
local Lock={}
local names={'contactL/contactL','contactR/contactR'}
function Lock.begin(model,duration)
 local a,b=model:getKey(names[1]),model:getKey(names[2])
 assert(a.y>1 and b.y>1,'Fox Spine contact points are missing')
 local side=a.y<=b.y and 1 or 2
 local p=side==1 and a or b
 return {name=names[side],anchorX=model.x+p.x*model.scaleX,minimumDuration=duration,elapsed=0,stableTime=0,stableFrames=0,lastPointX=p.x,
  startX=model.x,maxError=0,frames=0}
end
function Lock.update(lock,model,dt)
 if not lock then return true end
 local p=model:getKey(lock.name)
 model.x=lock.anchorX-p.x*model.scaleX
 lock.maxError=math.max(lock.maxError,math.abs(model.x+p.x*model.scaleX-lock.anchorX))
 lock.frames=lock.frames+1
 -- A lock can be created during this frame, after its elapsed dt. Do not count
 -- that whole frame as recovery time, especially when the app is backgrounded.
 if lock.frames==1 then dt=0 end
 lock.elapsed=lock.elapsed+dt
 if math.abs(p.x-lock.lastPointX)<.01 then lock.stableTime=lock.stableTime+dt;lock.stableFrames=lock.stableFrames+1 else lock.stableTime=0;lock.stableFrames=0 end
 lock.lastPointX=p.x
 lock.settleDistance=model.x-lock.startX
 lock.settled=lock.elapsed>=lock.minimumDuration and lock.stableTime>=.06 and lock.stableFrames>=3
 lock.timedOut=lock.elapsed>3
 return lock.settled or lock.timedOut
end
return Lock
