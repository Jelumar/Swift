
function X_MapIsReady()
    local Mode = "Production";
    if gvMission.DevelopmentMode then
        Mode = "Development";
    end
    API.StaticNote("Local script loaded! (" ..Mode..")");
end