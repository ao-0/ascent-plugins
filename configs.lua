local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/,./"][\\-=_|]{}='

local function EncodeJit(data)
    return ((data:gsub('.', function(x) 
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end
local function DecodeJit(data)
    data = string.gsub(data, '[^'..b..'=]', '')
    return (data:gsub('.', function(x)
        if (x == '=') then return '' end
        local r,f='',(b:find(x)-1)
        for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
        return r;
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
        if (#x ~= 8) then return '' end
        local c=0
        for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
            return string.char(c)
    end))
end
if AscentPluginService and AscentPluginService.NewPlugin then
    local Plugin = AscentPluginService.NewPlugin()
    local Logic = Plugin.RequestAccess().AscentLogic
    
    local cfgdata = "new.ascfg"
    
    local function dump_logic(name)
        local String = "return {CFGName = '"..name.."';\n"
        for i,v in pairs(Logic) do
            if typeof(v) == 'table' then
                String =    String..'["'..i..'"] = {\n' -- table
                for i,v in pairs(v) do
                    if typeof(v) == 'table' then
                        String = String..'["'..i..'"] = {\n' -- section
                        for i,v in pairs(v) do
                            String = String..'["'..i..'"] = {' -- buttons
                            for i,v in pairs(v) do
                                if v._get then
                                    if typeof(v._get()) == 'Color3' then
                                        String = String..'["'..i..'"] = Color3.new('.. tostring(v._get()) ..');\n'
                                    elseif typeof(v._get()) == 'string' then
                                        String = String..'["'..i..'"] = "'.. tostring(v._get()) ..'";\n'
                                    else
                                        String = String..'["'..i..'"] = '.. tostring(v._get()) ..';\n'
                                    end
                                    
                                end
                            end
                            String = String..'};\n'
                        end
                        String = String..'};\n'
                    end
                end
                String = String..'};\n'
            end
        end
        String = String..'};\n'
        return String
    end
    local function IndexExists(table, index)
        return table[index]~=nil
    end
    local function match_table(table, table2)
        for i,v in pairs(table) do
            if typeof(v) == 'table' then
                if IndexExists(table2, i) then -- tabs
                    for a,b in pairs(v) do
                        if typeof(b) == 'table' then
                             -- section
                            for b,g in pairs(b) do
                                 -- buttons
                                for j,t in pairs(g) do
                                    if t._set then
                                        task.spawn(function()
                                            t._set(table2[i][a][b][j])
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    if not isfolder('ascent-cfg') then
        makefolder('ascent-cfg')
    end
    local function load_cfg(cfg)
        if not isfolder('ascent-cfg') then
            makefolder('ascent-cfg')
        end

        
        local _cfg = loadstring(readfile(cfg))()

        match_table(Logic, _cfg)
    end
    local function load_cfg_table(table)
        if not isfolder('ascent-cfg') then
            makefolder('ascent-cfg')
        end

        match_table(Logic, table)
    end
    local function get_configs()
        local res = {}
        for i,v in pairs(listfiles('ascent-cfg')) do
            print(i,v)
            table.insert(res, tostring(v))
        end
        return res
    end
    local function save_cfg(name)
        if not isfolder('ascent-cfg') then
            makefolder('ascent-cfg')
        end
        local cfg = dump_logic(name)
        if string.find(name, 'ascent-cfg') then
            writefile(name, cfg)
        else
            writefile('ascent-cfg/'..name, cfg)
        end
        return cfg
    end

    function refreshcfgs()
        if Tab then
            Tab:Destroy()
        end
        local Tab = Plugin.CreateContentSector('Configs');Logic['Configs'].OpenTab()
        local Configs = Tab.Section('Configurations', 'left');
        local cfgdata = get_configs()[1] or 'default'
        Configs.CreateDropdown('Config', (get_configs() or {}), cfgdata or '', function(a)
            cfgdata = a
        end)
        Configs.CreateButton('Load Config', '⚙', function(a)
            load_cfg(cfgdata)
            Logic.ConsoleNotify('Loading config', 1, Color3.fromRGB(72, 255, 0), true)
            
        end)
        Configs.CreateInput('CFG Name', 'Enter your configs name', function(a)
            cfgdata = a
        end)
        Configs.CreateInput('Import', '', function(a)
            local DATA = DecodeJit(a)
            local ConfigData = loadstring(DATA)()
            local ConfigName = ConfigData.CFGName;
            if string.find(ConfigName, 'ascent-cfg') then
                writefile(ConfigName, DATA)
            else
                writefile('ascent-cfg/'..ConfigName, DATA)
            end
            
            refreshcfgs()
            Logic.ConsoleNotify('Imported config', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        Configs.CreateButton('Export', '⚙', function(a)
            
            setclipboard(EncodeJit(readfile(cfgdata)))
            Logic.ConsoleNotify('Exported config', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        
        Configs.CreateButton('Save Config', '⚙', function(a)
            save_cfg(cfgdata)
            refreshcfgs()
            Logic.ConsoleNotify('Saved config', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        Configs.CreateButton('Delete Config', '⚙', function(a)
            delfile(cfgdata)
            refreshcfgs()
            Logic.ConsoleNotify('Deleted config', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        Configs.CreateButton('Delete All Configs', '⚙', function(a)
            delfolder('ascent-cfg')
            makefolder('ascent-cfg')
            save_cfg('Default')
            refreshcfgs()
            Logic.ConsoleNotify('Deleted all configs', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        Configs.CreateButton('Refresh', '🔄', function(a)
            refreshcfgs()
            Logic.ConsoleNotify('Refreshed configs', 1, Color3.fromRGB(72, 255, 0), true)
        end)
    end
    refreshcfgs()
end
