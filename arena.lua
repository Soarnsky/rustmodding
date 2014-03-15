PLUGIN.Title           = "Arena"
PLUGIN.Description     = ""
PLUGIN.Author          = "Kitboga, Soarnsky"
PLUGIN.Version         = "1.2 Alpha"

PLUGIN.playerList      = {}
PLUGIN.playerOriLoc    = {}
PLUGIN.alivePlayers    = {}
PLUGIN.isOn            = false
PLUGIN.playing         = false

PLUGIN.kitToUse        = 1
PLUGIN.theKits         = {}
PLUGIN.theKits[1]      = { "Pistols" , { 99, "9mm Ammo"}, { 1, "9mm Pistol"}, { 5, "Large Medkit"} }
PLUGIN.theKits[2]      = { "Bows" , { 50, "Arrow"}, { 1, "Hunting Bow"}, { 1, "Large Medkit"} }
PLUGIN.theKits[3]      = { "Military" , { 199, "9mm Ammo"}, { 1, "MP5A4"}, { 5, "Large Medkit"}, { 1, "Kevlar Helmet"}, { 1, "Kevlar Vest"}, { 1, "Kevlar Pants"}, { 1, "Kevlar Boots"} }

-- Initializes the plugin
function PLUGIN:Init()
    Arena = self
    Arena.LoadConfig()
    Arena.isOn = false
    Arena.kitToUse = Arena.Config.kitToUse
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
    elseif (not Arena.isOn) then
        Arena.isOn = true
        Arena.playerList = {}
        Arena.alivePlayers = {}
        Arena.playerOriLoc = {}
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
        message = "Handing out your " ..  Arena.theKits[Arena.kitToUse][1] .. " weapon kit..."
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

--for function calls, not chat command
function PLUGIN:stopArena()
        Arena.isOn = false
        Arena.playing = false
    return
end

