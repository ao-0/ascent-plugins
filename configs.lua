if AscentPluginService and AscentPluginService.NewPlugin then
    local Plugin = AscentPluginService.NewPlugin()
    local Logic = Plugin.RequestAccess().AscentLogic
    
    local cfgdata = "new.ascfg"
    
    local function dump_logic()
        local String = "return {"
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
        local cfg = dump_logic()
        writefile('ascent-cfg/'..name, cfg)
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
        Configs.CreateButton('Save Config', '⚙', function(a)
            save_cfg(cfgdata)
            refreshcfgs()
            Logic.ConsoleNotify('Saved config', 1, Color3.fromRGB(72, 255, 0), true)
        end)
        Configs.CreateButton('Refresh', '🔄', function(a)
            refreshcfgs()
            Logic.ConsoleNotify('Refreshed configs', 1, Color3.fromRGB(72, 255, 0), true)
        end)
    end
    refreshcfgs()
end
