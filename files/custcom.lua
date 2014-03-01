--custom commands
--

dofile(path.."files/chatcore.lua")
dofile(path.."files/dependency/functions.lua" )
local tokenize=Explode

function chkpriv(user,n)
	local profile = Core.GetUserValue(user,15)
	if profile == -1 then return false end
	if profile > n  then return false end
	return true
end

function isHigherRanked(user,victim)
	local userprofile = Core.GetUserValue(user,15)
	local victimprofile = Core.GetUserValue(victim,15)
	if userprofile < victimprofile and userprofile ~= -1 then return true end
	return false
end
	
function isthere(user,tabl)
	return tabl[user]
end

function isthere_key(key,tabl)
	local q = string.lower(key)
	for k,v in ipairs(tabl) do
	w = string.lower(v)
		if w == q then
			return k
		end
	end
	return nil
end

function substring(tokens,index)	--return a string concatenated with all tokens after index
	local string=""
	for k,v in ipairs(tokens) do
		if k>index then
			string= string..v.." "
		end
	end
	return string
end

function check(user,regprofile,tokens,numofargs,victimid)
	if not chkpriv( user, regprofile) then
		notify(user,"You dont have access to this command")
		return false
	end
	if tokens and numofargs then
		if not tokens[numofargs] then
			notify(user,"Insufficient arguments")
			return false
		end
	end
	if victimid then
		local victim=Core.GetUser(tokens[victimid])
		if not victim then
			notify(user,victim.." not online")
			return false
		end
		if not isHigherRanked(user,victim) then
			notify(user,"You dont have the permission to use this command on "..victim.sNick)
			return false
		end

	end
	return true
end
function notify(user,msg)
	if inPM then
		Core.SendPmToUser(user,"PtokaX",msg)
	else
		Core.SendToUser(user,"<PtokaX> "..msg)
	end
