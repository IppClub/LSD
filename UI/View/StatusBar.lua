-- [tsx]: StatusBar.tsx
local ____lualib = require("lualib_bundle") -- 1
local __TS__ArrayMap = ____lualib.__TS__ArrayMap -- 1
local ____exports = {} -- 1
local ____dora_2Dx = require("dora-x") -- 2
local React = ____dora_2Dx.React -- 2
local toNode = ____dora_2Dx.toNode -- 2
local useRef = ____dora_2Dx.useRef -- 2
local ____dora = require("dora") -- 3
local Color = ____dora.Color -- 3
local Color3 = ____dora.Color3 -- 3
local Vec2 = ____dora.Vec2 -- 3
local function Bar(self, props) -- 14
    local ____props_0 = props -- 15
    local width = ____props_0.width -- 15
    local height = ____props_0.height -- 15
    local y = ____props_0.y -- 15
    local hw = width / 2 -- 16
    local percentage = props.percentage or 1 -- 17
    return React:createElement( -- 18
        React.Fragment, -- 18
        nil, -- 18
        React:createElement( -- 18
            "polygon-shape", -- 18
            { -- 18
                verts = { -- 18
                    Vec2(-hw, y), -- 21
                    Vec2(-hw, height + y), -- 22
                    Vec2(hw, height + y), -- 23
                    Vec2(hw, y) -- 24
                }, -- 24
                fillColor = Color( -- 24
                    Color3(props.color3), -- 25
                    127 -- 25
                ):toARGB() -- 25
            } -- 25
        ), -- 25
        React:createElement( -- 25
            "draw-node", -- 25
            {scaleX = percentage, x = -hw, ref = props.ref, color3 = props.color3}, -- 25
            React:createElement( -- 25
                "polygon-shape", -- 25
                { -- 25
                    verts = { -- 25
                        Vec2(0, y), -- 28
                        Vec2(0, height + y), -- 29
                        Vec2(width, height + y), -- 30
                        Vec2(width, y) -- 31
                    }, -- 31
                    fillColor = 4294967295 -- 31
                } -- 31
            ) -- 31
        ) -- 31
    ) -- 31
end -- 14
local function StatusBar(self, props) -- 48
    local ____props_1 = props -- 49
    local width = ____props_1.width -- 49
    local height = ____props_1.height -- 49
    return React:createElement( -- 50
        "draw-node", -- 50
        nil, -- 50
        __TS__ArrayMap( -- 53
            props.bars, -- 53
            function(____, bar, i) return React:createElement(Bar, { -- 53
                ref = bar.ref, -- 53
                y = i * height, -- 53
                width = width, -- 53
                height = height, -- 53
                color3 = bar.color3, -- 53
                percentage = bar.percentage -- 53
            }) end -- 53
        ) -- 53
    ) -- 53
end -- 48
function ____exports.default(hp, ap, hpColor3) -- 67
    local hpBar = useRef() -- 68
    local apBar = useRef() -- 69
    local node = toNode(React:createElement(StatusBar, {width = 100, height = 10, bars = {{color3 = 9289459, percentage = ap, ref = apBar}, {color3 = hpColor3, percentage = hp, ref = hpBar}}})) -- 70
    return node, hpBar.current, apBar.current -- 76
end -- 76
return ____exports -- 76