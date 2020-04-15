-- While my mod has nothing to do with music, this approach allows it to be a clientside mod

local Azimuth -- client includes
local resourceDisplay_initialize, resourceDisplay_updateClient -- client, extended functions
local ResourceDisplayConfigOptions, ResourceDisplayConfig, resourceDisplay_rect, resourceDisplay_moveUI, resourceDisplay_dragged -- client

if onClient() then


Azimuth = include("azimuthlib-basic")

resourceDisplay_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    resourceDisplay_initialize(...)

    -- load config
    ResourceDisplayConfigOptions = {
      _version = { default = "1.0", comment = "Config version. Don't touch." },
      ShowCargoCapacity = { default = true, comment = "Show current ship cargo capacity" },
      ShowInventoryCapacity = { default = true, comment = "Show currently used and total inventory slots" },
      InventoryCapacityShowBothAlways = { default = false, comment = "Show both player and alliance inventory capacity no matter the ship" },
      PositionX = { default = 5, comment = "UI X coordinate" },
      PositionY = { default = 28, comment = "UI Y coordinate" }
    }
    local isModified
    ResourceDisplayConfig, isModified = Azimuth.loadConfig("ResourceDisplay", ResourceDisplayConfigOptions)
    if isModified then
        Azimuth.saveConfig("ResourceDisplay", ResourceDisplayConfig, ResourceDisplayConfigOptions)
    end

    resourceDisplay_rect = Rect(
      ResourceDisplayConfig.PositionX, ResourceDisplayConfig.PositionY,
      ResourceDisplayConfig.PositionX + 290, ResourceDisplayConfig.PositionY + 180
    )

    local tab = PlayerWindow():createTab("Resources Display"%_t, "data/textures/icons/metal-bar.png", "Resources Display"%_t)
    local lister = UIVerticalLister(Rect(tab.size), 10, 0)
    local checkBox = tab:createCheckBox(lister:placeRight(vec2(lister.inner.width, 25)), "Enable UI movement"%_t, "resourceDisplay_onToggleMovement")
    checkBox.captionLeft = false

    Player():registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
end

function MusicCoordinator.getUpdateInterval()
    return resourceDisplay_moveUI and 0 or 1
end

resourceDisplay_updateClient = MusicCoordinator.updateClient
function MusicCoordinator.updateClient(...)
    if resourceDisplay_updateClient then resourceDisplay_updateClient(...) end

    local mouse, isMouseDown, saveNewPosition
    if resourceDisplay_moveUI then
        if Player().state == PlayerStateType.Fly then
            mouse = Mouse()
            isMouseDown = mouse:mouseDown(MouseButton.Left)
        elseif resourceDisplay_dragged then
            saveNewPosition = true
        end
    else
        saveNewPosition = true
    end
    if isMouseDown and not resourceDisplay_dragged then
        if mouse.position.x >= resourceDisplay_rect.lower.x and mouse.position.x <= resourceDisplay_rect.upper.x
          and mouse.position.y >= resourceDisplay_rect.lower.y and mouse.position.y <= resourceDisplay_rect.upper.y then
            resourceDisplay_dragged = {
              offsetX = mouse.position.x - resourceDisplay_rect.lower.x,
              offsetY = mouse.position.y - resourceDisplay_rect.lower.y
            }
        end
    end
    if resourceDisplay_dragged then
        local x = mouse.position.x - resourceDisplay_dragged.offsetX
        local y = mouse.position.y - resourceDisplay_dragged.offsetY
        resourceDisplay_rect = Rect(x, y, x + resourceDisplay_rect.width, y + resourceDisplay_rect.height)
        if mouse:mouseUp(MouseButton.Left) then
            saveNewPosition = true
        end
        if saveNewPosition then
            saveNewPosition = false
            ResourceDisplayConfig.PositionX = x
            ResourceDisplayConfig.PositionY = y
            resourceDisplay_dragged = nil
            Azimuth.saveConfig("ResourceDisplay", ResourceDisplayConfig, ResourceDisplayConfigOptions)
        end
    end
end

function MusicCoordinator.resourceDisplay_onToggleMovement(checkbox, value)
    resourceDisplay_moveUI = value
end

function MusicCoordinator.resourceDisplay_onPreRenderHud(state)
    if state ~= PlayerStateType.Fly and state ~= PlayerStateType.Interact then return end

    local player = Player()
    local faction = player
    local prefix = ""
    if player.craft and player.craft.allianceOwned then
        faction = Alliance()
        prefix = "[A]  /* Alliance resource prefix */"%_t
    end

    local x = resourceDisplay_rect.lower.x
    local x2 = resourceDisplay_rect.upper.x
    local y = resourceDisplay_rect.lower.y
    if not faction.infiniteResources then
        for i, amount in ipairs({faction:getResources()}) do
            local material = Material(i-1)
            drawTextRect(prefix..material.name, Rect(x, y, x2, y + 16), -1, -1, material.color, 15, 0, 0, 2)
            drawTextRect(createMonetaryString(amount), Rect(x, y, x2, y + 16), 1, -1, material.color, 15, 0, 0, 2)
            y = y + 18
        end
        drawTextRect(prefix.."Credits"%_t, Rect(x, y, x2, y + 16), -1, -1, ColorRGB(1, 1, 1), 15, 0, 0, 2)
        drawTextRect("¢"..createMonetaryString(faction.money), Rect(x, y, x2, y + 16), 1, -1, ColorRGB(1, 1, 1), 15, 0, 0, 2)
        y = y + 18
    end
    -- inventory slots
    if ResourceDisplayConfig.ShowInventoryCapacity then
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways then
            faction = player
        end
        local inv = faction:getInventory()
        local color = ColorRGB(0.8, 0.8, 0.8)
        drawTextRect("Inventory Slots"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
        drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        y = y + 18
        if ResourceDisplayConfig.InventoryCapacityShowBothAlways and player.alliance then
            inv = player.alliance:getInventory()
            drawTextRect("[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
            drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
            y = y + 18
        end
    end
    -- cargo
    if ResourceDisplayConfig.ShowCargoCapacity then
        local ship = getPlayerCraft()
        local color = ColorRGB(0.8, 0.8, 0.8)
        drawTextRect("Cargo Hold"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
        if ship and ship.maxCargoSpace then
            drawTextRect(math.ceil(ship.occupiedCargoSpace).."/"..math.floor(ship.maxCargoSpace), Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        else
            drawTextRect("-", Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        end
    end

    if resourceDisplay_moveUI then
        drawRect(resourceDisplay_rect, ColorARGB(0.6, 0.4, 0.4, 0.4))
    end
end


end