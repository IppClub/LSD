-- A durable firing decision precedes publishing its projectile to physics.
-- A crash after this commit keeps the shot cost even if its visual never appears.
local D=require('Dora');local Store=require('Economy.Store');local Ledger=require('Economy.Ledger');local Session={};Session.__index=Session
function Session.open(attempt)
 local ledger,why=Store.load(attempt);if not ledger then return nil,why end
 if ledger.status~='active'then return nil,'CLOSED'end
 local serial=0;for id in pairs(ledger.events)do serial=math.max(serial,tonumber(id:match('^fire:(%d+)$')) or 0)end
 return setmetatable({attempt=attempt,isVirtual=false,serial=serial,ledger=ledger,emissions=0,maxCommitSeconds=0,actors=setmetatable({},{__mode="k"}),actorSerial=0},Session)
end
-- The same price/stock rules, with no wallet, reservation or persistent writes.
function Session.virtual(attempt,loadout)
 local quote,why=Ledger.quote(loadout);if not quote then return nil,why end
 local ledger,why=Ledger.new(attempt,loadout,quote.total,0);if not ledger then return nil,why end
 return setmetatable({attempt=attempt,isVirtual=true,serial=0,ledger=ledger,emissions=0,maxCommitSeconds=0,
  actors=setmetatable({},{__mode='k'}),actorSerial=0},Session)
end
function Session:canSpend(owner,item,count)
 local stock=self.ledger.stock[owner..':'..item]
 if self.ledger.status~='active'then return false,'CLOSED'end
 if not stock then return false,'NOT_EQUIPPED'end
 if stock.remaining<(count or 1)then return false,'OUT_OF_SUPPLIES'end
 return true
end
function Session:emit(owner,item,count,performer,step)
 local serial=self.serial+1;local id='fire:'..serial
 local start=D.App.runningTime
 local ledger,why
 if self.isVirtual then
  local ok;ok,why=Ledger.consume(self.ledger,id,owner,item,count,performer,step)
  if ok then ledger=self.ledger end
 else ledger,why=Store.consumeNow(self.attempt,{{id=id,owner=owner,item=item,count=count,performer=performer,step=step}})end
 self.maxCommitSeconds=math.max(self.maxCommitSeconds,D.App.runningTime-start)
 if not ledger then self.lastError=why;return false,why end
 -- An existing ID must never publish a second projectile.
 if why=='ALREADY_RECORDED'then return false,'DUPLICATE_EMISSION'end
 self.lastError=nil;self.serial=serial;self.ledger=ledger;self.emissions=self.emissions+1
 return true,id
end
function Session:closeVirtual(status)
 if not self.isVirtual then return nil,'NOT_VIRTUAL'end
 return Ledger.settle(self.ledger,status)
end
function Session:emitStolen(lease)
 local owner=lease.owner.data.supplyActorId
 local item=({kineticgun='kinetic',empgun='emp'})[lease.asset]
 if not owner or not item then return false,'UNMAPPED_WEAPON_OWNER'end
 local performer=self.actors[lease.holder]
 if not performer then
  self.actorSerial=self.actorSerial+1;performer='enemy:'..self.actorSerial;self.actors[lease.holder]=performer
 end
 return self:emit(owner,item,1,performer)
end
function Session:statusText()
 local key=self.emissions..':'..tostring(self.lastError)
 if self.statusKey==key then return self.cachedStatus end
 self.statusKey=key;local names={['mentor:smoke']='烟雾',['mentor:flare']='火光',['mentor:kinetic']='导师实弹',['ninilite:emp']='妮妮莉特EMP',['wuyun:emp']='乌云EMP',['wuyun:blade']='乌云近战'};local parts={}
 for _,line in ipairs(self.ledger.quote.lines)do parts[#parts+1]=(names[line.key]or line.key)..' '..self.ledger.stock[line.key].remaining end
 self.cachedStatus=(self.isVirtual and '虚拟补给（不扣物资）：'or '补给：')..table.concat(parts,' / ')..' · 已用成本 '..self.ledger.spent
 if self.lastError then self.cachedStatus=self.cachedStatus..(self.lastError=='OUT_OF_SUPPLIES' and ' · 弹药耗尽，请调整战术或撤退' or ' · 消费未能保存，本次攻击未发出')end
 return self.cachedStatus
end
function Session:observation(actor)
 local ammo={};for _,line in ipairs(self.ledger.quote.lines)do if line.actor==actor then ammo[line.item]=self.ledger.stock[line.key].remaining end end
 return {schemaVersion=1,actor=actor,ammo=ammo,spent=self.ledger.spent,reserved=self.ledger.quote.total,budgetLeft=self.ledger.quote.total-self.ledger.spent}
end
function Session:evidence()
 local e={schemaVersion=1,trainable=false,mode=self.isVirtual and 'virtual' or 'mission',attempt=self.attempt,quote=self.ledger.quote,events=self.ledger.events,stock=self.ledger.stock,spent=self.ledger.spent}
 return D.json.decode(D.json.encode(e,false,true),32)
end
return Session
