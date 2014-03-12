PLUGIN.Title           = "Arena"
PLUGIN.Description     = ""
PLUGIN.Author          = "Kitboga, Soarnsky"
PLUGIN.Version         = "1.0 Alpha"

PLUGIN.playerList	= {}
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
   timer.Once(10, function()
      message = "Arena will start in 2 mins !"
      rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
      timer.Once(60, function()
      	 message = "Arena will start in 1 min !"
         rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
         timer.Once(60, function()
            -- start the game
            Arena.playing = true
            Arena:givePlayerKits()
            message = "FIGHT !!!"
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
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
  for p=1,table.getn(Arena.playerList) do
    for k=1, table.getn(Arena.theKits[Arena.kitToUse])-1 do
      rust.RunServerCommand('inv.giveplayer "'.. p.displayName .. '" "' .. k[k+1][2] .. '" "' .. k[l+1][1] .. '"')
    end
  end
end
     

function PLUGIN:Coord( netuser )
    local coords = netuser.playerClient.lastKnownPosition
    rust.SendChatToUser( netuser, "Current Position: {x: " .. coords.x .. ", y: " .. coords.y .. ", z: " .. coords.z .. "}")
end

function PLUGIN:displayArena( netuser )
	for i, player in ipairs(Arena.playerList) do
		print(playerList[i])
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
end


function PLUGIN:SendHelpText( netuser )
    rust.SendChatToUser( netuser, "Use /ahelp to see Arena commands" )
end
