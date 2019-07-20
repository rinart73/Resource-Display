-- While my mod has nothing to do with music, this approach allows it to be a 100% clientside mod
if onClient() then

local resourceDisplay_initialize = MusicCoordinator.initialize
function MusicCoordinator.initialize(...)
    resourceDisplay_initialize(...)

    if not GameSettings().infiniteResources then
        Player():registerCallback("onPreRenderHud", "resourceDisplay_onPreRenderHud")
    end
end

function MusicCoordinator.resourceDisplay_onPreRenderHud()
    local player = Player()
    if player.infiniteResources then return end

    local resources = {player:getResources()}
    local y = 10
    local material, rect
    for i = 1, #resources do
        material = Material(i-1)
        y = y + 18
        rect = Rect(5, y, 295, y + 16)
        drawTextRect(material.name, rect, -1, -1, material.color, 15, 0, 0, 2)
        drawTextRect(createMonetaryString(resources[i]), rect, 1, -1, material.color, 15, 0, 0, 2)
    end
    y = y + 18
    rect = Rect(5, y, 295, y + 16)
    local color = ColorRGB(1, 1, 1)
    drawTextRect("Credits"%_t, rect, -1, -1, color, 15, 0, 0, 2)
    drawTextRect(createMonetaryString(player.money), rect, 1, -1, color, 15, 0, 0, 2)
end

end