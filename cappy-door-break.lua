-- name: Cappy Door Break  
-- description: Allow Cappy to break doors made by Retired64 (Optimized Version)  
  
-- Constantes configurables  
local CONSTANTS = {  
    DOOR_BREAK_DISTANCE = 300,  
    DOOR_HIDE_HEIGHT = 9999,  
    DOOR_RESPAWN_TIME = 339,  
    BROKEN_DOOR_LIFETIME = 300,  
    DOOR_VELOCITY = 80,  
    PARTICLE_COUNT = 30,  
    PARTICLE_COLOR = 138,  
    DOOR_CHECK_INTERVAL = 5,  
    DOOR_DETECTION_RANGE = 500,  
    FIRE_FLAME_COUNT = 5,      -- Número de llamas al romper  
    FIRE_FLAME_SCALE = 2.0,    -- Tamaño de las llamas  
    FIRE_SPAWN_HEIGHT = 50     -- Altura donde aparece el humo  
}
  
-- Mapeo de modelos de puertas  
local DOOR_MODELS = {  
    [E_MODEL_CASTLE_DOOR_1_STAR] = E_MODEL_CASTLE_DOOR_1_STAR,  
    [E_MODEL_CASTLE_DOOR_3_STARS] = E_MODEL_CASTLE_DOOR_3_STARS,  
    [E_MODEL_CCM_CABIN_DOOR] = E_MODEL_CCM_CABIN_DOOR,  
    [E_MODEL_HMC_METAL_DOOR] = E_MODEL_HMC_METAL_DOOR,  
    [E_MODEL_HMC_WOODEN_DOOR] = E_MODEL_HMC_WOODEN_DOOR,  
    [E_MODEL_BBH_HAUNTED_DOOR] = E_MODEL_BBH_HAUNTED_DOOR,  
    [E_MODEL_CASTLE_METAL_DOOR] = E_MODEL_CASTLE_METAL_DOOR,  
    [E_MODEL_CASTLE_CASTLE_DOOR] = E_MODEL_CASTLE_CASTLE_DOOR,  
    [E_MODEL_HMC_HAZY_MAZE_DOOR] = E_MODEL_HMC_HAZY_MAZE_DOOR,  
    [E_MODEL_CASTLE_GROUNDS_METAL_DOOR] = E_MODEL_CASTLE_GROUNDS_METAL_DOOR,  
    [E_MODEL_CASTLE_KEY_DOOR] = E_MODEL_CASTLE_KEY_DOOR  
}  
  
-- Variables para caché  
local lastDoorCheck = 0  
local cachedDoor = nil  
  
-- Funciones auxiliares optimizadas  
local function active_player(m)  
    if not m or not gNetworkPlayers[m.playerIndex] then return false end  
    local np = gNetworkPlayers[m.playerIndex]  
    if m.playerIndex == 0 then return true end  
    if not np.connected then return false end  
    if np.currCourseNum ~= gNetworkPlayers[0].currCourseNum then return false end  
    if np.currActNum ~= gNetworkPlayers[0].currActNum then return false end  
    if np.currLevelNum ~= gNetworkPlayers[0].currLevelNum then return false end  
    if np.currAreaIndex ~= gNetworkPlayers[0].currAreaIndex then return false end  
    return is_player_active(m)  
end  
  
local function if_then_else(cond, ifTrue, ifFalse)  
    if cond then return ifTrue end  
    return ifFalse  
end  
  
local function s16(num)  
    num = math.floor(num) & 0xFFFF  
    if num >= 32768 then return num - 65536 end  
    return num  
end  
  
local function should_push_or_pull_door(m, o)  
    if not m or not o then return 0x00000001 end  
    local dx = o.oPosX - m.pos.x  
    local dz = o.oPosZ - m.pos.z  
    local dYaw = s16(o.oMoveAngleYaw - atan2s(dz, dx))  
    return if_then_else(dYaw >= -0x4000 and dYaw <= 0x4000, 0x00000001, 0x00000002)  
