-- A bounded, repeatable sorting job; no ammunition or mission entry required.
local D=require('Dora');local S=require('Economy.Store');local Loadout=require('Economy.Loadout')
local R={ceiling=assert(Loadout.quote(Loadout.defaults(),{learner='ninilite',wuyun=true})).total,reward=60}
R.tasks={{item='kinetic',text='把实弹手枪归入实弹补给箱',art='kinetic-pistol'},{item='emp',text='把EMP手枪归入EMP补给箱',art='emp-pistol'},{item='laser',text='把激光手枪归入激光补给箱',art='laser-pistol'}}
local busy=false
function R.load()
 if not S.open()then return nil,'READ_FAILED'end
 if D.DB:exec('CREATE TABLE IF NOT EXISTS lsd.Game0SupplyRecovery(id INTEGER PRIMARY KEY CHECK(id=1),round INTEGER NOT NULL CHECK(round>=0),stage INTEGER NOT NULL CHECK(stage BETWEEN 0 AND 2))')<0 or D.DB:exec('INSERT OR IGNORE INTO lsd.Game0SupplyRecovery VALUES(1,0,0)')<0 then return nil,'READ_FAILED'end
 local rows=D.DB:query('SELECT round,stage FROM lsd.Game0SupplyRecovery WHERE id=1');local wallet=S.wallet()
 if not rows or not rows[1]or not wallet then return nil,'READ_FAILED'end
 return {round=rows[1][1],stage=rows[1][2],balance=wallet.available,eligible=wallet.available<R.ceiling}
end
function R.sortAsync(round,stage,item)
 if busy then return nil,'BUSY'end
 local state,why=R.load();if not state then return nil,why end
 if state.round~=round or state.stage~=stage then return nil,'STALE_STEP'end
 if not state.eligible then return nil,'SUPPLIES_SUFFICIENT'end
 if R.tasks[stage+1].item~=item then return nil,'WRONG_CRATE'end
 local active,why=S.active();if active then return nil,'MISSION_ACTIVE'elseif why~='NOT_RECORDED'then return nil,why end
 local wallet,why=S.wallet();if not wallet then return nil,why end
 local complete=stage==2;local reward=complete and math.min(R.reward,R.ceiling-wallet.available)or 0
 local operations={
  {'UPDATE lsd.Game0SupplyWallet SET available=available+?,revision=CASE WHEN revision=? AND NOT EXISTS(SELECT 1 FROM lsd.Game0SupplyAttempts WHERE status=\'active\') THEN revision+1 ELSE -1 END WHERE id=1',{{reward,wallet.revision}}},
  {'UPDATE lsd.Game0SupplyRecovery SET round=?,stage=CASE WHEN round=? AND stage=? THEN ? ELSE -1 END WHERE id=1',{{complete and round+1 or round,round,stage,complete and 0 or stage+1}}}}
 busy=true;local ok=D.DB:transactionAsync(operations);busy=false
 if not ok then return nil,'WRITE_FAILED'end
 local nextState,why=R.load();if not nextState then return nil,why end;nextState.reward=reward;return nextState
end
return R
