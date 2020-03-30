-- While my mod has nothing to do with music, this approach allows it to be a 100% clientside mod

local Azimuth -- client includes
local resourceDisplay_initialize -- client, extended functions
local ResourceDisplayConfig, resourceDisplay_hud -- client

if onClient() then


Azimuth = include("azimuthlib-basic")

resourceDisplay_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    resourceDisplay_initialize(...)

    -- load config
    local configOptions = {
      _version = { default = "1.1", comment = "Config version. Don't touch." },
      ShowCargoCapacity = { default = true, comment = "Show current ship cargo capacity" },
      ShowInventoryCapacity = { default = true, comment = "Show currently used and total inventory slots" },
      InventoryCapacityShowBothAlways = { default = false, comment = "Show both player and alliance inventory capacity no matter the ship" },
      UIPosition = { default = 10, comment = "Vertical position of UI"}
    }
    local isModified
    ResourceDisplayConfig, isModified = Azimuth.loadConfig("ResourceDisplay", configOptions)
    if isModified then
        Azimuth.saveConfig("ResourceDisplay", ResourceDisplayConfig, configOptions)
    end

    resourceDisplay_hud = Hud()
    Player():registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
end

function MusicCoordinator.resourceDisplay_onPreRenderHud()
    local player = Player()
    local faction = player
    if player.craft and player.craft.allianceOwned then
        faction = Alliance()
    end
    if player.state ~= PlayerStateType.Fly and player.state ~= PlayerStateType.Interact then return end

    local y = ResourceDisplayConfig.UIPosition
    if not faction.infiniteResources and player.state == PlayerStateType.Fly and not resourceDisplay_hud.resourcesVisible then
        local resources = {faction:getResources()}
        local rect
        for i = 1, #resources do
            local material = Material(i-1)
            y = y + 18
            rect = Rect(5, y, 295, y + 16)
            if faction.isAlliance then
                drawTextRect("[A]  /* Alliance resource prefix */"%_t..material.name, rect, -1, -1, material.color, 15, 0, 0, 2)
            else
                drawTextRect(material.name, rect, -1, -1, material.color, 15, 0, 0, 2)
            end
            drawTextRect(createMonetaryString(resources[i]), rect, 1, -1, material.color, 15, 0, 0, 2)
        end
        y = y + 18
        rect = Rect(5, y, 295, y + 16)
        local color = ColorRGB(1, 1, 1)
        if faction.isAlliance then
            drawTextRect("[A]  /* Alliance resource prefix */"%_t.."Credits"%_t, rect, -1, -1, color, 15, 0, 0, 2)
        else
            drawTextRect("Credits"%_t, rect, -1, -1, color, 15, 0, 0, 2)
        end
        drawTextRect("¢"..createMonetaryString(faction.money), rect, 1, -1, color, 15, 0, 0, 2)
    else
        if resourceDisplay_hud.resourcesVisible then
            y = y + NumMaterials() * 18
        end
    end
    -- inventory slots
    if ResourceDisplayConfig.ShowInventoryCapacity then
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways then
            faction = player
        end
        local inv = faction:getInventory()
        y = y + 18
        rect = Rect(5, y, 295, y + 16)
        color = ColorRGB(0.8, 0.8, 0.8)
        if faction.isAlliance then
            drawTextRect("[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, rect, -1, -1, color, 15, 0, 0, 2)
        else
            drawTextRect("Inventory Slots"%_t, rect, -1, -1, color, 15, 0, 0, 2)
        end
        drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, rect, 1, -1, color, 15, 0, 0, 2)
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways and player.alliance then
            inv = player.alliance:getInventory()
            y = y + 18
            rect = Rect(5, y, 295, y + 16)
            color = ColorRGB(0.8, 0.8, 0.8)
            drawTextRect("[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, rect, -1, -1, color, 15, 0, 0, 2)
            drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, rect, 1, -1, color, 15, 0, 0, 2)
        end
    end
    -- cargo
    if ResourceDisplayConfig.ShowCargoCapacity then
        local ship = getPlayerCraft()
        y = y + 18
        rect = Rect(5, y, 295, y + 16)
        color = ColorRGB(0.8, 0.8, 0.8)
        drawTextRect("Cargo Hold"%_t, rect, -1, -1, color, 15, 0, 0, 2)
        if ship and ship.maxCargoSpace then
            drawTextRect(math.ceil(ship.occupiedCargoSpace).."/"..math.floor(ship.maxCargoSpace), rect, 1, -1, color, 15, 0, 0, 2)
        else
            drawTextRect("-", rect, 1, -1, color, 15, 0, 0, 2)
        end
    end
end


end