end  
  
local function get_door_model(door)  
    if not door then return E_MODEL_CASTLE_CASTLE_DOOR end  
      
    if get_id_from_behavior(door.behavior) == id_bhvStarDoor then  
        return E_MODEL_CASTLE_STAR_DOOR_8_STARS  
    end  
      
    for model, result in pairs(DOOR_MODELS) do  
        if obj_has_model_extended(door, model) ~= 0 then  
            return result  
        end  
    end  
      
    return E_MODEL_CASTLE_CASTLE_DOOR  
end  
  
local function find_nearest_door(cappy)  
    if not cappy then return nil end  
      
    local doors = {}  
      
    -- Buscar todas las puertas dentro del rango de detección  
    for _, doorType in ipairs({id_bhvDoor, id_bhvStarDoor, id_bhvDoorWarp}) do  
        local door = obj_get_first_with_behavior_id(doorType)  
        while door ~= nil do  
            local dist = dist_between_objects(cappy, door)  
            if dist < CONSTANTS.DOOR_DETECTION_RANGE then  
                table.insert(doors, {obj = door, dist = dist})  
            end  
            door = obj_get_next_with_same_behavior_id(door)  
        end  
    end  
      
    -- Encontrar la más cercana  
    local nearest = nil  
    local minDist = math.huge  
      
    for _, doorInfo in ipairs(doors) do  
        if doorInfo.dist < minDist then  
            minDist = doorInfo.dist  
            nearest = doorInfo.obj  
        end  
    end  
      
    return nearest  
end  
  
-- Comportamiento de puerta rota (optimizado)  
-- Comportamiento de puerta rota sin daño  
local function bhv_broken_door_init(o)  
    if not o then return end  
    o.oFlags = OBJ_FLAG_UPDATE_GFX_POS_AND_ANGLE  
    o.oInteractType = 0  -- Sin interacción de daño  
    o.oIntangibleTimer = 0  
    o.oGraphYOffset = -5  
    o.oDamageOrCoinValue = 0  -- Sin daño  
    obj_scale(o, 0.85)  
    o.hitboxRadius = 80  
    o.hitboxHeight = 100  
    o.oGravity = 3  
    o.oFriction = 0.8  
    o.oBuoyancy = 1  
    o.oVelY = 50  
    -- Apariencia quemada  
    o.oOpacity = 200  
end
  
local function bhv_broken_door_loop(o)  
    if not o then return end  
    if o.oForwardVel > 10 then  
        object_step()  
        if o.oForwardVel < 30 then  
            o.oInteractType = 0  
        end  
    else  
        cur_obj_update_floor()  
        o.oFaceAnglePitch = approach_s32(o.oFaceAnglePitch, -0x4000, 0x500, 0x500)  
    end  
    obj_flicker_and_disappear(o, CONSTANTS.BROKEN_DOOR_LIFETIME)  
end  
  
local id_bhvBrokenDoor = hook_behavior(nil, OBJ_LIST_GENACTOR, true, bhv_broken_door_init, bhv_broken_door_loop)  
  