function PLUGIN:cmdJoin( netuser )
    if (Arena.isOn == true and Arena.playing == false) then
        Arena:clearInventory(netuser)
        --need both oldCoords and newCoords
        local oldCoords = netuser.playerClient.lastKnownPosition
        local newCoords = netuser.playerClient.lastKnownPosition
        -- add to an array to teleport them back later !
        oldCoords.y = oldCoords.y + 2
        Arena.playerOriLoc[netuser] = oldCoords
        newCoords.x = Arena.Config.arenaX --Xcoordinates arena
        newCoords.y = Arena.Config.arenaY --Ycoordinates arena
        newCoords.z = Arena.Config.arenaZ --Zcoordinates arena
        rust.ServerManagement():TeleportPlayer(netuser.playerClient.netPlayer, newCoords)
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
    local inv
    for p=1,#Arena.playerList do
        inv = rust.GetInventory(PL[p])
        for k=1, (#Arena.theKits[Arena.kitToUse])-1 do
            local item = rust.GetDatablockByName(KL[k+1][2])
            local pref = rust.InventorySlotPreference( InventorySlotKind.Belt, false, InventorySlotKindFlags.Belt)
            if(string.find(KL[k+1][2], "Ammo") or string.find(KL[k+1][2], "Shell") or string.find(KL[k+1][2], "Arrow")) 
            	then
            	   pref = rust.InventorySlotPreference( InventorySlotKind.Default, false, InventorySlotKindFlags.Belt)
            	end
            if(string.find(KL[k+1][2], "Helmet") or string.find(KL[k+1][2], "Boots") or string.find(KL[k+1][2], "Pants") or string.find(KL[k+1][2], "Vest")) 
               then
            	  pref = rust.InventorySlotPreference( InventorySlotKind.Armor, false, InventorySlotKindFlags.Armor)
               end
            local amt = KL[k+1][1]
            inv:AddItemAmount( item, amt, pref )
        end
    end
end
     

function PLUGIN:cmdCoord( netuser )
    local coords = netuser.playerClient.lastKnownPosition
    rust.SendChatToUser( netuser, "Current Position: {x: " .. coords.x .. ", y: " .. coords.y .. ", z: " .. coords.z .. "}")
end

function PLUGIN:cmdArena( netuser )
    local players = ""
    if Arena.isOn then
        rust.SendChatToUser( netuser, #Arena.playerList .. " participant(s):" )
	    for i in ipairs(Arena.playerList) do
            if (i%5 ~= 0 and i ~= #Arena.playerList) then
                players = players .. Arena.playerList[i].displayName .. ", "
            elseif (i == #Arena.playerList) then
                players = players .. Arena.playerList[i].displayName .. "."
            end
        end
        rust.SendChatToUser( netuser, players)
    else
        rust.Notice( netuser, "Arena is closed!")
    end
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
end

-- Tests if a value is contained in a table
function PLUGIN:containsVal(t, val)
	for i,v in ipairs(t) do
		if (v == val) then return i end
	end
	return false
end

-- Removes a value from a table
function PLUGIN:removeVal(t, val)
    for i,v in ipairs(t) do
		if (v == val) then
			table.remove(t, i)
			return true
		end
	end
	return false
end
-- called when they first spawn
function PLUGIN:OnSpawnPlayer( playerClient, useCamp, avatar )
    timer.Once(0, function()
        local player = playerClient.netUser
        local isAPlayer = Arena:containsVal(Arena.playerList, player)
        if(isAPlayer)
        then
            local originalLocation = Arena.playerOriLoc[player]
            rust.ServerManagement():TeleportPlayer(playerClient.netPlayer, originalLocation)
            Arena:removeVal(Arena.playerList, player)
            Arena:removeVal(Arena.playerOriLoc, player)
        end
    end)
end

-- if someone were to disconnect we need to remove them from the lists
function PLUGIN:OnUserDisconnect(netPlayer)
    if(Arena.isOn== true and Arena.playing== true) then
        local netuser = rust.NetUserFromNetPlayer(netPlayer)
        if(Arena:containsVal(Arena.playerList, netuser))
            then
            Arena:removeVal(Arena.playerList, netuser)
            Arena:removeVal(Arena.alivePlayers, netuser)
            rust.BroadcastChat("Arena", netUser.displayName .. " has left the arena... ")
            
            if(#Arena.alivePlayers == 1) then
                    timer.Once(15, function()
                    message = "Arena Winner: " .. Arena.alivePlayers[1]
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")

                    -- kill this person, or teleport them lol
                    local isAPlayer = Arena:containsVal(Arena.playerList, netuser)
		            if(isAPlayer) then
		           -- clear the inventory before teleporting
		                Arena:clearInventory( netuser ) 
                        local originalLocation = Arena.playerOriLoc[netuser]
                        rust.ServerManagement():TeleportPlayer(netPlayer, originalLocation)
                        end
                    end)
                    Arena:stopArena()
                elseif(#Arena.alivePlayers == 0) then
                    timer.Once(15, function()
                    message = "Arena Finished (everyone died)"
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
                    rust.BroadcastChat("Arena", "No winner... everyone died.")
                    Arena:stopArena()
                    end)
                end
            
        end
        
    end
end

-- called when someone is killed
function PLUGIN:OnKilled( target, dmg )
    if(Arena.isOn and Arena.playing) then
        if(dmg.attacker and dmg.attacker.client ) then
            local player = dmg.attacker.client
            local playerattacker = player.netUser.displayName
            local component = target:GetComponent("HumanController")
            if(not component) then return end
            local victim = rust.NetUserFromNetPlayer(component.networkViewOwner)
            -- check to see if the victim is part of the arena match
            if( Arena:containsVal(Arena.playerList, victim)) then
                -- the player was killed in the arena so remove him from the aliveplayers array
                Arena:removeVal(Arena.alivePlayers, victim)
                Arena:clearInventory( victim ) 
                rust.BroadcastChat("Arena", victim.displayName .. " died in the arena...")
                -- not working with suicide
                rust.BroadcastChat("Arena", playerattacker .. " has slain " .. victim.displayName)
                if(#Arena.alivePlayers == 1) then
                    timer.Once(15, function()
                    message = "Arena Winner: " .. playerattacker
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
                    rust.BroadcastChat("Arena", playerattacker .. " wins!")
                    -- kill this person, or teleport them lol
                    local isAPlayer = Arena:containsVal(Arena.playerList, player.netUser)
		            if(isAPlayer) then
		           -- clear the inventory before teleporting
		                Arena:clearInventory( player.netUser ) 
                        local originalLocation = Arena.playerOriLoc[player.netUser]
                        rust.ServerManagement():TeleportPlayer(player.netPlayer, originalLocation)
                        if( Arena:containsVal(Arena.alivePlayers, player.netUser)) then
                            Arena:removeVal(Arena.alivePlayers, player.netUser)
                        end
                        Arena:removeVal(Arena.playerList, player.netUser)
                    end
                    end)
                    Arena:stopArena()
                elseif(#Arena.alivePlayers == 0) then
                    timer.Once(15, function()
                    message = "Arena Finished (everyone died)"
                    rust.RunServerCommand("notice.popupall \"" .. message .. "\"")
                    rust.BroadcastChat("Arena", "No winner... everyone died.")
                    Arena:stopArena()
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
