PLUGIN.Title           = "Arena"
PLUGIN.Description     = ""
PLUGIN.Author          = "Kitboga, Soarnsky"
PLUGIN.Version         = "1.11 Alpha"

PLUGIN.playerList      = {}
PLUGIN.playerOriLoc    = {}
PLUGIN.alivePlayers    = {}
PLUGIN.isOn            = false
PLUGIN.playing         = false

PLUGIN.kitToUse        = 1
PLUGIN.theKits         = {}
PLUGIN.theKits[1]      = { "Pistols" , { 99, "9mm Ammo"}, { 1, "9mm Pistol"}, { 5, "Large Medkit"} }
PLUGIN.theKits[2]      = { "Bows" , { 50, "Arrow"}, { 1, "Hunting Bow"}, { 1, "Large Medkit"} }
PLUGIN.theKits[3]      = { "Millitary" , { 199, "9mm Ammo"}, { 1, "MP54A"}, { 5, "Large Medkit"}, { 2, "F1 Grenade"}, { 1, "Kevlar Vest"} }

-- Initializes the plugin
function PLUGIN:Init()
    Arena = self
    Arena.LoadConfig()
    Arena.isOn = false
    Arena:AddChatCommand( "startarena", Arena.cmdStartArena )
    Arena:AddChatCommand( "stoparena", Arena.cmdStopArena )
    Arena:AddChatCommand( "join", Arena.cmdJoin )
    Arena:AddChatCommand( "coord", Arena.cmdCoord )
    Arena:AddChatCommand( "arena", Arena.cmdArena )
    Arena:AddChatCommand( "ahelp", Arena.cmdAHELP )
end

function PLUGIN:LoadConfig()
    local b, res = config.Read("arena")
    Arena.Config = res or {}
    if (not b) then
        Arena:LoadDefaultConfig()
        if (res) then config.Save("arena") end
    end
end

function PLUGIN:cmdStartArena( netuser )
    if ( not(netuser:CanAdmin()) ) then
        rust.Notice( netuser, "Only admins can do this!" )
    else
        Arena.isOn = true
        Arena.playerList = {}
        message = "Arena starts in " .. Arena.Config.startDelay/60 ..
                  " min! Type /join to join ( BEWARE -- your inventory will be cleared )"
        -- message = "Arena starts in 2 min"
        rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
        --Timer is split equally into 3 parts
        --First notification
        timer.Once(Arena.Config.startDelay/3, function()
        message = "Arena will start in " .. (((Arena.Config.startDelay/60)/3)*2) .. " min!"
        --message = "Arena starts in 1 min"
        if Arena.isOn then 
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
        else return end
        --Second notification
        timer.Once((Arena.Config.startDelay/3)-Arena.Config.setupDelay, function()
      	message = "Arena will start in " .. ((Arena.Config.startDelay/60)/3) .. " min!"
        --message = "Arena blah mins"
        if Arena.isOn then
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
        else return end
        --Distribute kits
        timer.Once(Arena.Config.setupDelay/2, function()       
        message = "Handing out your weapons..."
        if Arena.isOn then
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
        else return end
        Arena.playing = true
        Arena:givePlayerKits()
        --Start the arena
        timer.Once(Arena.Config.setupDelay/2, function()
        message = "FIGHT !!!"
        if Arena.isOn then
            rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
        else return end
        end) end) end) end)
    end
    return
end

function PLUGIN:cmdStopArena( netuser )
    if ( not(netuser:CanAdmin()) ) then
        rust.Notice( netuser, "Only admins can do this!" )
    else
        Arena.isOn = false
        Arena.playing = false
        message = "Arena is closed!"
        rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
    end 
    return
end

