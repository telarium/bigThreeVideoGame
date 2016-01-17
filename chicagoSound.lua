local soundTime = nil
local kEnemyImpactChannel = 1
local kWeaponChannel = 2
local kVoiceChannel = 3
local kBonusSound = 4
local kDamageSound = 5
local bVoicePlaying = false

local mainScene = nil

local sound = {
	--
}

function sound:load(sound, bForceLoadSound )
	if ( system.getInfo("platformName") == "Android" and not bForceLoadSound ) then
		return media.newEventSound( "sounds/" .. sound )
	else
		return audio.loadSound( "sounds/" .. sound )
	end
end

function sound:killSounds()
	if ( system.getInfo("platformName") == "Android" ) then
		media.stopSound()
	else
		audio.stop()
	end
end

function sound:play(sound, bAllowOverlap, bForceLoadSound, delay )
	if( not bAllowOverlap ) then
		if( system.getTimer() - soundTime < 100 ) then
			return
		else
			soundTime = system.getTimer()
		end
	end
	local delayFunction = nil
	if( delay ) then
	   delayFunction = function()  
            local channel = audio.play( sound )
       end
       
       timer.performWithDelay( delay*1000, delayFunction, 1 )
    else
        if ( system.getInfo("platformName") == "Android" and not bForceLoadSound ) then
           local channel = media.playEventSound( sound )
         else
             local channel = audio.play( sound )
         end
    end
end

function sound:loadEnemyImpactSound( sound )
    if ( system.getInfo("platformName") == "Android" ) then
		return media.newEventSound( "sounds/" .. sound )
	else
		return audio.loadSound( "sounds/" .. sound )
	end
end

function sound:playEnemyImpactSound( sound )
    if ( system.getInfo("platformName") == "Android" ) then
        media.playEventSound( sound )
	else
	   audio.play( sound, kEnemyImpactChannel )
	end
end

function sound:loadWeaponSound( sound )
    
    if ( system.getInfo("platformName") == "Android" ) then
		return media.newEventSound( "sounds/" .. sound )
	else
		return audio.loadSound( "sounds/" .. sound )
	end
end

function sound:playWeaponSound( sound )
    if ( system.getInfo("platformName") == "Android" ) then
        media.playEventSound( sound )
	else
	   audio.play( sound, kWeaponChannel)
	end
end

function sound:playEnemyImpactSound( sound )
    if ( system.getInfo("platformName") == "Android" ) then
        media.playEventSound( sound )
	else
	   audio.play( sound, kEnemyImpactChannel )
	end
end

function sound:loadBonusSound( sound )
    
    if ( system.getInfo("platformName") == "Android" ) then
		return media.newEventSound( "sounds/" .. sound )
	else
		return audio.loadSound( "sounds/" .. sound )
	end
end

function sound:playBonusSound( sound, bKillVoice )
    if ( system.getInfo("platformName") == "Android" ) then
        media.playEventSound( sound )
	else
	   audio.play( sound, kBonusSound )
	end
end

function sound:loadDamageSound( sound )
    return audio.loadSound( "sounds/" .. sound )
end

function sound:playDamageSound( sound )
    audio.play( sound, kDamageSound )
end

function sound:loadVoice( voiceFile )
    return audio.loadSound( "sounds/" .. voiceFile )
end

function sound:playVoice( voice, delay, bForce, bDisableGameOver )
    if( audio.isChannelPlaying( kVoiceChannel ) ) then
        return false
    end
    if( mainScene.bSmoggy and not bForce ) then
        return
    end
    if( not delay ) then
        delay = 0
    end
	local finished = function( event )
		if event.completed then
			bVoicePlaying = false
		end
	end
    local goVoice = function()
		if( bVoicePlaying and not bForce ) then
			return false
		end
		bVoicePlaying = true
        if( not audio.isChannelPlaying( kVoiceChannel ) and ( not mainScene.bGameOver or bDisableGameOver ) ) then
            audio.play( voice, { kVoiceChannel, onComplete=finished } )
        end
    end
    timer.performWithDelay( delay*1000, goVoice, 1 )
	return true
end



function sound:init(scene)
	mainScene = scene
	bVoicePlaying = false
	soundTime = system.getTimer()
	audio.reserveChannels(kWeaponChannel)
	audio.reserveChannels(kEnemyImpactChannel)
	audio.reserveChannels(kVoiceChannel)
	audio.reserveChannels(kBonusSound)
	audio.reserveChannels(kDamageSound)
end

function sound:destroy()
	mainScene = nil
	soundTime = nil
end

return sound
