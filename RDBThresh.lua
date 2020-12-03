	--[[
Code by: rikirayo
Version: 1.0.0
Published: 02/12/2020
]]

if Player.CharName ~= "Thresh" then return end
require("common.log")
module("ThreshRDB", package.seeall, log.setup)
local TickCount = 0
local _SDK = _G.CoreEx
local SpellLib = Libs.Spell
local insert, sort = table.insert, table.sort
local Console, ObjManager, EventManager, Geometry, Input, Renderer, Enums, Game = _SDK.Console, _SDK.ObjectManager, _SDK.EventManager, _SDK.Geometry, _SDK.Input, _SDK.Renderer, _SDK.Enums, _SDK.Game
local Menu, Orbwalker, Collision, Prediction, HealthPred = _G.Libs.NewMenu, _G.Libs.Orbwalker, _G.Libs.CollisionLib, _G.Libs.Prediction, _G.Libs.HealthPred
local DmgLib, ImmobileLib, Spell = _G.Libs.DamageLib, _G.Libs.ImmobileLib, _G.Libs.Spell
local AbilityResourceTypes, BuffTypes, DamageTypes, Events, GameObjectOrders, HitChance, ItemSlots, ObjectTypeFlags, PerkIDs, SpellSlots, SpellStates, Teams = 
Enums.AbilityResourceTypes, Enums.BuffTypes, Enums.DamageTypes, Enums.Events, Enums.GameObjectOrders, Enums.HitChance, Enums.ItemSlots, Enums.ObjectTypeFlags, Enums.PerkIDs, Enums.SpellSlots, Enums.SpellStates, Enums.Teams
local TS = _G.Libs.TargetSelector()
local SpellSlots, SpellStates = Enums.SpellSlots, Enums.SpellStates
local Thresh = {}
local spells = {
	Q = Spell.Skillshot({
		Slot = SpellSlots.Q,
		Range = 1100,
		Widht = 140,
		Speed = 1900,
		Delay = 0.5,
		Collisions = {Minions=true, WindWall=true},
		Type = "Linear"
	}),
    W = Spell.Skillshot({
        Slot = SpellSlots.W,
        Range = 950,
        Radius = 300,
        Type = "Circular"
    }),
    E = Spell.Skillshot({
        Slot = SpellSlots.E,
        Range = 500,
        Delay = 0.3889,
        Type = "Linear"
    }),
    R = Spell.Active({
        Slot = SpellSlots.R,
        Range = 400
    })
}
local function Game_ON()
	--juego activo, no muerto, etc.
	return not (Game.IsChatOpen() or Game.IsMinimized() or Player.IsDead or Player.IsRecalling)
end
local function IsValidTarget(object, range, from)
    return TS:IsValidTarget(object, range, from)
end
local function EnemiesInRange(pos,range,enemies)
	local count = 0
	for k, enemy in pairs(enemies or ObjManager.Get("enemy", "heroes")) do
	    local enemy = enemy.AsAI
	    if enemy and IsValidTarget(enemy, range, pos) then
	        count = count + 1
	    end
    end
    return count
end
function Thresh.OnDraw()
    local PP = Player.Position
    if Menu.Get("DQ")then
        Renderer.DrawCircle3D(PP,spells.Q.Range,30,2,0x0099FFFF)
    end
    if Menu.Get("DW") then
        Renderer.DrawCircle3D(PP,spells.W.Range,30,2,0x0099FFFF)
    end
    if Menu.Get("DE") then
        Renderer.DrawCircle3D(PP,spells.E.Range,30,2,0x0099FFFF)
    end
    if Menu.Get("DR") then
        Renderer.DrawCircle3D(PP,spells.R.Range,30,2,0x0099FFFF)
    end
end

function Thresh.QRawDamage()
	-- 80 / 120 / 160 / 200 / 240 (+ 50% AP)
	return (40*spells.Q:GetLevel()+40)+(Player.TotalAP * 0.5)
