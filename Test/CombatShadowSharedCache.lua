local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local S=require('Combat.AimOcclusion')
local function rect(x,y,w,h,id)return{id=id,vertices={{x=x,y=y},{x=x+w,y=y},{x=x+w,y=y+h},{x=x,y=y+h}},bounds={minX=x,maxX=x+w,minY=y,maxY=y+h}}end
local parts={rect(5,-3,.2,6,'wall'),rect(10,-4,1,8,'target')};local o={x=0,y=0}
local proof=assert(S.build(o,parts,'target',30));assert(proof({x=10,y=0}))
assert(proof==S.build({x=0,y=0},parts,'target',30),'same pose and muzzle should reuse')
parts[1].enabled=false;assert(S.build(o,parts,'target',30)==nil)
parts[1].enabled=true;local enabled=assert(S.build(o,parts,'target',30));assert(enabled~=proof)
parts[1],parts[2]=parts[2],parts[1];local reordered=assert(S.build(o,parts,'target',30));assert(reordered~=enabled)
parts[2].bounds.minX=100;assert(S.build(o,parts,'target',30)==nil);parts[2].bounds.minX=5
local restored=assert(S.build(o,parts,'target',30));S.invalidate(parts);assert(S.build(o,parts,'target',30)~=restored)
local moved=assert(S.build({x=1,y=0},parts,'target',30));assert(moved~=restored)
local ranged=assert(S.build({x=1,y=0},parts,'target',20));assert(ranged~=moved);assert(not ranged({x=100,y=0}))
parts[2]=rect(15,-3,.2,6,'wall');assert(S.build(o,parts,'target',30)==nil)
print('PASS shared shadow cache reuse, enabled/order/bounds/replacement/origin/range invalidation and explicit callback invalidation')
