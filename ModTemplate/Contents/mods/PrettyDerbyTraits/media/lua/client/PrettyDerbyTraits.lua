----------------------------------------------------------------------------------------------------
--
-- 目前赛马娘特质有如下特点
--
-- 个人负重大幅提高，耐力越少恢复越快
-- 使用近战武器的时候伤害和暴击大幅提高,必定击退，同时受饥饿加成，吃的越饱伤害越高,但是也更容易造成武器损坏
-- 踩踏伤害巨幅提高，同样受饥饿值加成
-- 慢跑和冲刺速度大幅提高，但是耐力消耗更高，受饥饿值加成
-- 食欲旺盛，受饥饿值加成
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
local hungryLevel = 4;
local enduranceLevel = 4;

-- 增加负重
function bearLoad()
    local player = getPlayer();
    if player:HasTrait("PrettyDerbyTraits") then
        local muleMaxWeightbonus = math.floor(20 + player:getPerkLevel(Perks.Strength) * 2);
        player:setMaxWeightBase(muleMaxWeightbonus);
    end
end

-- 使用近战武器的时候伤害大幅提高，但是也更容易造成武器损坏
function meleePower(_actor, _target, _weapon, _damage)
    local player = getPlayer();
    local weapon = _weapon;
    local weapondata = weapon:getModData();
    local damage = _damage * SandboxVars.PrettyDerby_damage * (hungryLevel - 1);
    print("damage:   ", damage)
    print("_damage:   ", _damage)
    print("SandboxVars.PrettyDerby_damage:   ", SandboxVars.PrettyDerby_damage)
    print("hungryLevel:   ", hungryLevel)
    print("weapon:getSubCategory():   ", weapon:getSubCategory())

    if _actor == player and player:HasTrait("PrettyDerbyTraits") and weapon:getSubCategory() ~= "Firearm" then
        
        -- 致命一击概率触发
        if _target:isZombie() then
            _target:setKnockedDown(true);
            _target:setStaggerBack(true);
            _target:setHitReaction("");
            _target:setPlayerAttackPosition("FRONT");
            _target:setHitForce(2.0);
            _target:reportEvent("wasHit");
        end
        print("weapon.iLastWeaponCond:   ", weapondata.iLastWeaponCond)
        print("weapon.getCondition():   ", weapon:getCondition())
        print("weapon.getConditionMax():   ", weapon:getConditionMax())

        _target:setHealth(_target:getHealth() - damage * 0.1);
        if _target:getHealth() <= 0 and _target:isAlive() then
            _target:update();
        end
        if weapondata.iLastWeaponCond == nil then
            weapondata.iLastWeaponCond = weapon:getCondition();
        end
        if weapondata.iLastWeaponCond > weapon:getCondition() and ZombRand(0, 101) <= 33 then
            weapon:setCondition(weapon:getCondition() - 0.5 * SandboxVars.PrettyDerby_breakage);
        end
    end
end

-- 战争践踏
function LeadFoot(_player)
    local player = getPlayer();
    local shoes = player:getClothingItem_Feet();
    local itemdata = nil;
    if shoes ~= nil then
        itemdata = shoes:getModData();
        local origstomp = itemdata.origStomp;
        if origstomp == nil then
            origstomp = shoes:getStompPower();
            itemdata.origStomp = origstomp;
            itemdata.stompState = "Normal";
        end
        if player:HasTrait("leadfoot") then
            if itemdata.stompState ~= "LeadFoot" then
                local newstomp = origstomp * 2 * hungryLevel + 1;
                shoes:setStompPower(newstomp);
                itemdata.stompState = "LeadFoot";
            end
        else
            if shoes:getStompPower() ~= origstomp then
                shoes:setStompPower(origstomp);
                itemdata.stompState = "Normal";
            end
        end
    end
end

-- 移动速度
function moveSpeed()
    local player = getPlayer()

    if player:HasTrait("PrettyDerbyTraits") then
        -- print("content:   ",1.1 + hungryLevel )
        getPlayer():setVariable("runspeed_sprint", 1.1 + hungryLevel * 0.1)
        getPlayer():setVariable("runspeed_run", 1.1 + hungryLevel * 0.1)
    else
        getPlayer():setVariable("runspeed_sprint", 1.1)
        getPlayer():setVariable("runspeed_run", 1.1)
    end
end