-- Función principal de romper puerta (con validaciones)  
local function break_door(m, targetDoor)  
    if not m or not targetDoor then return end  
      
    local model = get_door_model(targetDoor)  
      
    targetDoor.oTimer = 0  
    targetDoor.oPosY = CONSTANTS.DOOR_HIDE_HEIGHT  
      
    -- Sonido de quemado sin daño  
    play_sound(SOUND_MOVING_LAVA_BURN, targetDoor.header.gfx.cameraToObject)  
    network_send_object(targetDoor, false)  
      
    -- Spawnear humo negro para efecto de puerta quemada  
    for i = 0, 6 do  
        spawn_non_sync_object(  
            id_bhvBlackSmokeMario,  
            E_MODEL_NONE,  
            targetDoor.oPosX + (i - 3) * 40,   
            targetDoor.oHomeY + 30,   
            targetDoor.oPosZ + (i % 2 - 0.5) * 40,  
            function(smoke)  
                smoke.oForwardVel = 10 + math.random(5)  
                smoke.oVelY = 25 + math.random(15)  
                smoke.oOpacity = 180  
            end  
        )  
    end  
      
    -- Humo adicional que sube  
    spawn_non_sync_object(  
        id_bhvBlackSmokeUpward,  
        E_MODEL_NONE,  
        targetDoor.oPosX, targetDoor.oHomeY + 60, targetDoor.oPosZ,  
        function(smoke)  
            smoke.oVelY = 40  
            smoke.oOpacity = 200  
        end  
    )  
  
    -- Puerta rota sin daño  
    spawn_non_sync_object(  
        id_bhvBrokenDoor,  
        model,  
        targetDoor.oPosX, targetDoor.oHomeY, targetDoor.oPosZ,  
        function(o)  
            if not o then return end  
            o.globalPlayerIndex = gNetworkPlayers[m.playerIndex].globalIndex  
            o.oForwardVel = CONSTANTS.DOOR_VELOCITY  
            -- Sin partículas de fuego ni daño  
            play_sound(SOUND_MOVING_LAVA_BURN, targetDoor.header.gfx.cameraToObject)  
        end  
    )  
  
    if get_id_from_behavior(targetDoor.behavior) == id_bhvDoorWarp then  
        m.interactObj = targetDoor  
        m.usedObj = targetDoor  
        m.actionArg = should_push_or_pull_door(m, targetDoor)  
        level_trigger_warp(m, WARP_OP_WARP_DOOR)  
    end  
end  
  
-- Hook principal optimizado con caché  
hook_event(HOOK_UPDATE, function()  
    if not _G.OmmEnabled then return end  
      
    local m = gMarioStates[0]  
    if not active_player(m) then return end  
  
    local cappy = obj_get_first_with_behavior_id_and_field_s32(  
        bhvOmmCappy, 0x31, network_global_index_from_local(0) + 1)  
      
    if not cappy then return end  
  
    -- Sistema de caché para mejorar rendimiento  
    if get_global_timer() - lastDoorCheck > CONSTANTS.DOOR_CHECK_INTERVAL then  
        cachedDoor = find_nearest_door(cappy)  
        lastDoorCheck = get_global_timer()  
    end  
  
    if cachedDoor and cappy.oSubAction ~= 0 and   
       dist_between_objects(cappy, cachedDoor) < CONSTANTS.DOOR_BREAK_DISTANCE then  
        break_door(m, cachedDoor)  
        cachedDoor = nil -- Limpiar caché después de usar  
    end  
end)  
  
-- Hook de respawn mejorado para multijugador  
hook_event(HOOK_MARIO_UPDATE, function(m)  
    if not is_player_active(m) then return end  
      
    local door = obj_get_first(OBJ_LIST_SURFACE)  
    while door ~= nil do  
        local id = get_id_from_behavior(door.behavior)  
          
        if (id == id_bhvDoor or id == id_bhvStarDoor or id == id_bhvDoorWarp)   
           and door.oPosY == CONSTANTS.DOOR_HIDE_HEIGHT then  
              
            if door.oTimer >= CONSTANTS.DOOR_RESPAWN_TIME then  
                door.oPosY = door.oHomeY  
                network_send_object(door, true) -- Sincronizar con todos los jugadores  
            end  
        end  
        door = obj_get_next(door)  
    end  
end)  
  
-- Hook de interacción (sin cambios funcionales)  
hook_event(HOOK_ALLOW_INTERACT, function(m, obj, interactType, allow)  
    if get_id_from_behavior(obj.behavior) == id_bhvBrokenDoor and   
       gNetworkPlayers[m.playerIndex].globalIndex == obj.globalPlayerIndex then  
        return false  
    end  
    return true  
end)