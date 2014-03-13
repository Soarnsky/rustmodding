PLUGIN.Title           = "Arena"
PLUGIN.Description     = ""
PLUGIN.Author          = "Kitboga, Soarnsky"
PLUGIN.Version         = "1.0 Alpha"

PLUGIN.playerList	= {}
PLUGIN.alivePlayers     = {}
PLUGIN.isOn 		= false
PLUGIN.playing		= false

PLUGIN.kitToUse = 1
PLUGIN.theKits = {}
PLUGIN.theKits[1] = { "Pistols" , { 99, "9mm Ammo"}, { 1, "9mm Pistol"}, { 5, "Large Medkit"} }
PLUGIN.theKits[2] = { "Bows" , { 50, "Arrow"}, { 1, "Hunting Bow"}, { 1, "Large Medkit"} }
PLUGIN.theKits[3] = { "Millitary" , { 199, "9mm Ammo"}, { 1, "MP54A"}, { 5, "Large Medkit"}, { 2, "F1 Grenade"}, { 1, "Kevlar Vest"} }

-- Initializes the plugin
function PLUGIN:Init()
   Arena = self
   Arena.isOn = false
   Arena:AddChatCommand( "startarena", Arena.arenaON )
   Arena:AddChatCommand( "stoparena", Arena.arenaOFF )
   Arena:AddChatCommand( "join", Arena.arenaPort )
   Arena:AddChatCommand( "coord", Arena.Coord )
   Arena:AddChatCommand( "arena", Arena.displayArena )
   Arena:AddChatCommand( "ahelp", Arena.AHELP )
end

function PLUGIN:arenaON( netuser )
   if ( not(netuser:CanAdmin()) ) then
  rust.Notice( netuser, "Only admins can do this!" )
  return
  end
   Arena.isOn= true
   Arena.playerList = {}
   message = "Arena open! Type /join to join ( BEWARE -- your inventory will be cleared )"
   rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
   timer.Once(15, function()
      message = "Arena will start in 2 mins !"
      rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
      timer.Once(15, function()
      	 message = "Arena will start in 1 min !"
         rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
         timer.Once(15, function()
            -- start the game
            message = "Handing out your weapons..."
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
            Arena.playing = true
            Arena:givePlayerKits()
            timer.Once(15, function()
               message = "FIGHT !!!"
               rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
            end)
         end)
      end)
   end)
   return
end

function PLUGIN:arenaOFF( netuser )
   if ( not(netuser:CanAdmin()) ) then
  rust.Notice( netuser, "Only admins can do this!" )
  return
  end
   Arena.isOn= false
   Arena.playing = false
   message = "Arena is closed!"
   rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
   return
end

function PLUGIN:arenaPort( netuser )
   if (Arena.isOn== true and Arena.playing== false) then
     Arena:clearInventory(netuser)
     local coords = netuser.playerClient.lastKnownPosition
     coords.x = 3440.619628903 --Xcoordinates arena
     coords.y = 353.20803833008 --Ycoordinates arena
     coords.z = 1167.337890625 --Zcoordinates arena
     rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, coords)
	 table.insert( Arena.playerList, netuser )
	 table.insert( Arena.alivePlayers, netuser )
   else
     rust.Notice(netuser, "Arena is closed!")
   end
   return
end

function PLUGIN:clearInventory( netuser )
  local inv = rust.GetInventory(netuser)
  if (not inv) then return end
  for i=0,39 do
    local b, item = inv:GetItem(i)
    if (b) then inv:RemoveItem(item) end
  end
end 

function PLUGIN:givePlayerKits()
  -- give each netuser a kit 
  -- PLUGIN.theKits[1] = { "Pistols" , { 99, "9mm Ammo"}, { 1, "9mm Pistol"}, { 5, "Large Medkit"} }
local PL = Arena.playerList
local KL = Arena.theKits[Arena.kitToUse]
  print(KL)
  for p=1,#Arena.playerList do
    for k=1, (#Arena.theKits[Arena.kitToUse])-1 do
        print((#Arena.theKits[Arena.kitToUse])-1 )
        print(PL[p].displayName)
        print(KL[k+1][2])
      	--rust.RunServerCommand("inv.giveplayer ".. PL[p].displayName .. " " .. KL[k+1][2] .. " " .. KL[k+1][1])
        rust.RunServerCommand('inv.giveplayer "'.. PL[p].displayName .. '" "' .. KL[k+1][2] .. '" "' .. KL[k+1][1] .. '"')
    end
  end
end
     

function PLUGIN:Coord( netuser )
    local coords = netuser.playerClient.lastKnownPosition
    rust.SendChatToUser( netuser, "Current Position: {x: " .. coords.x .. ", y: " .. coords.y .. ", z: " .. coords.z .. "}")
end

function PLUGIN:displayArena( netuser )
  rust.SendChatToUser( netuser, #Arena.playerList .. " participant(s):" )
	for i, player in ipairs(Arena.playerList) do
		rust.SendChatToUser( netuser, Arena.playerList[i].displayName)
	end
end

function PLUGIN:AHELP( netuser )
	rust.SendChatToUser( netuser, "Use /join to tp to the Arena if it is open, /coord to check location" )
    if (netuser:CanAdmin()) then
        rust.SendChatToUser( netuser, "Use /startarena and /stoparena to activate/deactivate arena" )
    end
end

-- Called when the server is initialized
function PLUGIN:OnServerInitialized()
	print(Arena.Title .. " v" .. Arena.Version .. " loaded!")
	print(Arena.theKits)
	print(Arena.theKits[kitToUse])
end

-- Tests if a value is contained in a table
function PLUGIN:containsVal(t, val)
	for _,v in ipairs(t) do
		if (v == val) then
			return true
		end
	end
	return false
end

-- Removes a value from an array
function PLUGIN:removeVal(t, val)
	for i,v in ipairs(t) do
		if (v == val) then
			table.remove(t, i)
			rust.BroadcastChat("Arena", val.displayName .. " died in the arena...")
			return true
		end
	end

	return false
end

-- called when someone is killed
function PLUGIN:OnKilled( target, dmg )
   if(Arena.isOn== true and Arena.playing== true)
   then
      if(dmg.attacker and dmg.attacker.client )
         -- local player = dmg.attacker.client.netUser
	 -- local playerattacker = player.displayName
	 local component = target:GetComponent("HumanController")
	 if (not component) then return end
	 local victim = rust.NetUserFromNetPlayer(component.networkViewOwner)
	 -- check to see if the victim is part of the arena match
	 if( Arena:containsVal(Arena.playerList, victim)
	 then
	    -- the player was killed in the arena so remove him from the aliveplayers array
	    Arena:removeVal(Arena.alivePlayers, victim)
	    rust.BroadcastChat("Arena", playerattacker .. " has slain " .. victim.playerName)
	    if(#Arena.alivePlayers == 1)
	    then
	      timer.Once(15, function()
               message = "Arena Winner: " .. playerattacker
               rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
               Arena:arenaOFF()
              end)
	    end
            elseif(#Arena.alivePlayers == 0)
    	     then
    	     timer.Once(15, function()
               message = "Arena Finished (everyone died)"
               rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
               Arena:arenaOFF()
              end)
    	    end
	 end
      end
   end
end

function PLUGIN:SendHelpText( netuser )
    rust.SendChatToUser( netuser, "Use /ahelp to see Arena commands" )
end
