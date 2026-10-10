-- Story-only portrait adapter. Yu uses Yu Buxiu's original illustration;
-- characters with authored Spine portraits keep their existing native animation.
local D=require('Dora');local Portrait={}
function Portrait.asset(id)
 if not id or id==''then return nil end
 if id=='yu'then return 'Image/Story/yu-portrait.png'end
 if id=='char'then id=require('Data.Config').char end
 if id=='vivi'then id='vika'end
 return 'spine:'..id..'Figure'
end
function Portrait.create(args)
 local id=args.char
 if id~='yu'then local node=require('UI.StoryFigure')(args);node.tag='story-portrait:spine:'..id;return node end
 local node=D.Node();node.tag='story-portrait:illustration:'..id
 local sprite=assert(D.Sprite(Portrait.asset(id)));sprite.anchor=D.Vec2(.5,0);sprite.y=70
 sprite.scaleX=1450/sprite.height;sprite.scaleY=sprite.scaleX;sprite:addTo(node)
 node.sourceArt='LSD-doc/docs/source/img/figure/yu.png';node.illustration=sprite
 node:perform(D.Opacity(.2,0,1));return node
end
return setmetatable(Portrait,{__call=function(_,args)return Portrait.create(args)end})