end
function Thresh.ERawDamage()
    -- 65 / 95 / 125 / 155 / 185 (+ 40% AP)
    return (30*spells.E:GetLevel()+35)+(Player.TotalAP * 0.85)
end
function Thresh.RRawDamage()
    -- 150 / 275 / 400 (+ 75% PH)
    return (125*spells.R:GetLevel()+25)+(Player.TotalAP* 0.75)
end

function Thresh.GetTargets(range)
    return {TS:GetTarget(range, true)}
end 

function Thresh.Harass()
	local QChance = Menu.Get("HCQ")
	--[[if Menu.Get("HQ") and spells.Q:IsReady() then
        for k, qTarget in ipairs(Thresh.GetTargets(spells.Q.Range)) do
	        if spells.Q:CastOnHitChance(qTarget,QChance) then
	        	if qTarget:GetBuff("threshq") and Menu.Get("HQ2") and spells.Q:Cast(qTarget) then
	  			end
	  		end
        end
    end]]
    for k, Target in ipairs(Thresh.GetTargets(spells.Q.Range)) do
        local targetAI = Target.AsAI
        if targetAI and Menu.Get("HQ") then
            qPred = Prediction.GetPredictedPosition(targetAI, spells.Q, Player.Position)
            if qPred then 
                if qPred.HitChance >= Menu.Get("HCQ") then
                    qPred = qPred.CastPosition
                else 
                    qPred = nil
                end
            end
        end
    end
    
    if Player:GetSpellState(SpellSlots.Q) == SpellStates.Ready
        and qPred then
        Input.Cast(SpellSlots.Q, qPred)
        if Player:GetSpellState(SpellSlots.Q) == SpellStates.Ready and Menu.Get("HQ2") and spells.Q:Cast(Player) then end
    end
    
    if Menu.Get("HE") and spells.E:IsReady() then
        for k,eTarget in ipairs(Thresh.GetTargets(spells.E.Range)) do
            if (Menu.Get("HPull")) then
                local pull = eTarget.Position:RotatedAroundPoint(Player, 3,0,3)
                if spells.E:Cast(pull) then
                    return
                end
            else
                spells.E:Cast(eTarget)
            end
        end
    end
end
function Thresh.Combo()
    local qPred = nil
	local QChance = Menu.Get("CCQ")
    --[[if Menu.Get("CQ") then
	   if spells.Q:IsReady() then
    		for k, Target in ipairs(Thresh.GetTargets(spells.Q.Range)) do
                local pred = Prediction.GetPredictedPosition(Target, spells.Q, Player.Position)
                spells.Q:CastOnHitChance(pred.CastPosition,QChance)
				if Target:GetBuff("threshq") and Menu.Get("CQ2") and spells.Q:Cast(Target) then
                end
            end
		end
	end]]
    for k, Target in ipairs(Thresh.GetTargets(spells.Q.Range)) do
        local targetAI = Target.AsAI
        if targetAI and Menu.Get("CQ") then
            qPred = Prediction.GetPredictedPosition(targetAI, spells.Q, Player.Position)
            if qPred then 
                if qPred.HitChance >= Menu.Get("CCQ") then
                    qPred = qPred.CastPosition
                else 
                    qPred = nil
                end
            end
        end
    end
    
    if Player:GetSpellState(SpellSlots.Q) == SpellStates.Ready
        and qPred then
        Input.Cast(SpellSlots.Q, qPred)
        if Player:GetSpellState(SpellSlots.Q) == SpellStates.Ready and Menu.Get("CQ2") and spells.Q:Cast(Player) then end
    end


	if Menu.Get("CE") and spells.E:IsReady() then
        for k,eTarget in ipairs(Thresh.GetTargets(spells.E.Range)) do
            if (Menu.Get("CPull")) then
                local pull = eTarget.Position:RotatedAroundPoint(Player, 3,0,3)
                if spells.E:Cast(pull) then
                    return
                end
            else
                spells.E:Cast(eTarget)
            end
        end
    end
    if Menu.Get("CR") and spells.R:IsReady() then
        for k,eTarget in ipairs(Thresh.GetTargets(spells.R.Range)) do
            if spells.R:Cast() then
                return
            end
        end
    end
