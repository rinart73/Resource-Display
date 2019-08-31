-- While my mod has nothing to do with music, this approach allows it to be a 100% clientside mod

local resourceDisplay_initialize -- extended functions
local resourceDisplay_gameVersion

if onClient() then


resourceDisplay_gameVersion = GameVersion()

resourceDisplay_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    resourceDisplay_initialize(...)

    if not GameSettings().infiniteResources then
        Player():registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
    end
end

function MusicCoordinator.resourceDisplay_onPreRenderHud()
    local player = Player()
    local faction = player.craft.allianceOwned and Alliance() or player
    local playerNotFlying = false
    if resourceDisplay_gameVersion.minor >= 26 then
        playerNotFlying = player.state ~= PlayerStateType.Fly
    end
    if faction.infiniteResources or playerNotFlying then return end

    local resources = {faction:getResources()}
    local y = 10
    local material, rect
    for i = 1, #resources do
        material = Material(i-1)
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
    drawTextRect(createMonetaryString(faction.money), rect, 1, -1, color, 15, 0, 0, 2)
end


end