end
CustomCommands= {
	["say"]=function(user,tokens)			-- Send a message on mainchat as someone else Syntax - !say <nick>  <message>
		if not check(user,3,tokens,3) then return false end
		local msg =substring(tokens,3)
		msg = "<"..tokens[3].."> "..msg
		SendToRoom("PtokaX",user.sNick.." send a mainchat message saying "..msg,"#[Hub-Feed]" ,3)
		return msg
	end,
	["drop"]=function(user,tokens)		--Disconnect (drop) a user Syntax - !drop <nick>
		if not check(user,3,tokens,3,3) then return false end
		Core.Disconnect(tokens[3])
		SendToRoom("PtokaX",user.sNick.." dropped " ..tokens[3] ,"#[Hub-Feed]" ,3)
		return false
	end,
	["warn"]=function(user,tokens)		--Send a warning on mainchat as the mainbot Syntax - !warn <nick> <reason>
		if not check(user,3,tokens,3,3) then return false end
		local reason =substring(tokens,3)
		local warning = "<PtokaX> "..tokens[3].." has been warned for : "..reason..". If it doesnt calm down it WILL be kicked from the hub."
		return warning
	end,
	["kick"]=function(user,tokens)		--Disconnect the victim and tempban him/her for 10 mins Syntax -!kick <nick> <reason>
		if not check(user,3,tokens,3,3) then return false end
		victim=tokens[3]
		local reason =substring(tokens,3)
		BanMan.TempBanNick(victim,10,reason,user.sNick)
		if reason then
			SendToRoom(user.sNick, "Kicking "..victim.." for: "..reason,"#[Hub-Feed]" ,3)
		else
			SendToRoom(user.sNick, "Kicking "..victim.." .","#[Hub-Feed]" ,3)
		end
		return false
	end,
	["mute"]=function(user,tokens)		--Mute the  victim indefinitely, preventing him/her from posting on mainchat Syntax - !mute <nick>
		if not check(user,3,tokens,3,3) then return false end
		victim=tokens[3]
		muted[tokens[3]] = true
		SendToRoom(user.sNick, "Muting "..victim.." .","#[Hub-Feed]" ,3)
		return false
	end,
	["unmute"]=function(user,tokens)		--Unmute the person Syntax - !unmute <nick>
		if not check(user,3,tokens,3,3) then return false end
		if isthere(tokens[3],muted) then
			muted[tokens[3]] = nil
			SendToRoom(user.sNick, "Unmuting "..tokens[3],"#[Hub-Feed]" ,3)
		else
			notify(user,tokens[3].." is not muted.|")
		end
		return false
	end,
	["foreveralone"]=function(user,tokens)		--Hellban the person i.e only he/she can see their posts on mainchat Syntax - !foreveralone <nick>
		if not check(user,3,tokens,3,3) then return false end
		falone[tokens[3]] = true
		SendToRoom("PtokaX",tokens[3].." was aloned by ".. user.sNick,"#[Hub-Feed]" ,3)
		return false
	end,
	["nomorealone"]=function(user,tokens)		--Remove the hellban Syntax - !nomorealone <nick>
		if not check(user,3,tokens,3,3) then return false end
		if isthere(tokens[3],falone) then
			falone[tokens[3]] = nil
			SendToRoom("PtokaX",tokens[3].." was un-aloned by ".. user.sNick,"#[Hub-Feed]" ,3)
		else
			notify(user, tokens[3].." has not been aloned.|")
		end
		return false
	end,
	["changenick"]=function(user,tokens)	--Change the nick of the vicitim on mainchat Syntax - !changenick <original_nick> <new_nick>
		if not check(user,0,tokens,4,3) then return false end
		nickc[tokens[3]]= tokens[4]
		SendToRoom("PtokaX",user.sNick.." changed nick of "..tokens[3].." to "..tokens[4],"#[Hub-Feed]" ,3)
		return false
	end,
	["revertnick"]=function(user,tokens)	-- Undo the effect of !changenick Syntax - !revertnick <original_nick>
		if not check(user,0,tokens,3,3) then return false end
		if isthere(tokens[3],nickc) then
			nickc[tokens[3]] = nil
			notify(user, tokens[3].."'s nick has been changed back.|" )
			SendToRoom("PtokaX", user.sNick.." changed back "..tokens[3].."'s nick.", "#[Hub-Feed]" ,3)
		else
			notify(user,tokens[3].."'s nick has not been changed.|")
		end
		return false
	end,
	-- General Commands
	["unsub"]=function(user,tokens)	-- Unsubscribe from mainchat - Syntax - !unsub
		if not isthere_key(user.sNick,unsubbed) then
		key = isthere_key(user.sNick,subbed)
		while key do
			table.remove( subbed, key)
			key = isthere_key(user.sNick,subbed)
		end
		table.insert( unsubbed, user.sNick )
		pickle.store( path.."files/mcunsubs.txt", {unsubbed=unsubbed} )
		notify(user,"You have unsubscribed from mainchat.|")
		end
		return false
	end,
	["sub"]=function(user,tokens)	-- Subscribe back to mainchat Syntax - !sub
		if not isthere_key(user.sNick,subbed) then
		key = isthere_key(user.sNick,unsubbed)
		while key do
			table.remove( unsubbed, key)
			key = isthere_key(user.sNick,unsubbed)
		end
		table.insert(subbed,user.sNick)
		pickle.store( path.."files/mcunsubs.txt", {unsubbed=unsubbed} )
		notify(user,"You have subscribed back")
		end
		return false
	end,
      	["me"]=function(user,tokens)	-- Speak in third person.Identical to /me command on IRC, Syntax - !me <message>
		local msg =substring(tokens,2)
		msg = user.sNick.." "..msg
		return msg
	end,
	--For fun
	["desu"]=function(user)	--Toggles desu variable .if desu is true , appends desu to every message on mainchat Syntax - !desu
		if not check(user,0) then return false end
		desu=not desu
		return false
	end,
	["san"]=function(user)	--Toggles san variable.If san is true, appends -san to every nick on mainchat .Example - Brick -> Brick-san Syntax - !san
		if not check(user,0) then return false end
		san= not san
		return false
	end,
	["chan"]=function(user)	 ---Toggles chan variable.If chan is true, appends -chan to every nick on mainchat .Example - Brick -> Brick-chan Syntax - !san
		if not check(user,0) then return false end
		chan=not chan
		return false
	end,
	--adminstrative shortcuts
	["send"]=function(user,tokens) -- Send message to all in the form of raw data(without adding any dcprotocol keywords) . Syntax - !send <message>
		if not check(user,0) then return false end
		local msg =substring(tokens,2)
		return msg
	end,
	["changereg"]=function(user,tokens) -- Change the profile of a registered user. Syntax - !changereg <user_nick> <profile_num>
		if not check(user,0,tokens,4) then return false end
		local account=RegMan.GetReg(tokens[3])
		local profile=ProfMan.GetProfile(tonumber(tokens[4]))
		if not account then
		notify(user,"No registered user with nick "..tokens[3])
		return false
		end
		if not profile then
		notify(user,"No profile with number "..tokens[4])
		return false
		end
		RegMan.ChangeReg(account.sNick,account.sPassword,tonumber(tokens[4]))
		Core.Disconnect(tokens[3])
		notify(user,"Profile of "..tokens[3].." changed to "..profile.sProfileName)
		return false
	end,
	["getpass"]=function(user,tokens)-- Get the password of a registered user Syntax - !getpass <nick>
		if not check(user,0,tokens,3) then return false end
		account=RegMan.GetReg(tokens[3])
		if not account then
		notify(user,"No registered user with nick "..tokens[3])
		return false
		end
		notify(user,"Nick="..account.sNick.." Password: "..account.sPassword)
		return false
	end,
        ["clrpassbans"]=function(user,tokens)	--Clear the automatic bans done due to incorrect password imput .Syntax !clrpassbans
		if not check(user,0) then return false end
		local bans = BanMan.GetPermBans()
		for k,v in ipairs(bans) do
		if v.sReason and v.sReason:find("3x bad password") then
			BanMan.UnbanPerm(v.sIP)
		end
		end
		notify(user,"Password Bans Cleared")
		return false
	end,
	["getprofiles"]=function(user,tokens)	--Gives a list of all profiles . Syntax !getprofiles
		if not check(user,0) then return false end
		local profiles = ProfMan.GetProfiles()
		local msg = "\n\tProfile name\t\tNumber"
		for k,profile in ipairs(profiles) do
		msg=msg.."\n\t"..profile.sProfileName.."\t\t"..profile.iProfileNumber
		end
		notify(user,msg)
		return false
	end,
}

custcom=function(user,data)
	local tokens= tokenize(data)
	_,_,tokens[2]=string.find(tokens[2],".(%S+)")
	local msg=CustomCommands[tokens[2]](user,tokens)
	return msg
end