-- 饥饿、卡路里、耐力恢复
function consume()
    local player = getPlayer()

    local hungerItem = tonumber(SandboxVars.PrettyDerby_hunger) - 1;
    local enduranceSandbox = tonumber(SandboxVars.PrettyDerby_endurance);
    local enduranceItem = (enduranceSandbox > 2 and {enduranceSandbox * 2} or {enduranceSandbox - 1})[1];

    -- local enduranceStats = player:getStats():getEndurance()
    -- local hungerStats = player:getStats():getHunger()
    -- print("hungryLevel: ", hungryLevel, " enduranceLevel: ", enduranceLevel, " hungerStats: ",hungerStats)
    if player:HasTrait("PrettyDerbyTraits") then
        player:getStats():setEndurance(player:getStats():getEndurance() + 0.0005 * enduranceLevel * hungryLevel *
                                           enduranceItem)
        player:getStats():setHunger(player:getStats():getHunger() + 0.00025 * hungryLevel * hungerItem);
        player:getNutrition():setCalories(player:getNutrition():getCalories() - 0.5 * hungryLevel * hungerItem)
    end
end

function updateLevel()
    local player = getPlayer()
    local enduranceStats = player:getStats():getEndurance()
    local hungerStats = player:getStats():getHunger()

    if enduranceStats > 0.85 then
        enduranceLevel = 1;
    elseif enduranceStats <= 0.85 and enduranceStats > 0.6 then
        enduranceLevel = 2;
    elseif enduranceStats <= 0.6 and enduranceStats > 0.6 then
        enduranceLevel = 3;
    else
        enduranceLevel = 4;
    end
    if hungerStats < 0.15 then
        hungryLevel = 4;
    elseif hungerStats >= 0.15 and hungerStats < 0.25 then
        hungryLevel = 3;
    elseif hungerStats >= 0.25 and hungerStats < 0.45 then
        hungryLevel = 2;
    elseif hungerStats >= 0.45 and hungerStats < 0.7 then
        hungryLevel = 1;
    else
        hungryLevel = 0;
    end

end

function OnCreatePlayer(_player)
    moveSpeed()
end

function EveryOneMinute(_player)
    updateLevel();
    bearLoad();
    LeadFoot();
    consume();
    moveSpeed()
end

-- 移速消耗
function OnPlayerMove()
    local player = getPlayer()

    if player:HasTrait("PrettyDerbyTraits") then
        if player:isSprinting() then
            player:getStats():setEndurance(player:getStats():getEndurance() - 0.000016 / hungryLevel);
        elseif player:IsRunning() then
            player:getStats():setEndurance(player:getStats():getEndurance() - 0.000016 / hungryLevel);
        end

    end

end

function MainPlayerUpdate(_player)

end

Events.OnPlayerMove.Add(OnPlayerMove)
Events.OnWeaponHitCharacter.Add(meleePower);
Events.EveryOneMinute.Add(EveryOneMinute);
Events.OnPlayerUpdate.Add(MainPlayerUpdate);
Events.OnCreatePlayer.Add(OnCreatePlayer);
-- Events.OnInitWorld.Add(OnCreatePlayer);

-- 移动
-- Events.OnPlayerMove.Add(NoodleLegs);
-- 僵尸死亡
-- Events.OnZombieDead.Add(graveRobber);
-- 武器命中时
-- Events.OnWeaponHitCharacter.Add(problunt);
-- 武器挥动时
-- Events.OnWeaponSwing.Add(progun);
-- 增加经验时
-- Events.AddXP.Add(Specialization);
-- 玩家更新？
-- Events.OnPlayerUpdate.Add(MainPlayerUpdate);
-- 每分钟
-- Events.EveryOneMinute.Add(EveryOneMinute);
-- 每小时
-- Events.EveryHours.Add(EveryHours);
-- 每天
-- Events.EveryDays.Add(EveryDay);
-- 初始化世界
-- Events.OnInitWorld.Add(OnInitWorld);
-- 玩家获取攻击
-- Events.OnPlayerGetDamage.Add(MTPlayerHit)
-- 装备主要武器时
-- Events.OnEquipPrimary.Add(BurnWardItem)
-- 新的游戏
-- Events.OnNewGame.Add(initToadTraitsPerks);
-- 打开容器
-- Events.OnRefreshInventoryWindowContainers.Add(ContainerEvents);
-- 建立角色
-- Events.OnCreatePlayer.Add(OnCreatePlayer);
-- 技能等级?
-- Events.LevelPerk.Add(FixSpecialization);