function PLUGIN:cmdJoin( netuser )
    if (Arena.isOn == true and Arena.playing == false) then
        Arena:clearInventory(netuser)
        local coords = netuser.playerClient.lastKnownPosition
        -- add to an array to teleport them back later !
        table.insert ( Arena.playerOriLoc, coords) 
        
        coords.x = Arena.Config.arenaX --Xcoordinates arena
        coords.y = Arena.Config.arenaY --Ycoordinates arena
        coords.z = Arena.Config.arenaZ --Zcoordinates arena
        rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, coords)
        table.insert( Arena.playerList, netuser )
        table.insert( Arena.alivePlayers, netuser )
    else rust.Notice(netuser, "Arena is closed!") end
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
    for p=1,#Arena.playerList do
        for k=1, (#Arena.theKits[Arena.kitToUse])-1 do
        --[[print((#Arena.theKits[Arena.kitToUse])-1 )
        print(PL[p].displayName)
        print(KL[k+1][2])
        rust.RunServerCommand("inv.giveplayer ".. PL[p].displayName .. " " .. KL[k+1][2] .. " " .. KL[k+1][1])]]
        rust.RunServerCommand('inv.giveplayer "'.. PL[p].displayName .. '" "' .. KL[k+1][2] .. '" "' .. KL[k+1][1] .. '"')
        end
    end
end
     

function PLUGIN:cmdCoord( netuser )
    local coords = netuser.playerClient.lastKnownPosition
    rust.SendChatToUser( netuser, "Current Position: {x: " .. coords.x .. ", y: " .. coords.y .. ", z: " .. coords.z .. "}")
end

function PLUGIN:cmdArena( netuser )
    local players = ""
    rust.SendChatToUser( netuser, #Arena.playerList .. " participant(s):" )
	for i in ipairs(Arena.playerList) do
        if (i%5 ~= 0 and i ~= #Arena.playerList) then
            players = players .. Arena.playerList[i].displayName .. ", "
        elseif (i == #Arena.playerList) then
            players = players .. Arena.playerList[i].displayName .. "."
        end
    end
    rust.SendChatToUser( netuser, players)	 
end

function PLUGIN:cmdAHELP( netuser )
	  rust.SendChatToUser( netuser, "Use /join to tp to the Arena if it is open, /coord to check location" )
    if (netuser:CanAdmin()) then
        rust.SendChatToUser( netuser, "Use /startarena and /stoparena to activate/deactivate arena" )
    end
end

-- Called when the server is initialized
function PLUGIN:OnServerInitialized()
    print(Arena.Title .. " v" .. Arena.Version .. " loaded!")
    print((Arena.Config.startDelay/60)/3)
end

-- Tests if a value is contained in a table
function PLUGIN:containsVal(t, val)
	  for i,v in ipairs(t) do
		    if (v == val) then return i end
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
-- called when they first spawn
function PLUGIN:OnSpawn ( playerClient, useCamp, avatar )
    timer.Once(0, function()
        local isAPlayer = Arena:containsVal(Arena.playerList, playerClient.netUser)
        if(isAPlayer)
            local originalLocation = Arena.playerOriLoc[isAPlayer]
            rust.ServerManagement():TeleportPlayer(playerClient.netPlayer, originalLocation)
        end
    end
end
-- called when someone is killed
function PLUGIN:OnKilled( target, dmg )
    if(Arena.isOn== true and Arena.playing== true) then
        if(dmg.attacker and dmg.attacker.client ) then
            local player = dmg.attacker.client.netUser
            local playerattacker = player.displayName
            local component = target:GetComponent("HumanController")
            if(not component) then return end
            local victim = rust.NetUserFromNetPlayer(component.networkViewOwner)
            -- check to see if the victim is part of the arena match
            if( Arena:containsVal(Arena.playerList, victim)) then
                -- the player was killed in the arena so remove him from the aliveplayers array
                Arena:removeVal(Arena.alivePlayers, victim)
                -- not working with suicide
                rust.BroadcastChat("Arena", playerattacker .. " has slain " .. victim.playerName)
                if(#Arena.alivePlayers == 1) then
                    timer.Once(15, function()
                    message = "Arena Winner: " .. playerattacker
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
                    
                    -- kill this person, or teleport them lol
                      timer.Once(15, function()
                      local isAPlayer = Arena:containsVal(Arena.playerList, player)
		         if(isAPlayer)
		           -- clear the inventory before teleporting
		           Arena:clearInventory( player ) 
                           local originalLocation = Arena.playerOriLoc[isAPlayer]
                           rust.ServerManagement():TeleportPlayer(player, originalLocation)
                         end
                       end)
                       Arena:cmdStopArena()
                    end)
                elseif(#Arena.alivePlayers == 0) then
                    timer.Once(15, function()
                    message = "Arena Finished (everyone died)"
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
                    Arena:cmdStopArena()
                    end)
                end
            end
        end
    end
end

function PLUGIN:SendHelpText( netuser )
    rust.SendChatToUser( netuser, "Use /ahelp to see Arena commands" )
end

function PLUGIN:LoadDefaultConfig()
    Arena.Config.startDelay = 300.00
    Arena.Config.setupDelay = 30.00
    Arena.Config.arenaX = 3440.619628903
    Arena.Config.arenaY = 353.20803833008
    Arena.Config.arenaZ = 1167.337890625
end
