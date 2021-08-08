-- While my mod has nothing to do with music, this approach allows it to be a client-side mod

Azimuth = include("azimuthlib-basic")
include("azimuthlib-uiproportionalsplitter")

local red_initialize, red_updateClient -- client, extended functions
local red_configOptions, red_config, red_rect, red_moveUI, red_dragged -- client


if onClient() then


red_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    red_initialize(...)

    -- load config
    red_configOptions = {
      _version = {"1.0", comment = "Config version. Don't touch."},
      ShowCargoCapacity = {true, comment = "Show current ship cargo capacity"},
      ShowInventoryCapacity = {true, comment = "Show currently used and total inventory slots"},
      InventoryCapacityShowBothAlways = {false, comment = "Show inventory capacity for alliance/ship at the same time"},
      PositionX = {5, comment = "UI X coordinate"},
      PositionY = {28, comment = "UI Y coordinate"},
      ShowAllianceResources = {true, comment = "Show alliance resources when piloting an alliance ship"}
    }
    local isModified
    red_config, isModified = Azimuth.loadConfig("ResourceDisplay", red_configOptions)
    if isModified then
        Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
    end

    red_rect = Rect(
      red_config.PositionX, red_config.PositionY,
      red_config.PositionX + 290, red_config.PositionY + 180
    )

    local tab = PlayerWindow():createTab("Resources Display"%_t, "data/textures/icons/metal-bar.png", "Resources Display"%_t)
    local lister = UIVerticalLister(Rect(tab.size), 10, 0)
    
    local split = UIVerticalProportionalSplitter(lister:placeRight(vec2(lister.inner.width, 25)), 10, 0, {0.5, 300})
    local checkBox = tab:createCheckBox(split[1], "Enable UI movement"%_t, "red_onToggleMovement")
    checkBox.captionLeft = false
    local btn = tab:createButton(split[2], "Reset UI position"%_t, "red_onResetPosition")
    
    local checkBox = tab:createCheckBox(lister:placeRight(vec2(lister.inner.width, 25)), "Show current ship cargo capacity"%_t, "red_onToggleCargo")
    checkBox.captionLeft = false
    checkBox:setCheckedNoCallback(red_config.ShowCargoCapacity)
    
    local checkBox = tab:createCheckBox(lister:placeRight(vec2(lister.inner.width, 25)), "Show currently used and total inventory slots"%_t, "red_onToggleInventory")
    checkBox.captionLeft = false
    checkBox:setCheckedNoCallback(red_config.ShowInventoryCapacity)
    
    local checkBox = tab:createCheckBox(lister:placeRight(vec2(lister.inner.width, 25)), "Show inventory capacity for alliance/ship at the same time"%_t, "red_onToggleInventoryBoth")
    checkBox.captionLeft = false
    checkBox:setCheckedNoCallback(red_config.InventoryCapacityShowBothAlways)
    
    local checkBox = tab:createCheckBox(lister:placeRight(vec2(lister.inner.width, 25)), "Show alliance resources when piloting an alliance ship"%_t, "red_onToggleAlliance")
    checkBox.captionLeft = false
    checkBox:setCheckedNoCallback(red_config.ShowAllianceResources)

    Player():registerCallback("onPreRenderHud", "red_onPreRenderHud")
end

function MusicCoordinator.getUpdateInterval()
    return red_moveUI and 0 or 1
end

red_updateClient = MusicCoordinator.updateClient
function MusicCoordinator.updateClient(...)
    if red_updateClient then red_updateClient(...) end

    local mouse, isMouseDown, saveNewPosition
    if red_moveUI then
        if Player().state == PlayerStateType.Fly then
            mouse = Mouse()
            isMouseDown = mouse:mouseDown(MouseButton.Left)
        elseif red_dragged then
            saveNewPosition = true
        end
    else
        saveNewPosition = true
    end
    if isMouseDown and not red_dragged then
        if mouse.position.x >= red_rect.lower.x and mouse.position.x <= red_rect.upper.x
          and mouse.position.y >= red_rect.lower.y and mouse.position.y <= red_rect.upper.y then
            red_dragged = {
              offsetX = mouse.position.x - red_rect.lower.x,
              offsetY = mouse.position.y - red_rect.lower.y
            }
        end
    end
    if red_dragged then
        local x = mouse.position.x - red_dragged.offsetX
        local y = mouse.position.y - red_dragged.offsetY
        red_rect = Rect(x, y, x + red_rect.width, y + red_rect.height)
        if mouse:mouseUp(MouseButton.Left) then
            saveNewPosition = true
        end
        if saveNewPosition then
            saveNewPosition = false
            red_config.PositionX = x
            red_config.PositionY = y
            red_dragged = nil
            Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
        end
    end
