-- [tsx]: Action.tsx
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 1
local cycle = ____Dora.cycle -- 1
local Ease = ____Dora.Ease -- 1
local Node = ____Dora.Node -- 1
local once = ____Dora.once -- 1
local Opacity = ____Dora.Opacity -- 1
local sleep = ____Dora.sleep -- 1
local Spine = ____Dora.Spine -- 1
local tolua = ____Dora.tolua -- 1
local Vec2 = ____Dora.Vec2 -- 1
local ____Platformer = require("Platformer") -- 2
local Unit = ____Platformer.Unit -- 2
local UnitAction = ____Platformer.UnitAction -- 2
local Data = ____Platformer.Data -- 2
local BulletDef = ____Platformer.BulletDef -- 2
local Face = ____Platformer.Face -- 2
local Bullet = ____Platformer.Bullet -- 2
local TargetAllow = ____Platformer.TargetAllow -- 2
local ____DoraX = require("DoraX") -- 3
local React = ____DoraX.React -- 3
local toNode = ____DoraX.toNode -- 3
local Rectangle = require("UI.View.Shape.Rectangle") -- 4
local ____LightStrip = require("Tutorial.LightStrip") -- 5
local LightStrip = ____LightStrip.LightStrip -- 5
function ____exports.default() -- 7
    UnitAction:add( -- 8
        "bmove", -- 8
        { -- 8
            priority = 1, -- 9
            reaction = 2, -- 10
            recovery = 0.2, -- 11
            available = function(owner) return owner.onSurface end, -- 12
            create = function(owner) -- 13
                local playable = owner.playable -- 14
                playable:play("bmove", true) -- 15
                return function(owner, action) -- 16
                    local ____action_0 = action -- 17
                    local elapsedTime = ____action_0.elapsedTime -- 17
                    local recovery = ____action_0.recovery -- 17
                    local move = owner.unitDef.move -- 18
                    local moveSpeed = 1 -- 19
                    if elapsedTime < recovery then -- 19
                        moveSpeed = math.min(elapsedTime / recovery, 1) -- 21
                    end -- 21
                    owner.velocityX = moveSpeed * (owner.faceRight and -move or move) * 0.5 -- 23
                    return not owner.onSurface -- 24
                end -- 16
            end -- 13
        } -- 13
    ) -- 13
    UnitAction:add( -- 29
        "fmove", -- 29
        { -- 29
            priority = 1, -- 30
            reaction = 2, -- 31
            recovery = 0.2, -- 32
            available = function(owner) return owner.onSurface end, -- 33
            create = function(owner) -- 34
                local playable = owner.playable -- 35
                playable:play("fmove", true) -- 36
                return function(owner, action) -- 37
                    local ____action_1 = action -- 38
                    local elapsedTime = ____action_1.elapsedTime -- 38
                    local recovery = ____action_1.recovery -- 38
                    local move = owner.unitDef.move -- 39
                    local moveSpeed = 1 -- 40
                    if elapsedTime < recovery then -- 40
                        moveSpeed = math.min(elapsedTime / recovery, 1) -- 42
                    end -- 42
                    owner.velocityX = moveSpeed * (owner.faceRight and move or -move) -- 44
                    return not owner.onSurface -- 45
                end -- 37
            end -- 34
        } -- 34
    ) -- 34
    UnitAction:add( -- 50
        "prepare", -- 50
        { -- 50
            priority = 1, -- 51
            reaction = 2, -- 52
            recovery = 0.2, -- 53
            available = function(owner) return owner.onSurface end, -- 54
            create = function(owner) -- 55
                local playable = owner.playable -- 56
                repeat -- 56
                    local ____switch13 = playable.lastCompleted -- 56
                    local ____cond13 = ____switch13 == "pistol" or ____switch13 == "hit" -- 56
                    if ____cond13 then -- 56
                        playable.recovery = 0 -- 60
                        break -- 61
                    end -- 61
                until true -- 61
                playable:play("prepare", true) -- 63
                return function() return not owner.onSurface end -- 64
            end -- 55
        } -- 55
    ) -- 55
    UnitAction:add( -- 68
        "idle", -- 68
        { -- 68
            priority = 1, -- 69
            reaction = 2, -- 70
            recovery = 0.2, -- 71
            create = function(owner) -- 72
                local playable = owner.playable -- 73
                playable:play("idle", true) -- 74
                local playIdleSpecial = coroutine.create(function() -- 75
                    while true do -- 75
                        sleep(3) -- 77
                        sleep(playable:play("idle1")) -- 78
                        playable:play("idle", true) -- 79
                    end -- 79
                end) -- 75
                owner.data.playIdleSpecial = playIdleSpecial -- 82
                return function() -- 83
                    coroutine.resume(playIdleSpecial) -- 84
                    return not owner.onSurface -- 85
                end -- 83
            end -- 72
        } -- 72
    ) -- 72
    UnitAction:add( -- 90
        "laser", -- 90
        { -- 90
            priority = 3, -- 91
            reaction = 3, -- 92
            recovery = 0.2, -- 93
            queued = true, -- 94
            create = function(owner) return once(function() -- 95
                owner.playable:slot("attack"):set(function() -- 96
                    local bulletDef = BulletDef() -- 97
                    bulletDef.lifeTime = 10 -- 98
                    bulletDef.damageRadius = 0 -- 99
                    bulletDef.highSpeedFix = true -- 100
                    bulletDef.gravity = Vec2.zero -- 101
                    bulletDef.face = Face(function() -- 102
                        return Rectangle({width = 10, height = 10, borderColor = 4294901896, fillColor = 1727987848}) -- 103
                    end) -- 102
                    bulletDef:setAsCircle(10) -- 110
                    bulletDef:setVelocity(0, 5000) -- 111
                    local bullet = Bullet(bulletDef, owner) -- 112
                    local targetAllow = TargetAllow() -- 113
                    targetAllow:allow("Enemy", true) -- 114
                    targetAllow.terrainAllowed = true -- 115
                    bullet.angle = 0 -- 116
                    bullet.targetAllow = targetAllow:toValue() -- 117
                    bullet:slot( -- 118
                        "HitTarget", -- 118
                        function(bullet, target, pos) -- 118
                            local entity = target.entity -- 119
                            target.data.hitFromRight = bullet.velocityX < 0 -- 120
                            entity.ap = entity.ap - 100 -- 121
                            bullet.hitStop = true -- 122
                        end -- 118
                    ) -- 118
                    bullet:addTo(owner.world, owner.order) -- 124
                    local pistol = owner.playable:getSlot("pistol") -- 125
                    if pistol then -- 125
                        local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 127
                        local ____opt_2 = owner.parent -- 127
                        local pos = ____opt_2 and ____opt_2:convertToNodeSpace(worldPos) -- 128
                        if pos then -- 128
                            bullet.position = pos -- 129
                        end -- 129
                    end -- 129
                    LightStrip(bullet.position, bullet, 4287479539) -- 131
                end) -- 96
                sleep(owner.playable:play("pistol")) -- 133
                return true -- 134
            end) end -- 95
        } -- 95
    ) -- 95
    UnitAction:add( -- 138
        "kinetic", -- 138
        { -- 138
            priority = 3, -- 139
            reaction = 3, -- 140
            recovery = 0.2, -- 141
            queued = true, -- 142
            create = function(owner) return once(function() -- 143
                owner.playable:slot("attack"):set(function() -- 144
                    local ____owner_data_aimAngle_4 = owner.data.aimAngle -- 145
                    if ____owner_data_aimAngle_4 == nil then -- 145
                        ____owner_data_aimAngle_4 = 0 -- 145
                    end -- 145
                    local aimAngle = ____owner_data_aimAngle_4 -- 145
                    local bulletDef = BulletDef() -- 146
                    bulletDef.lifeTime = 10 -- 147
                    bulletDef.damageRadius = 0 -- 148
                    bulletDef.highSpeedFix = true -- 149
                    bulletDef.gravity = Vec2.zero -- 150
                    bulletDef.face = Face(function() -- 151
                        local spine = Spine("Spine/kineticgun") -- 152
                        if spine then -- 152
                            local node = Node() -- 154
                            node:addChild(spine) -- 155
                            spine.angle = owner.faceRight and aimAngle or 180 - aimAngle -- 156
                            spine.scaleX = 0.5 -- 157
                            spine.scaleY = 0.5 -- 158
                            spine.look = "PTbullet" -- 159
                            return node -- 160
                        end -- 160
                        return Node() -- 162
                    end) -- 151
                    bulletDef:setAsCircle(10) -- 164
                    bulletDef:setVelocity(-aimAngle, 5000) -- 165
                    local bullet = Bullet(bulletDef, owner) -- 166
                    local targetAllow = TargetAllow() -- 167
                    targetAllow:allow("Enemy", true) -- 168
                    targetAllow.terrainAllowed = true -- 169
                    bullet.targetAllow = targetAllow:toValue() -- 170
                    bullet:slot( -- 171
                        "HitTarget", -- 171
                        function(bullet, target, pos) -- 171
                            local entity = target.entity -- 172
                            target.data.hitFromRight = bullet.velocityX < 0 -- 173
                            entity.hp = entity.hp - 1 -- 174
                            bullet.hitStop = true -- 175
                        end -- 171
                    ) -- 171
                    bullet:addTo(owner.world, owner.order) -- 177
                    local pistol = owner.playable:getSlot("pistol") -- 178
                    if pistol then -- 178
                        local worldPos = pistol:convertToWorldSpace(Vec2(300, 0)) -- 180
                        local ____opt_5 = owner.parent -- 180
                        local pos = ____opt_5 and ____opt_5:convertToNodeSpace(worldPos) -- 181
                        if pos then -- 181
                            bullet.position = pos -- 182
                        end -- 182
                        worldPos = pistol:convertToWorldSpace(Vec2.zero) -- 183
                        local ____opt_7 = owner.parent -- 183
                        pos = ____opt_7 and ____opt_7:convertToNodeSpace(worldPos) or Vec2.zero -- 184
                        local casing = toNode(React:createElement( -- 185
                            "body", -- 185
                            { -- 185
                                type = "Dynamic", -- 185
                                x = pos.x, -- 185
                                y = pos.y, -- 185
                                world = owner.world, -- 185
                                group = Data.groupHide, -- 185
                                linearAcceleration = Vec2(0, -9.8), -- 185
                                velocityX = math.random() * (owner.faceRight and -200 or 200), -- 185
                                velocityY = math.random() * 300, -- 185
                                angle = math.random() * aimAngle -- 185
                            }, -- 185
                            React:createElement("rect-fixture", { -- 185
                                width = 20, -- 185
                                height = 10, -- 185
                                density = 26, -- 185
                                friction = 0.4, -- 185
                                restitution = 0.4 -- 185
                            }), -- 185
                            React:createElement("spine", {file = "Spine/kineticgun", look = "PTcasing", scaleX = 0.5, scaleY = 0.5}) -- 185
                        )) -- 185
                        if casing then -- 185
                            casing:schedule(once(function() -- 199
                                sleep(10) -- 200
                                sleep(casing:perform(Opacity(0.5, 1, 0))) -- 201
                                casing:removeFromParent() -- 202
                            end)) -- 199
                            casing:addTo(owner.world, owner.order) -- 204
                        end -- 204
                    end -- 204
                    LightStrip(bullet.position, bullet, 4294967295) -- 207
                    local playable = tolua.cast(owner.playable, "Spine") -- 208
                    if playable then -- 208
                        playable:schedule(once(function() -- 210
                            sleep(0.2) -- 211
                            cycle( -- 212
                                0.2, -- 212
                                function(time) -- 212
                                    local angle = -(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 213
                                    owner.data.aimAngle = angle -- 214
                                    playable:setBoneRotation("aim", angle) -- 215
                                end -- 212
                            ) -- 212
                        end)) -- 210
                    end -- 210
                end) -- 144
                local aim = owner:getChildByTag("aim") -- 220
                local playable = tolua.cast(owner.playable, "Spine") -- 221
                if aim and playable then -- 221
                    local angle = aim.angle -- 223
                    playable:schedule(once(function() -- 224
                        local fix = owner.faceRight and 1 or -1 -- 225
                        cycle( -- 226
                            0.2, -- 226
                            function(time) -- 226
                                local aimAngle = -Ease:func(Ease.OutSine, time) * fix * angle -- 227
                                owner.data.aimAngle = -aimAngle -- 228
                                playable:setBoneRotation("aim", aimAngle) -- 229
                            end -- 226
                        ) -- 226
                    end)) -- 224
                end -- 224
                sleep(owner.playable:play("pistol")) -- 233
                return true -- 234
            end) end, -- 143
            stop = function(owner) -- 236
                local aimAngle = owner.data.aimAngle -- 237
                if aimAngle then -- 237
                    local playable = tolua.cast(owner.playable, "Spine") -- 239
                    if playable then -- 239
                        playable:schedule(once(function() -- 241
                            cycle( -- 242
                                0.2, -- 242
                                function(time) -- 242
                                    playable:setBoneRotation( -- 243
                                        "aim", -- 243
                                        -(1 - Ease:func(Ease.OutSine, time)) * aimAngle -- 243
                                    ) -- 243
                                end -- 242
                            ) -- 242
                        end)) -- 241
                    end -- 241
                end -- 241
            end -- 236
        } -- 236
    ) -- 236
    UnitAction:add( -- 251
        "hit", -- 251
        { -- 251
            priority = 99, -- 252
            reaction = 3, -- 253
            recovery = 0.2, -- 254
            create = function(owner) return once(function() -- 255
                sleep(owner.playable:play("hit")) -- 256
                return true -- 257
            end) end -- 255
        } -- 255
    ) -- 255
    UnitAction:add( -- 261
        "dizzy", -- 261
        { -- 261
            priority = 99, -- 262
            reaction = 3, -- 263
            recovery = 0.2, -- 264
            create = function(owner) -- 265
                owner.playable:play("dizzy", true) -- 266
                return function() return false end -- 267
            end -- 265
        } -- 265
    ) -- 265
    UnitAction:add( -- 271
        "lose", -- 271
        { -- 271
            priority = 99, -- 272
            reaction = 3, -- 273
            recovery = 0.2, -- 274
            create = function(owner) return once(function() -- 275
                local time = owner.playable:play("lose") -- 276
                sleep(time - 0.05) -- 277
                owner.playable.speed = 0 -- 278
                return true -- 279
            end) end -- 275
        } -- 275
    ) -- 275
    UnitAction:add( -- 283
        "blow", -- 283
        { -- 283
            reaction = 3, -- 284
            recovery = 0.2, -- 285
            priority = 3, -- 286
            queued = true, -- 287
            create = function(owner) -- 288
                owner.playable:slot("attack"):set(function() -- 289
                    local senser = owner:getSensorByTag(Unit.AttackSensorTag) -- 290
                    senser.sensedBodies:each(function(item) -- 291
                        local unit = tolua.cast(item, "Platformer::Unit") -- 292
                        if unit and Data:isEnemy(unit.group, owner.group) and unit.x >= owner.x == owner.faceRight then -- 292
                            unit:applyLinearImpulse( -- 294
                                Vec2(unit.x < owner.x and -500 or 500, 0), -- 294
                                Vec2.zero -- 294
                            ) -- 294
                            unit:start("cancal") -- 295
                            if unit.x < owner.x and not unit.faceRight then -- 295
                                unit:start("turn") -- 297
                            end -- 297
                            unit:start("hit") -- 299
                        end -- 299
                        return false -- 301
                    end) -- 291
                end) -- 289
                return once(function() -- 304
                    sleep(owner.playable:play("blow")) -- 305
                    return true -- 306
                end) -- 304
            end -- 288
        } -- 288
    ) -- 288
    UnitAction:add( -- 311
        "fallOff", -- 311
        { -- 311
            priority = 2, -- 312
            reaction = -1, -- 313
            recovery = 0.3, -- 314
            queued = true, -- 315
            available = function(owner) return not owner.onSurface end, -- 316
            create = function(owner) -- 317
                local playable = owner.playable -- 318
                if playable.current ~= "jumping" then -- 318
                    playable:play("jumping", true) -- 320
                end -- 320
                return once(function() -- 322
                    while true do -- 322
                        if owner.onSurface then -- 322
                            sleep(playable:play("landing", false)) -- 325
                            coroutine.yield(true) -- 326
                        else -- 326
                            coroutine.yield(false) -- 328
                        end -- 328
                    end -- 328
                end) -- 322
            end -- 317
        } -- 317
    ) -- 317
end -- 317
return ____exports -- 317