-- While my mod has nothing to do with music, this approach allows it to be a 100% clientside mod

local Azimuth -- client includes
local resourceDisplay_initialize -- client, extended functions
local ResourceDisplayConfig -- client

if onClient() then


Azimuth = include("azimuthlib-basic")

resourceDisplay_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    resourceDisplay_initialize(...)

    -- load config
    local configOptions = {
      _version = { default = "1.0", comment = "Config version. Don't touch." },
      ShowCargoCapacity = { default = true, comment = "Show current ship cargo capacity" },
      ShowInventoryCapacity = { default = true, comment = "Show currently used and total inventory slots" },
      InventoryCapacityShowBothAlways = { default = false, comment = "Show both player and alliance inventory capacity no matter the ship" }
    }
    local isModified
    ResourceDisplayConfig, isModified = Azimuth.loadConfig("ResourceDisplay", configOptions)
    if isModified then
        Azimuth.saveConfig("ResourceDisplay", ResourceDisplayConfig, configOptions)
    end

    Player():registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
end

function MusicCoordinator.resourceDisplay_onPreRenderHud()
    local player = Player()
    local faction = player
    if player.craft and player.craft.allianceOwned then
        faction = Alliance()
    end
    if player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact then return end

    local alignBottom = tablelength(Galaxy():getPlayerNames()) > 1
    local margin = alignBottom and 17 or 18
    local y = 0
    local uiLines = {}
    if not faction.infiniteResources and player.state == PlayerStateType.Fly and not Hud().resourcesVisible then
        local resources = {faction:getResources()}
        for i = 1, #resources do
            local material = Material(i-1)
            y = y + margin
            if faction.isAlliance then
                uiLines[#uiLines+1] = { text = "[A]  /* Alliance resource prefix */"%_t..material.name, y = y, color = material.color }
            else
                uiLines[#uiLines+1] = { text = material.name, y = y, color = material.color }
            end
            uiLines[#uiLines+1] = { text = createMonetaryString(resources[i]), y = y, color = material.color, right = 1 }
        end
        y = y + margin
        local white = ColorRGB(1, 1, 1)
        if faction.isAlliance then
            uiLines[#uiLines+1] = { text = "[A]  /* Alliance resource prefix */"%_t.."Credits"%_t, y = y, color = white }
        else
            uiLines[#uiLines+1] = { text = "Credits"%_t, y = y, color = white }
        end
        uiLines[#uiLines+1] = { text = "¢"..createMonetaryString(faction.money), y = y, color = white, right = 1 }
    elseif not alignBottom and Hud().resourcesVisible then
        y = y + NumMaterials() * margin
    end
    -- inventory slots
    if ResourceDisplayConfig.ShowInventoryCapacity then
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways then
            faction = player
        end
        local inv = faction:getInventory()
        y = y + margin
        local color = ColorRGB(0.8, 0.8, 0.8)
        if faction.isAlliance then
            uiLines[#uiLines+1] = { text = "[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, y = y, color = color }
        else
            uiLines[#uiLines+1] = { text = "Inventory Slots"%_t, y = y, color = color }
        end
        uiLines[#uiLines+1] = { text = inv.occupiedSlots.."/"..inv.maxSlots, y = y, color = color, right = 1 }
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways and player.alliance then
            inv = player.alliance:getInventory()
            y = y + margin
            color = ColorRGB(0.8, 0.8, 0.8)
            uiLines[#uiLines+1] = { text = "[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, y = y, color = color }
            uiLines[#uiLines+1] = { text = inv.occupiedSlots.."/"..inv.maxSlots, y = y, color = color, right = 1 }
        end
    end
    -- cargo
    if ResourceDisplayConfig.ShowCargoCapacity then
        local ship = getPlayerCraft()
        y = y + margin
        local color = ColorRGB(0.8, 0.8, 0.8)
        uiLines[#uiLines+1] = { text = "Cargo Hold"%_t, y = y, color = color }
        if ship and ship.maxCargoSpace then
            uiLines[#uiLines+1] = { text = math.ceil(ship.occupiedCargoSpace).."/"..math.floor(ship.maxCargoSpace), y = y, color = color, right = 1 }
        else
            uiLines[#uiLines+1] = { text = "-", y = y, color = color, right = 1 }
        end
    end

    if alignBottom then
        y = getResolution().y - 492 - y
    else
        y = 10
    end
    for _, line in ipairs(uiLines) do
        drawTextRect(line.text, Rect(5, y + line.y, 295, y + line.y + 16), line.right or -1, -1, line.color, 15, 0, 0, 2)
    end
end


end