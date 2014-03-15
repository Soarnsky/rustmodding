PLUGIN.Title = "Ownership Remover"
PLUGIN.Description = "House 'ownership' so you can easily destroy misplaced objects"
PLUGIN.Version = "1.0.1"
PLUGIN.Author = "ZOR"

function PLUGIN:Init()
    self.nextHitNotes = {}
    self.CfgFile, self.Cfg = self:readFileToMap("ownremCfg")
    self.removerFlag = "ownremover"
    self:initCfgParam("exclusiveRemovers",false)
    self:initCfgParam("giveNewItem",false)
    self:initCfgParam("giveResources",true)
    self:initCfgParam("onlySkeleton",false)
    self:initCfgParam("hatchetEnabled",false)
    self:initCfgParam("allowPillarLances",true)
    self:initCfgParam("econIntegration",false)
    self:initCfgParam("adminOwns",false)
    self.econ= plugins.Find("econ")
    self:AddChatCommand("ownremflag", self.cmdFlag)

    print( self.Title .. " v" .. self.Version .. " loaded!" )
end


function PLUGIN:SendHelpText( netuser )
    if self.econ and self.econIntegration and self.econ.ownremoveFee then
        rust.SendChatToUser( netuser,
            "* You can remove some of structures misplaced by you with Pick Axe! (for "..self.econ:moneyStr(self.econ.ownremoveFee)..")" )
    else
    rust.SendChatToUser( netuser, "* You can remove some of structures misplaced by you with Pick Axe! *" ) end
    if netuser:CanAdmin()  then
         rust.SendChatToUser( netuser, "Use /ownremflag \"giveResources|giveNewItem|onlySkeleton\" to change boolean flag state" )
    return end
end

function PLUGIN:cmdFlag( netuser, cmd, args )
    if not netuser:CanAdmin()  then return end
    local flag = args[1]
    if flag then
        if self[flag] == nill then
            rust.SendChatToUser(netuser,  "No flag with name ["..args[1].."] found")
            return end
        self[flag] = not self[flag]
        self.Cfg[flag] = self[flag]
        rust.SendChatToUser(netuser,  "Flag [ "..args[1].." ] is now [ "..tostring(self[flag]).." ]")
        self:SaveMapToFile( self.Cfg,self.CfgFile)
    end
end

