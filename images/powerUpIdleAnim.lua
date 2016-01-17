--
-- created with TexturePacker (http://www.codeandweb.com/texturepacker)
--
-- $TexturePacker:SmartUpdate:fbd6f527b00fd2e7e228625d4f7babc1:1/1$
--
-- local sheetInfo = require("mysheet")
-- local myImageSheet = graphics.newImageSheet( "mysheet.png", sheetInfo:getSheet() )
-- local sprite = display.newSprite( myImageSheet , {frames={sheetInfo:getFrameIndex("sprite")}} )
--

local SheetInfo = {}

SheetInfo.sheet =
{
    frames = {
    
        {
            -- Comp 3_00000
            x=330,
            y=248,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00001
            x=248,
            y=412,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00002
            x=248,
            y=330,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00003
            x=248,
            y=248,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00004
            x=412,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00005
            x=330,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00006
            x=248,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00007
            x=166,
            y=412,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00008
            x=166,
            y=330,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00009
            x=166,
            y=248,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00010
            x=166,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00011
            x=412,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00012
            x=330,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00013
            x=248,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00014
            x=166,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00015
            x=84,
            y=412,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00016
            x=84,
            y=330,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00017
            x=84,
            y=248,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00018
            x=84,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00019
            x=84,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00020
            x=412,
            y=2,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00021
            x=330,
            y=2,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00022
            x=248,
            y=2,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00023
            x=166,
            y=2,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00024
            x=84,
            y=2,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00025
            x=2,
            y=412,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00026
            x=2,
            y=330,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00027
            x=2,
            y=248,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00028
            x=2,
            y=166,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00029
            x=2,
            y=84,
            width=80,
            height=80,

        },
        {
            -- Comp 3_00030
            x=2,
            y=2,
            width=80,
            height=80,

        },
    },
    
    sheetContentWidth = 512,
    sheetContentHeight = 512
}

SheetInfo.frameIndex =
{

    ["Comp 3_00000"] = 1,
    ["Comp 3_00001"] = 2,
    ["Comp 3_00002"] = 3,
    ["Comp 3_00003"] = 4,
    ["Comp 3_00004"] = 5,
    ["Comp 3_00005"] = 6,
    ["Comp 3_00006"] = 7,
    ["Comp 3_00007"] = 8,
    ["Comp 3_00008"] = 9,
    ["Comp 3_00009"] = 10,
    ["Comp 3_00010"] = 11,
    ["Comp 3_00011"] = 12,
    ["Comp 3_00012"] = 13,
    ["Comp 3_00013"] = 14,
    ["Comp 3_00014"] = 15,
    ["Comp 3_00015"] = 16,
    ["Comp 3_00016"] = 17,
    ["Comp 3_00017"] = 18,
    ["Comp 3_00018"] = 19,
    ["Comp 3_00019"] = 20,
    ["Comp 3_00020"] = 21,
    ["Comp 3_00021"] = 22,
    ["Comp 3_00022"] = 23,
    ["Comp 3_00023"] = 24,
    ["Comp 3_00024"] = 25,
    ["Comp 3_00025"] = 26,
    ["Comp 3_00026"] = 27,
    ["Comp 3_00027"] = 28,
    ["Comp 3_00028"] = 29,
    ["Comp 3_00029"] = 30,
    ["Comp 3_00030"] = 31,
}

function SheetInfo:getSheet()
    return self.sheet;
end

function SheetInfo:getFrameIndex(name)
    return self.frameIndex[name];
end

return SheetInfo