end
function Thresh.OnTick()
    	--comprobamos que el juego este activo
    	if not Game_ON() then return end
    	--comprobamos que el Orbwalker funcione
    	if not Orbwalker.CanCast() then return end
    	--ejecutamos el orbwalker que toca
	local ModeToExecute = Thresh[Orbwalker.GetMode()]
    if ModeToExecute then
        ModeToExecute()
    end
    Thresh.auto()
end
function Thresh.auto()
	if Menu.Get("AR") then
		local count = 0
	    local RRange = spells.R.Range
	    local enemies = ObjManager.Get("enemy", "heroes")
	    local PP = Player.Position
	    if EnemiesInRange(PP, RRange, enemies) >= Menu.Get("MAR") then
	    	spells.R:Cast()
	    end
	end
	if Menu.Get("AW") then
		local range = spells.W.Range
		for k,ally in pairs(ObjManager.Get("ally","heroes")) do
			local Ally = ally.AsHero
			if Ally:Distance(Player) <= spells.W.Range and EnemiesInRange(Ally,600) >= Menu.Get("MAW") then
				spells.W:Cast(Ally)
			end
		end
	end
end
function Thresh.OnGapclose(source,dash)
    if not (source.IsEnemy and Menu.Get("AE") and spells.E:IsReady()) then return end
    local paths = dash:GetPaths()
    local endPos = paths[#paths].EndPos
    if source:Distance(Player) < 400 then
        spells.E:Cast(source)
    end
end
function Thresh.LoadMenu()
	Menu.RegisterMenu("ThreshRDB","ThreshRDB",function ()
		Menu.ColumnLayout("cols", "cols", 3, true, function()

            Menu.ColoredText("Combo", 0X0099FFFF,false)
            Menu.Checkbox("CQ", "Use Q", true)
            Menu.Checkbox("CQ2", "Use 2º Q", true)
            Menu.Slider("CCQ", "HitChance Q", 0.7, 0, 1, 0.05)
            Menu.Checkbox("CE", "Use E", true)
            Menu.Checkbox("CPull", "E to pull", true)
            Menu.Checkbox("CR","Use R",true)

            Menu.NextColumn()

            Menu.ColoredText("Harass", 0X0099FFFF,false)
            Menu.Checkbox("HQ", "Use Q", true)
            Menu.Checkbox("HQ2", "Use 2º Q", true)
            Menu.Slider("HCQ", "HitChance Q", 0.7, 0, 1, 0.05)
            Menu.Checkbox("HE", "Use E", true)
            Menu.Checkbox("HPull", "E to pull", true)

            Menu.NextColumn()

            Menu.ColoredText("AutoSpells", 0X0099FFFF,false)
            Menu.Checkbox("AR","Use R",true)
            Menu.Slider("MAR", "Min. Heroes Hits", 3, 0, 5, 1)
            Menu.Checkbox("AE", "E when gapclose", true)
            Menu.Checkbox("AW", "Auto W", true)
            Menu.Slider("MAW", "Min. Enemies", 3, 0,3, 1)
			end)
        Menu.Separator()
        Menu.ColoredText("Draws", 0X0099FFFF, false)
        Menu.Checkbox("DQ","Q range",true)
        Menu.Checkbox("DW","W range",true)
        Menu.Checkbox("DE","E range",true)
        Menu.Checkbox("DR","R range",true)
	end)
end

function OnLoad()
		Thresh.LoadMenu()
    for eventName, eventId in pairs(Enums.Events) do
        if Thresh[eventName] then
            EventManager.RegisterCallback(eventId, Thresh[eventName])
        end
    end    
    return true
end