local GetComponents, SetComponents = typesystem.GetField( Rust.StructureMaster, "_structureComponents", bf.private_instance )
local NetCullRemove = util.FindOverloadedMethod( Rust.NetCull._type, "Destroy", bf.public_static, { UnityEngine.GameObject} )
function PLUGIN:getConnectedComponents( master )
    local hashset = GetComponents( master )
    local tbl = {}
    local it = hashset:GetEnumerator()
    while (it:MoveNext()) do
        tbl[ #tbl + 1 ] = it.Current end
    return tbl end
function RemoveGObject(object)
    local arr = util.ArrayFromTable( cs.gettype( "System.Object" ), { object } )  ;
    cs.convertandsetonarray( arr, 0, object , UnityEngine.GameObject._type )
    NetCullRemove:Invoke( nil, arr ) end

local RemovableTools = {}
RemovableTools["9mm Ammo"] = true
RemovableTools["Pick Axe"] = true
RemovableTools["Hatchet"] = true
RemovableTools["9mm Pistol"] = true
RemovableTools["Shotgun"] = true
RemovableTools["MP5A4"] = true
local RemovableItem = {}
RemovableItem["Wood_Shelter(Clone)"] = { name = "Wood Shelter", give = "Wood", giveAmount = 20 }
--RemovableItem["Campfire(Clone)"] = {name="Camp Fire", give="Wood",giveAmount=50 }
RemovableItem["Furnace(Clone)"] = { name = "Furnace", give = "Stones", giveAmount = 30 }
RemovableItem["Workbench(Clone)"] = { name = "Workbench", give = "Wood", giveAmount = 40 }
RemovableItem["SingleBed(Clone)"] = { name = "Bed", give = "Metal Fragments", giveAmount = 50 }
--RemovableItem["SleepingBagA(Clone)"] = {name="Sleeping Bag", give="Cloth",giveAmount=10 }
-- Attack and protect
--RemovableItem["LargeWoodSpikeWall(Clone)"] = {name="Large Spike Wall", give="Wood",giveAmount=100 }
--RemovableItem["WoodSpikeWall(Clone)"] = {name="Spike Wall", give="Wood",giveAmount=50 }
RemovableItem["Barricade_Fence_Deployable(Clone)"] = { name = "Wood Barricade", give = "Wood", giveAmount = 20 }
RemovableItem["WoodGateway(Clone)"] = { name = "Wood Gateway", give = "Wood", giveAmount = 200 }
RemovableItem["WoodGate(Clone)"] = { name = "Wood Gate", give = "Wood", giveAmount = 60 }
-- Storage
RemovableItem["WoodBoxLarge(Clone)"] = { name = "Large Wood Storage", give = "Wood", giveAmount = 40 }
RemovableItem["WoodBox(Clone)"] = { name = "Wood Storage Box", give = "Wood", giveAmount = 10 }
RemovableItem["SmallStash(Clone)"] = { name = "Small Stash", give = "Cloth", giveAmount = 5 }
-- Structure Wood
RemovableItem["WoodFoundation(Clone)"] = { name = "Wood Foundation", give = "Wood", giveAmount = 60 }
RemovableItem["WoodWindowFrame(Clone)"] = { name = "Wood Window", give = "Wood", giveAmount = 30 }
RemovableItem["WoodDoorFrame(Clone)"] = { name = "Wood Doorway", give = "Wood", giveAmount = 30 }
RemovableItem["WoodWall(Clone)"] = { name = "Wood Wall", give = "Wood", giveAmount = 20 }
RemovableItem["WoodenDoor(Clone)"] = { name = "Wooden Door", give = "Wood", giveAmount = 10 }
RemovableItem["WoodCeiling(Clone)"] = { name = "Wood Ceiling", give = "Wood", giveAmount = 30 }
RemovableItem["WoodRamp(Clone)"] = { name = "Wood Ramp", give = "Wood", giveAmount = 30 }
--RemovableItem["WoodStairs(Clone)"] = { name = "Wood Stairs", give = "Wood", giveAmount = 30 }
RemovableItem["WoodPillar(Clone)"] = { name = "Wood Pillar", give = "Wood", giveAmount = 10 }
-- Structure Metal
RemovableItem["MetalFoundation(Clone)"] = { name = "Metal Foundation", give = "Metal Fragments", giveAmount = 30 }
RemovableItem["MetalWall(Clone)"] = { name = "Metal Wall", give = "Metal Fragments", giveAmount = 20 }
RemovableItem["MetalDoorFrame(Clone)"] = { name = "Metal Doorway", give = "Metal Fragments", giveAmount = 20 }
RemovableItem["MetalDoor(Clone)"] = { name = "Metal Door", give = "Metal Fragments", giveAmount = 40 }
RemovableItem["MetalCeiling(Clone)"] = { name = "Metal Ceiling", give = "Metal Fragments", giveAmount = 40 }
RemovableItem["MetalStairs(Clone)"] = { name = "Metal Stairs", give = "Metal Fragments", giveAmount = 30 }
RemovableItem["MetalRamp(Clone)"] = { name = "Metal Ramp", give = "Metal Fragments", giveAmount = 30 }
RemovableItem["MetalBarsWindow(Clone)"] = {name="Metal Window Bars", give="Metal Fragments",giveAmount=50, needRemove = true }
RemovableItem["MetalWindowFrame(Clone)"] = { name = "Metal Window", give = "Metal Fragments", giveAmount = 20 }
RemovableItem["MetalPillar(Clone)"] = { name = "Metal Pillar", give = "Metal Fragments", giveAmount = 10 }

function PLUGIN:ModifyDamage(takedamage, damage)
    if damage.extraData == nil then return end
    if damage.attacker then if damage.attacker.client then
        local item = RemovableItem[takedamage.gameObject.Name]
        if damage.attacker.client.netUser and item then
            local user = damage.attacker.client.netUser
            local userID = rust.GetUserID(user)
            local creatorID = nil
            if (takedamage:GetComponent("DeployableObject")) then
                creatorID = takedamage:GetComponent("DeployableObject").creatorID
            elseif takedamage:GetComponent("StructureComponent") then
                creatorID = takedamage:GetComponent("StructureComponent")._master.creatorID
            end
            local isowner =  user.User.Userid == creatorID --or user:CanAdmin()
                and (not self.exclusiveRemovers or ( api.Exists("flags" ) and api.Call("flags", "HasFlag", user, self.removerFlag)) )
            if user:CanAdmin() and self.adminOwns  then  isowner = true end
            if  isowner and (RemovableTools[damage.extraData.dataBlock.name]
                    or (self.hatchetEnabled and damage.extraData.dataBlock.name == "Hatchet") ) then
                local isSkeletonItemTarget = false
                if takedamage:GetComponent("StructureComponent") then
                    local entity = takedamage:GetComponent("StructureComponent")
                    local master = entity._master
                    local tpos = entity.gameObject:GetComponent("Transform").position
                    local tname = item.name
                    --apply anti-floatin logic only for: --TODO use StructureComponentType
                    local tIsPillar = string.find(tname, "Pillar",1 ,true)
                    local tIsCeil = string.find(tname, "Ceiling",1 ,true)
                    local tIsFound= string.find(tname, "Foundation",1 ,true)
                    isSkeletonItemTarget = tIsPillar or tIsCeil or tIsFound
                    if  self.onlySkeleton and not isSkeletonItemTarget  then return end

                    isManyBasements = function(data, btype, height, pillarPose)
                        local around = 0
                        for _k, struct in pairs(data) do
                            local spos = struct:GetComponent("Transform").position
--                             print(struct.name .."="..spos.x.." "..spos.y.." "..spos.z.." ")
                            if string.find(struct.name, btype, 1, true) and spos.y == height and self:isPointIn2DRadius(pillarPose, spos, 3.55)
                            then around = around + 1
                            if (around > 1) then return true end
                            end
                        end
                        return false
                    end

                    if isSkeletonItemTarget  then
                        local connected = self:getConnectedComponents(master)
                        local rad = 2.52
                        local radc = 3.55
                        for k,v in pairs(connected) do
                            local pos = v:GetComponent("Transform").position
                            local searchRad = rad
                            if string.find(v.name, "Pillar",1 ,true) or tIsPillar then  searchRad = radc end
                            local inRad = self:isPointIn2DRadius(tpos, pos, searchRad) and  not (pos.x == tpos.x and pos.y == tpos.y and pos.z == tpos.z)
                            if inRad then
                                local allowDestroy = false
                                local isCeil,isPillar,isFound = string.find(v.name, "Ceiling",1 ,true) ,string.find(v.name, "Pillar",1 ,true) ,string.find(v.name, "Foundation",1 ,true)
                                local isRamp = string.find(v.name, "Ramp",1 ,true)
                                if(pos.y > tpos.y and pos.y < tpos.y + 5 )then       --  and pos.y < tpos.y + 5
--                 if user:CanAdmin() then  rust.SendChatToUser(user, "upper [" .. v.name .. "] upper") end
                                    if (tIsCeil or tIsFound) and  not ( isPillar or isRamp)   then allowDestroy = true --skip oters
                                    elseif tIsCeil and isPillar  and self.allowPillarLances then allowDestroy = true
--                if user:CanAdmin() then  rust.SendChatToUser(user, "t1") end
                                    elseif tIsPillar and not (isPillar ) --or isCeil
                                        then allowDestroy = true
--                if user:CanAdmin() then  rust.SendChatToUser(user, "t2") end
                                    elseif tIsPillar and isPillar and not (pos.z == tpos.z and pos.x == tpos.x)
                                        then allowDestroy = true
--                if user:CanAdmin() then  rust.SendChatToUser(user, "t3") end

                                     elseif tIsCeil  and isPillar then   --does conflict pillars got another basement ?
                                        allowDestroy = isManyBasements(connected,"Ceiling",tpos.y , pos)
--                    if user:CanAdmin() then  rust.SendChatToUser(user, "t4") end
                                    elseif  tIsFound and isPillar   then
                                        allowDestroy = isManyBasements(connected,"Foundation",tpos.y , pos)
--                    if user:CanAdmin() then  rust.SendChatToUser(user, "t5") end
                                    end
                                    if not allowDestroy then    return end

                                elseif pos.y == tpos.y and  not tIsCeil and  --same h check only 4 target=Pillar, + not for collided pillar
                                        ( tIsPillar and not string.find(v.name, "Pillar",1 ,true) ) then
--                    if user:CanAdmin() then rust.SendChatToUser( user, "-here: [" .. v.name .. "] r1="..tostring(tIsPillar and isCeil).."-"..tostring(self:radFromCoordinates(tpos,pos))) end
                                if tIsPillar and isCeil and not self:isPointInBl(tpos, pos, rad, radc) then    --plr not in corner?
                                    allowDestroy = true
                                elseif tIsPillar and v:IsWallType() then --lets deal with pillar in center. check i
                                    local aWorldWall = self:round(v:GetComponent("Transform").eulerAngles.y)
                                    if aWorldWall >= 180 then aWorldWall = aWorldWall - 180 end
                                    if aWorldWall >= 90 then aWorldWall = aWorldWall - 90 else aWorldWall = aWorldWall + 90 end

                                    local aPlrWall =self:round(math.deg( math.atan2( pos.x - tpos.x,pos.z - tpos.z)))
                                    if aPlrWall < 0 then aPlrWall = aPlrWall + 180 end
                                    allowDestroy = aWorldWall > aPlrWall + 1 or aWorldWall < aPlrWall  - 1
                    if user:CanAdmin() then  print("ownrem [info]: ".. v.name.."/"..tname ..":"..aPlrWall.."="..aWorldWall) end
                                end

                                if not allowDestroy then return end
                                end
                            end
                        end
                    end
                end
                if not self.nextHitNotes[creatorID .. item.name] then
                    self.nextHitNotes[creatorID .. item.name] = true
                    timer.Once(3, function() self.nextHitNotes[creatorID .. item.name] = nil end)
                    if self.econ and self.econIntegration and self.econ.ownremoveFee then
                        rust.Notice(user, "Hit one more time to remove this [" .. item.name .. "] (for "..self.econ:moneyStr(self.econ.ownremoveFee)..")" )
                    else rust.Notice(user, "Hit one more time to remove this [" .. item.name .. "]")  end
                    return
--                else self.nextHitNotes[creatorID .. item.name] = nil
                end
                if self.econ  and self.econIntegration and self.econ.ownremoveFee then -- and not user:CanAdmin()
                    if self.econ:getMoney(user) < self.econ.ownremoveFee then
                        rust.Notice(user, "You need ".. self.econ:moneyStr(self.econ.ownremoveFee) .." to remove this") return end
                    self.econ:takeMoneyFrom(user, self.econ.ownremoveFee)
                end

                if not self.giveResources and self.giveNewItem then
                    rust.GetInventory( user ):AddItemAmount( rust.GetDatablockByName(item.name),  1)
                elseif self.giveResources then
                    rust.GetInventory( user ):AddItemAmount( rust.GetDatablockByName(item.give), item.giveAmount)
                end
--                takedamage:SetGodMode(false)
                damage.amount = takedamage.health damage.status = LifeStatus.WasKilled
                if item.needRemove then  timer.NextFrame( function()  RemoveGObject(takedamage.gameObject) end)end
                return damage
            end
        end
    end
    end
end
function PLUGIN:isPointIn2DRadius(pos, point, rad)
    return self:radFromCoordinates({x=pos.x,y=1,z=pos.z},{x=point.x,y=1,z=point.z}) < rad
end
function PLUGIN:isPointInBl(pos, point, rad1, rad2)     --sq.R1 / sq.R2    =     r2(---r1(-------*
    return  self:isPointIn2DRadius(pos,point, rad2) and not self:isPointIn2DRadius(pos,point, rad1)
end


function PLUGIN:readFileToMap(filename, map)
    local file = util.GetDatafile(filename)
    local txt = file:GetText()
    if (txt ~= "") then
        print( filename.." loaded: " .. txt )
        return file, json.decode( txt )
    else
        print( filename.." not loaded: " .. txt )
        return file, {}
    end
end

function PLUGIN:SaveMapToFile(table, file)
    file:SetText( json.encode( table ) )  file:Save() end
function PLUGIN:initCfgParam(paramname, defaultVal)
    if (self.Cfg[paramname] ~= nil)
    then self[paramname] = self.Cfg[paramname]
    else self.Cfg[paramname] = defaultVal self[paramname] = defaultVal end end

function PLUGIN:round(val, decimal)
    if (decimal) then return math.floor( (val * 10^decimal) + 0.5) / (10^decimal)
    else  return math.floor(val+0.5) end end
function PLUGIN:radFromCoordinates(p1, p2)
    return math.sqrt(math.pow(p1.x - p2.x,2) + math.pow(p1.y - p2.y,2) + math.pow(p1.z - p2.z,2)) end
