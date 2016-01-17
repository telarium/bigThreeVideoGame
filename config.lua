application = {
	content = {
        --graphicsCompatibility = 1,  -- Turn on V1 Compatibility Mode
		width = 320,
		height = 480, 
		scale = "letterbox",
		antialias = false,
		xAlign = "center",
		yAlign = "center",
		fps = 60,
		
		--[[
        imageSuffix = {
		    ["@2x"] = 2,
		}
		--]]
	},

    --[[
    -- Push notifications

    notification =
    {
        iphone =
        {
            types =
            {
                "badge", "sound", "alert", "newsstand"
            }
        }
    }
    --]]    
}