end

-- CALLBACKS

function MusicCoordinator.red_onToggleMovement(checkbox, value)
    red_moveUI = value
end

function MusicCoordinator.red_onPreRenderHud(state)
    if state ~= PlayerStateType.Fly and state ~= PlayerStateType.Interact then return end

    local player = Player()
    local faction = player
    local prefix = ""
    if player.craft and player.craft.allianceOwned then
        faction = Alliance()
        prefix = "[A]  /* Alliance resource prefix */"%_t
    end

    local x = red_rect.lower.x
    local x2 = red_rect.upper.x
    local y = red_rect.lower.y
    if not faction.infiniteResources then
        local matFaction = faction
        local matPrefix = prefix
        if not red_config.ShowAllianceResources then
            matFaction = player
            matPrefix = ""
        end
        for i, amount in ipairs({matFaction:getResources()}) do
            local material = Material(i-1)
            drawTextRect(matPrefix..material.name, Rect(x, y, x2, y + 16), -1, -1, material.color, 15, 0, 0, 2)
            drawTextRect(createMonetaryString(amount), Rect(x, y, x2, y + 16), 1, -1, material.color, 15, 0, 0, 2)
            y = y + 18
        end
        drawTextRect(matPrefix.."Credits"%_t, Rect(x, y, x2, y + 16), -1, -1, ColorRGB(1, 1, 1), 15, 0, 0, 2)
        drawTextRect("¢"..createMonetaryString(matFaction.money), Rect(x, y, x2, y + 16), 1, -1, ColorRGB(1, 1, 1), 15, 0, 0, 2)
        y = y + 18
    end
    -- inventory slots
    if red_config.ShowInventoryCapacity then
        local invFaction = faction
        local invPrefix = prefix
        if red_config.InventoryCapacityShowBothAlways then
            invFaction = player
            invPrefix = ""
        end
        local inv = invFaction:getInventory()
        local color = ColorRGB(0.8, 0.8, 0.8)
        drawTextRect(invPrefix.."Inventory Slots"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
        drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        y = y + 18
        if red_config.InventoryCapacityShowBothAlways and player.alliance then
            inv = player.alliance:getInventory()
            drawTextRect("[A]  /* Alliance resource prefix */"%_t.."Inventory Slots"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
            drawTextRect(inv.occupiedSlots.."/"..inv.maxSlots, Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
            y = y + 18
        end
    end
    -- cargo
    if red_config.ShowCargoCapacity then
        local ship = getPlayerCraft()
        local color = ColorRGB(0.8, 0.8, 0.8)
        drawTextRect("Cargo Hold"%_t, Rect(x, y, x2, y + 16), -1, -1, color, 15, 0, 0, 2)
        if ship and ship.maxCargoSpace then
            drawTextRect(math.ceil(ship.occupiedCargoSpace).."/"..math.floor(ship.maxCargoSpace), Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        else
            drawTextRect("-", Rect(x, y, x2, y + 16), 1, -1, color, 15, 0, 0, 2)
        end
    end

    if red_moveUI then
        drawRect(red_rect, ColorARGB(0.6, 0.4, 0.4, 0.4))
    end
end

function MusicCoordinator.red_onResetPosition()
    local x = red_configOptions.PositionX[1]
    local y = red_configOptions.PositionY[1]
    red_rect = Rect(x, y, x + red_rect.width, y + red_rect.height)
    red_config.PositionX = x
    red_config.PositionY = y
    Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
end

function MusicCoordinator.red_onToggleCargo(_, state)
    red_config.ShowCargoCapacity = state
    Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
end

function MusicCoordinator.red_onToggleInventory(_, state)
    red_config.ShowInventoryCapacity = state
    Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
end

function MusicCoordinator.red_onToggleInventoryBoth(_, state)
    red_config.InventoryCapacityShowBothAlways = state
    Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
end

function MusicCoordinator.red_onToggleAlliance(_, state)
    red_config.ShowAllianceResources = state
    Azimuth.saveConfig("ResourceDisplay", red_config, red_configOptions)
end

end