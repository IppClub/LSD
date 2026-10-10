-- Temporary combat ownership only; never edit equipment/inventory persistence.
local D=require('Dora');local M={};local owners=setmetatable({},{__mode='k'});local holders=setmetatable({},{__mode='k'})
function M.release(lease,reason)
 if not lease or not lease.active then return false end
 lease.active=false;lease.reason=reason or 'RETURNED';lease.returnedAt=D.App.runningTime
 owners[lease.owner]=nil;holders[lease.holder]=nil
 if not lease.ownerGone then
  lease.owner:slot('Cleanup'):remove(lease.onOwnerRemoved)
  lease.owner.data.weaponDisarmed=false
  if lease.owner.playable:getSlot('pistol')==lease.original then lease.original.scaleX=lease.scaleX end
 end
 if not lease.holderGone then
  lease.holder:slot('Cleanup'):remove(lease.onHolderRemoved)
  if lease.holder.playable:getSlot('pistol')==lease.borrowed then lease.holder.playable:setSlot('pistol',nil)end
 end
 if lease.monitor then local monitor=lease.monitor;lease.monitor=nil;monitor:removeFromParent()end
 if not lease.ownerGone then lease.owner:emit('Combat.WeaponState',{state='returned',at=lease.returnedAt,weapon=lease.asset,reason=lease.reason,started=lease.started,expires=lease.expires})end
 return true
end
function M.take(owner,holder,options)
 options=options or {}
 if options.valid and not options.valid()then return nil,'NOT_AVAILABLE'end
 if owner==holder or owners[owner] or holders[holder] or owner.data.weaponDisarmed then return nil,'ALREADY_HELD'end
 local asset,look=owner.data.combatWeaponAsset,owner.data.combatWeaponLook;local gun=owner.playable:getSlot('pistol')
 if not asset or not gun or gun.scaleX==0 then return nil,'NO_WEAPON'end
 if holder.playable:getSlot('pistol')then return nil,'HOLDER_ARMED'end
 local duration=options.duration or 6;assert(duration>0 and duration<math.huge,'Invalid disarm duration')
 local borrowed=assert(D.Spine(asset));borrowed.look=look;borrowed.scaleX=gun.scaleX;borrowed.scaleY=gun.scaleY*(options.leftAuthored and -1 or 1)
 local lease={owner=owner,holder=holder,original=gun,borrowed=borrowed,scaleX=gun.scaleX,asset=asset,look=look,active=true,started=D.App.runningTime,expires=D.App.runningTime+duration}
 owners[owner]=lease;holders[holder]=lease;owner.data.weaponDisarmed=true;owner.data.weaponRevision=(owner.data.weaponRevision or 0)+1;gun.scaleX=0;holder.playable:setSlot('pistol',borrowed)
 -- Keep the original node alive; removing a slot cleans its native node and
 -- would make returning that same weapon invalid.
 lease.onOwnerRemoved=function()lease.ownerGone=true;M.release(lease,'OWNER_REMOVED')end
 lease.onHolderRemoved=function()lease.holderGone=true;M.release(lease,'HOLDER_REMOVED')end
 owner:slot('Cleanup',lease.onOwnerRemoved);holder:slot('Cleanup',lease.onHolderRemoved)
 owner:emit('Combat.WeaponState',{state='taken',at=lease.started,weapon=asset,started=lease.started,expires=lease.expires})
 local monitor=D.Node();lease.monitor=monitor;monitor:addTo(owner)
 monitor:schedule(function()
  if not lease.active then return true end
  if options.valid and not options.valid()then M.release(lease,'ENCOUNTER_ENDED');return true end
  if D.App.runningTime>=lease.expires then M.release(lease,'EXPIRED');return true end
  return false
 end)
 return lease
end
return M
