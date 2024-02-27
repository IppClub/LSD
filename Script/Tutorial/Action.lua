-- [tsx]: Action.tsx
local ____exports = {} -- 1
local ____dora = require("dora") -- 1
local cycle = ____dora.cycle -- 1
local Ease = ____dora.Ease -- 1
local Node = ____dora.Node -- 1
local once = ____dora.once -- 1
local Opacity = ____dora.Opacity -- 1
local sleep = ____dora.sleep -- 1
local Spine = ____dora.Spine -- 1
local tolua = ____dora.tolua -- 1
local Vec2 = ____dora.Vec2 -- 1
local ____Platformer = require("Platformer") -- 2
local Unit = ____Platformer.Unit -- 2
local UnitAction = ____Platformer.UnitAction -- 2
local Data = ____Platformer.Data -- 2
local BulletDef = ____Platformer.BulletDef -- 2
local Face = ____Platformer.Face -- 2
local Bullet = ____Platformer.Bullet -- 2
local TargetAllow = ____Platformer.TargetAllow -- 2
local ____dora_2Dx = require("dora-x") -- 3
local React = ____dora_2Dx.React -- 3
local toNode = ____dora_2Dx.toNode -- 3
local Rectangle = require("UI.View.Shape.Rectangle") -- 4
function ____exports.default() -- 6
    UnitAction:add( -- 7
        "bmove", -- 7
        { -- 7
            priority = 1, -- 8
            reaction = 2, -- 9
            recovery = 0.2, -- 10
            available = function(owner) return owner.onSurface end, -- 11
            create = function(owner) -- 12
                local playable = owner.playable -- 13
                playable:play("bmove", true) -- 14
                return function(owner, action) -- 15
                    local ____action_0 = action -- 16
                    local elapsedTime = ____action_0.elapsedTime -- 16
                    local recovery = ____action_0.recovery -- 16
                    local move = owner.unitDef.move -- 17
                    local moveSpeed = 1 -- 18
                    if elapsedTime < recovery then -- 18
                        moveSpeed = math.min(elapsedTime / recovery, 1) -- 20
                    end -- 20
                    owner.velocityX = moveSpeed * (owner.faceRight and -move or move) * 0.5 -- 22
                    return not owner.onSurface -- 23
                end -- 15
            end -- 12
        } -- 12
    ) -- 12
    UnitAction:add( -- 28
        "fmove", -- 28
        { -- 28
            priority = 1, -- 29
            reaction = 2, -- 30
            recovery = 0.2, -- 31
            available = function(owner) return owner.onSurface end, -- 32
            create = function(owner) -- 33
                local playable = owner.playable -- 34
                playable:play("fmove", true) -- 35
                return function(owner, action) -- 36
                    local ____action_1 = action -- 37
                    local elapsedTime = ____action_1.elapsedTime -- 37
                    local recovery = ____action_1.recovery -- 37
                    local move = owner.unitDef.move -- 38
                    local moveSpeed = 1 -- 39
                    if elapsedTime < recovery then -- 39
                        moveSpeed = math.min(elapsedTime / recovery, 1) -- 41
                    end -- 41
                    owner.velocityX = moveSpeed * (owner.faceRight and move or -move) -- 43
                    return not owner.onSurface -- 44
                end -- 36
            end -- 33
        } -- 33
    ) -- 33
    UnitAction:add( -- 49
        "prepare", -- 49
        { -- 49
            priority = 1, -- 50
            reaction = 2, -- 51
            recovery = 0.2, -- 52
            available = function(owner) return owner.onSurface end, -- 53
            create = function(owner) -- 54
                local playable = owner.playable -- 55
                repeat -- 55
                    local ____switch13 = playable.lastCompleted -- 55
                    local ____cond13 = ____switch13 == "pistol" or ____switch13 == "hit" -- 55
                    if ____cond13 then -- 55
                        playable.recovery = 0 -- 59
                        break -- 60
                    end -- 60
                until true -- 60
                playable:play("prepare", true) -- 62
                return function() return not owner.onSurface end -- 63
            end -- 54
        } -- 54
    ) -- 54
    UnitAction:add( -- 67
        "idle", -- 67
        { -- 67
            priority = 1, -- 68
            reaction = 2, -- 69
            recovery = 0.2, -- 70
            create = function(owner) -- 71
                local playable = owner.playable -- 72
                playable:play("idle", true) -- 73
                local playIdleSpecial = coroutine.create(function() -- 74
                    while true do -- 74
                        sleep(3) -- 76
                        sleep(playable:play("idle1")) -- 77
                        playable:play("idle", true) -- 78
                    end -- 78
                end) -- 74
                owner.data.playIdleSpecial = playIdleSpecial -- 81
                return function() -- 82
                    coroutine.resume(playIdleSpecial) -- 83
                    return not owner.onSurface -- 84
                end -- 82
            end -- 71
        } -- 71
    ) -- 71
    UnitAction:add( -- 89
        "laser", -- 89
        { -- 89
            priority = 3, -- 90
            reaction = 3, -- 91
            recovery = 0.2, -- 92
            queued = true, -- 93
            create = function(owner) return once(function() -- 94
                owner.playable:slot("attack"):set(function() -- 95
                    local bulletDef = BulletDef() -- 96
                    bulletDef.lifeTime = 10 -- 97
                    bulletDef.damageRadius = 0 -- 98
                    bulletDef.highSpeedFix = true -- 99
                    bulletDef.gravity = Vec2.zero -- 100
                    bulletDef.face = Face(function() -- 101
                        return Rectangle({width = 10, height = 10, borderColor = 4294901896, fillColor = 1727987848}) -- 102
                    end) -- 101
                    bulletDef:setAsCircle(10) -- 109
                    bulletDef:setVelocity(0, 5000) -- 110
                    local bullet = Bullet(bulletDef, owner) -- 111
                    local targetAllow = TargetAllow() -- 112
                    targetAllow:allow("Enemy", true) -- 113
                    targetAllow.terrainAllowed = true -- 114
                    bullet.angle = 0 -- 115
                    bullet.targetAllow = targetAllow:toValue() -- 116
                    bullet:slot( -- 117
                        "HitTarget", -- 117
                        function(bullet, target, pos) -- 117
                            local entity = target.entity -- 118
                            target.data.hitFromRight = bullet.velocityX < 0 -- 119
                            entity.ap = entity.ap - 100 -- 120
                            bullet.hitStop = true -- 121
                        end -- 117
                    ) -- 117
                    bullet:addTo(owner.world, owner.order) -- 123
                    local pistol = owner.playable:getSlot("pistol") -- 124
                    if pistol then -- 124
                        local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 126
                        local pos = owner.parent:convertToNodeSpace(worldPos) -- 127
                        bullet.position = pos -- 128
                    end -- 128
                end) -- 95
                sleep(owner.playable:play("pistol")) -- 131
                return true -- 132
            end) end -- 94
        } -- 94
    ) -- 94
    UnitAction:add( -- 136
        "kinetic", -- 136
        { -- 136
            priority = 3, -- 137
            reaction = 3, -- 138
            recovery = 0.2, -- 139
            queued = true, -- 140
            create = function(owner) return once(function() -- 141
                owner.playable:slot("attack"):set(function() -- 142
                    local ____owner_data_aimAngle_2 = owner.data.aimAngle -- 143
                    if ____owner_data_aimAngle_2 == nil then -- 143
                        ____owner_data_aimAngle_2 = 0 -- 143
                    end -- 143
                    local aimAngle = ____owner_data_aimAngle_2 -- 143
                    local bulletDef = BulletDef() -- 144
                    bulletDef.lifeTime = 10 -- 145
                    bulletDef.damageRadius = 0 -- 146
                    bulletDef.highSpeedFix = true -- 147
                    bulletDef.gravity = Vec2.zero -- 148
                    bulletDef.face = Face(function() -- 149
                        local spine = Spine("Spine/kineticgun") -- 150
                        if spine then -- 150
                            local node = Node() -- 152
                            node:addChild(spine) -- 153
                            spine.angle = owner.faceRight and aimAngle or 180 - aimAngle -- 154
                            spine.scaleX = 0.5 -- 155
                            spine.scaleY = 0.5 -- 156
                            spine.look = "PTbullet" -- 157
                            return node -- 158
                        end -- 158
                        return Node() -- 160
                    end) -- 149
                    bulletDef:setAsCircle(10) -- 162
                    bulletDef:setVelocity(-aimAngle, 5000) -- 163
                    local bullet = Bullet(bulletDef, owner) -- 164
                    local targetAllow = TargetAllow() -- 165
                    targetAllow:allow("Enemy", true) -- 166
                    targetAllow.terrainAllowed = true -- 167
                    bullet.targetAllow = targetAllow:toValue() -- 168
                    bullet:slot( -- 169
                        "HitTarget", -- 169
                        function(bullet, target, pos) -- 169
                            local entity = target.entity -- 170
                            target.data.hitFromRight = bullet.velocityX < 0 -- 171
                            entity.hp = entity.hp - 1 -- 172
                            bullet.hitStop = true -- 173
                        end -- 169
                    ) -- 169
                    bullet:addTo(owner.world, owner.order) -- 175
                    local pistol = owner.playable:getSlot("pistol") -- 176
                    if pistol then -- 176
                        local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 178
                        local pos = owner.parent:convertToNodeSpace(worldPos) -- 179
                        bullet.position = pos -- 180
                        worldPos = pistol:convertToWorldSpace(Vec2.zero) -- 181
                        pos = owner.parent:convertToNodeSpace(worldPos) -- 182
                        local casing = toNode(React:createElement( -- 183
                            "body", -- 183
                            { -- 183
                                type = "Dynamic", -- 183
                                x = pos.x, -- 183
                                y = pos.y, -- 183
                                world = owner.world, -- 183
                                group = Data.groupHide, -- 183
                                linearAcceleration = Vec2(0, -9.8), -- 183
                                velocityX = math.random() * (owner.faceRight and -100 or 100), -- 183
                                velocityY = math.random() * 300, -- 183
                                angle = math.random() * aimAngle -- 183
                            }, -- 183
                            React:createElement("rect-fixture", { -- 183
                                width = 20, -- 183
                                height = 10, -- 183
                                density = 26, -- 183
                                friction = 0.4, -- 183
                                restitution = 0.4 -- 183
                            }), -- 183
                            React:createElement("spine", {file = "Spine/kineticgun", look = "PTcasing", scaleX = 0.5, scaleY = 0.5}) -- 183
                        )) -- 183
                        if casing then -- 183
                            casing:schedule(once(function() -- 197
                                sleep(10) -- 198
                                sleep(casing:perform(Opacity(0.5, 1, 0))) -- 199
                                casing:removeFromParent() -- 200
                            end)) -- 197
                            casing:addTo(owner.world, owner.order) -- 202
                        end -- 202
                    end -- 202
                    local playable = tolua.cast(owner.playable, "Spine") -- 205
                    if playable then -- 205
                        playable:schedule(once(function() -- 207
                            sleep(0.2) -- 208
                            cycle( -- 209
                                0.2, -- 209
                                function(time) -- 209
                                    local angle = -(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 210
                                    owner.data.aimAngle = angle -- 211
                                    playable:setBoneRotation("aim", angle) -- 212
                                end -- 209
                            ) -- 209
                        end)) -- 207
                    end -- 207
                end) -- 142
                local aim = owner:getChildByTag("aim") -- 217
                local playable = tolua.cast(owner.playable, "Spine") -- 218
                if aim and playable then -- 218
                    local angle = aim.angle -- 220
                    playable:schedule(once(function() -- 221
                        local fix = owner.faceRight and 1 or -1 -- 222
                        cycle( -- 223
                            0.2, -- 223
                            function(time) -- 223
                                local aimAngle = -Ease:func(Ease.OutSine, time) * fix * angle -- 224
                                owner.data.aimAngle = -aimAngle -- 225
                                playable:setBoneRotation("aim", aimAngle) -- 226
                            end -- 223
                        ) -- 223
                    end)) -- 221
                end -- 221
                sleep(owner.playable:play("pistol")) -- 230
                return true -- 231
            end) end, -- 141
            stop = function(owner) -- 233
                local aimAngle = owner.data.aimAngle -- 234
                if aimAngle then -- 234
                    local playable = tolua.cast(owner.playable, "Spine") -- 236
                    if playable then -- 236
                        playable:schedule(once(function() -- 238
                            cycle( -- 239
                                0.2, -- 239
                                function(time) -- 239
                                    playable:setBoneRotation( -- 240
                                        "aim", -- 240
                                        -(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 240
                                    ) -- 240
                                end -- 239
                            ) -- 239
                        end)) -- 238
                    end -- 238
                end -- 238
            end -- 233
        } -- 233
    ) -- 233
    UnitAction:add( -- 248
        "hit", -- 248
        { -- 248
            priority = 99, -- 249
            reaction = 3, -- 250
            recovery = 0.2, -- 251
            create = function(owner) return once(function() -- 252
                sleep(owner.playable:play("hit")) -- 253
                return true -- 254
            end) end -- 252
        } -- 252
    ) -- 252
    UnitAction:add( -- 258
        "dizzy", -- 258
        { -- 258
            priority = 99, -- 259
            reaction = 3, -- 260
            recovery = 0.2, -- 261
            create = function(owner) -- 262
                owner.playable:play("dizzy", true) -- 263
                return function() return false end -- 264
            end -- 262
        } -- 262
    ) -- 262
    UnitAction:add( -- 268
        "lose", -- 268
        { -- 268
            priority = 99, -- 269
            reaction = 3, -- 270
            recovery = 0.2, -- 271
            create = function(owner) return once(function() -- 272
                local time = owner.playable:play("lose") -- 273
                sleep(time - 0.05) -- 274
                owner.playable.speed = 0 -- 275
                return true -- 276
            end) end -- 272
        } -- 272
    ) -- 272
    UnitAction:add( -- 280
        "blow", -- 280
        { -- 280
            reaction = 3, -- 281
            recovery = 0.2, -- 282
            priority = 3, -- 283
            queued = true, -- 284
            create = function(owner) -- 285
                owner.playable:slot("attack"):set(function() -- 286
                    local senser = owner:getSensorByTag(Unit.AttackSensorTag) -- 287
                    senser.sensedBodies:each(function(item) -- 288
                        local unit = tolua.cast(item, "Platformer::Unit") -- 289
                        if unit and Data:isEnemy(unit.group, owner.group) and unit.x >= owner.x == owner.faceRight then -- 289
                            unit:applyLinearImpulse( -- 291
                                Vec2(unit.x < owner.x and -500 or 500, 0), -- 291
                                Vec2.zero -- 291
                            ) -- 291
                            unit:start("cancal") -- 292
                            if unit.x < owner.x and not unit.faceRight then -- 292
                                unit:start("turn") -- 294
                            end -- 294
                            unit:start("hit") -- 296
                        end -- 296
                        return false -- 298
                    end) -- 288
                end) -- 286
                return once(function() -- 301
                    sleep(owner.playable:play("blow")) -- 302
                    return true -- 303
                end) -- 301
            end -- 285
        } -- 285
    ) -- 285
    UnitAction:add( -- 308
        "fallOff", -- 308
        { -- 308
            priority = 2, -- 309
            reaction = -1, -- 310
            recovery = 0.3, -- 311
            queued = true, -- 312
            available = function(owner) return not owner.onSurface end, -- 313
            create = function(owner) -- 314
                local playable = owner.playable -- 315
                if playable.current ~= "jumping" then -- 315
                    playable:play("jumping", true) -- 317
                end -- 317
                return once(function() -- 319
                    while true do -- 319
                        if owner.onSurface then -- 319
                            sleep(playable:play("landing", false)) -- 322
                            coroutine.yield(true) -- 323
                        else -- 323
                            coroutine.yield(false) -- 325
                        end -- 325
                    end -- 325
                end) -- 319
            end -- 314
        } -- 314
    ) -- 314
end -- 314
return ____exports -- 314