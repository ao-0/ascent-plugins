-- server hop not mine
local AllIDs = {}
local foundAnything = ""
local actualHour = os.date("!*t").hour
local Deleted = false
local S_T = game:GetService("TeleportService")
local S_H = game:GetService("HttpService")

local File = pcall(function()
	AllIDs = S_H:JSONDecode(readfile("server-hop-temp.json"))
end)
if not File then
	table.insert(AllIDs, actualHour)
	pcall(function()
		writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
	end)

end
local function TPReturnerHighest(placeId)
	local Site;
	if foundAnything == "" then
		Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Desc&limit=100'))
	else
		Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Desc&limit=100&cursor=' .. foundAnything))
	end
	local ID = ""
	if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
		foundAnything = Site.nextPageCursor
	end
	local num = 0;
	for i,v in pairs(Site.data) do
		local Possible = true
		ID = tostring(v.id)
		if tonumber(v.maxPlayers) > tonumber(v.playing) then
			for _,Existing in pairs(AllIDs) do
				if num ~= 0 then
					if ID == tostring(Existing) then
						Possible = false
					end
				else
					if tonumber(actualHour) ~= tonumber(Existing) then
						local delFile = pcall(function()
							delfile("server-hop-temp.json")
							AllIDs = {}
							table.insert(AllIDs, actualHour)
						end)
					end
				end
				num = num + 1
			end
			if Possible == true then
				table.insert(AllIDs, ID)
				wait()
				pcall(function()
					writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
					wait()
					S_T:TeleportToPlaceInstance(placeId, ID, game.Players.LocalPlayer)
				end)
				wait(4)
			end
		end
	end
end
local function TPReturnerLowest(placeId)
	local Site;
	if foundAnything == "" then
		Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100'))
	else
		Site = S_H:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. placeId .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
	end
	local ID = ""
	if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
		foundAnything = Site.nextPageCursor
	end
	local num = 0;
	for i,v in pairs(Site.data) do
		local Possible = true
		ID = tostring(v.id)
		if tonumber(v.maxPlayers) > tonumber(v.playing) then
			for _,Existing in pairs(AllIDs) do
				if num ~= 0 then
					if ID == tostring(Existing) then
						Possible = false
					end
				else
					if tonumber(actualHour) ~= tonumber(Existing) then
						local delFile = pcall(function()
							delfile("server-hop-temp.json")
							AllIDs = {}
							table.insert(AllIDs, actualHour)
						end)
					end
				end
				num = num + 1
			end
			if Possible == true then
				table.insert(AllIDs, ID)
				wait()
				pcall(function()
					writefile("server-hop-temp.json", S_H:JSONEncode(AllIDs))
					wait()
					S_T:TeleportToPlaceInstance(placeId, ID, game.Players.LocalPlayer)
				end)
				wait(4)
			end
		end
	end
end
function TeleportHighest(placeId)
	while wait() do
		pcall(function()
			TPReturnerHighest(placeId)
			if foundAnything ~= "" then
				TPReturnerHighest(placeId)
			end
		end)
	end
end
function TeleportLowest(placeId)
	while wait() do
		pcall(function()
			TPReturnerLowest(placeId)
			if foundAnything ~= "" then
				TPReturnerLowest(placeId)
			end
		end)
	end
end

local Players = game:GetService("Players")
local GroupId = 8068202
local AntiModEnabled = true
local HopMode = "Highest people"
for i,Player in pairs(game.Players:GetPlayers()) do
    if(Player:IsInGroup(GroupId)) then
        Logic.ConsoleNotify('FOUND MOD! REJOINING!!', 5, Color3.fromRGB(255,0,0))
        RighteousTP()
    end
end
function RighteousTP()
    if HopMode == "Highest people" then
        TeleportHighest(game.PlaceId)
    else
        TeleportLowest(game.PlaceId)
    end
end
Players.PlayerAdded:Connect(function(Player)
	if(Player:IsInGroup(GroupId)) and AntiModEnabled then
        RighteousTP()
	end
end)

if AscentPluginService and AscentPluginService.NewPlugin then
    local Plugin = AscentPluginService.NewPlugin()
    local Tab = Plugin.CreateContentSector('Anti Mod');
    local Logic = Plugin.RequestAccess().AscentLogic
    local AntiModSec = Tab.Section('Anti Mod', 'left');
    AntiModSec.CreateToggle('Enabled', true, function(a)
        AntiModEnabled = a
        if a then
            for i,Player in pairs(game.Players:GetPlayers()) do
                if(Player:IsInGroup(GroupId)) then
                    Logic.ConsoleNotify('FOUND MOD! REJOINING!!', 5, Color3.fromRGB(255,0,0))
                    RighteousTP()
                end
            end
        end
    end)
    AntiModSec.CreateButton('Server Hop', '🔄', function(a)
        Logic.ConsoleNotify('HOPPING SERVER!!', 5, Color3.fromRGB(255,0,0))
        RighteousTP()
    end)
    AntiModSec.CreateDropdown('Hop mode', {'Highest people', 'Lowest People'}, 'Highest people', function(a)
        HopMode = a
    end)
end
