TinyRockgroveHelper = {
  name = "TinyRockgroveHelper",
  version = "1.0",
  varVersion = 1,
  portalDebuffId = 153423,
  inPortal = false,
  marrowTime = 0,
  display = false,
  defaults = {
    ["panelCenterX"] = 500,
    ["panelCenterY"] = 500,
  },
}

local TRH = TinyRockgroveHelper

function TRH.OnCombatEvent(eventCode, result, isError, abilityName, abilityGraphic, abilityActionSlotType, sourceName, sourceType, targetName, targetType, hitValue, powerType, damageType, log, sourceUnitId, targetUnitId, abilityId, overflow)
  if abilityId == TRH.portalDebuffId then
    if targetType == COMBAT_UNIT_TYPE_PLAYER then
      if result == ACTION_RESULT_EFFECT_GAINED then
        TRH.inPortal = true
        TRH.HidePanel(not TRH.inPortal)
      elseif result == ACTION_RESULT_EFFECT_FADED then
        TRH.inPortal = false
        TRH.HidePanel(not TRH.inPortal)
      elseif result == ACTION_RESULT_DOT_TICK then
        TRH.marrowTime = GetGameTimeMilliseconds()/1000 + 2
        EVENT_MANAGER:RegisterForUpdate(TRH.name.."MarrowUpdate", 100, TRH.Countdown)
      end
    end
  end
end

function TRH.Move()
	TRH.savedVars.panelCenterX, TRH.savedVars.panelCenterY = TRH_Marrow:GetCenter()
	TRH_Marrow:ClearAnchors()
	TRH_Marrow:SetAnchor(CENTER, GuiRoot, TOPLEFT, TRH.savedVars.panelCenterX, TRH.savedVars.panelCenterY)
end

function TRH.RestorePosition()
	local panelCenterX = TRH.savedVars.panelCenterX
	local panelCenterY = TRH.savedVars.panelCenterY
	if panelCenterX or panelCenterY then
		TRH_Marrow:ClearAnchors()
		TRH_Marrow:SetAnchor(CENTER, GuiRoot, TOPLEFT, panelCenterX, panelCenterY)
	end
end

function TRH.Countdown()
  TRH_Marrow_Text:SetText(string.format("%.1f",  TRH.Time(TRH.marrowTime, 10)))
	if (TRH.marrowTime - GetGameTimeMilliseconds()/1000 <= 0) then 
		TRH_Marrow_Text:SetText("0")
		EVENT_MANAGER:UnregisterForUpdate(TRH.name.."MarrowUpdate")
	end
end

function TRH.HideFrame()
	if not IsReticleHidden() then TRH.HideOutOfCombat() end
end

function TRH.CombatState()
	TRH.HideOutOfCombat()
end

function TRH.HideOutOfCombat()
  TRH.HidePanel(not IsUnitInCombat("player"))
end

function TRH.HidePanel(value)
  if TRH.inPortal then
    TRH_Marrow:SetHidden(value)
  else
    TRH_Marrow:SetHidden(true)
  end
end

function TRH.UnlockPanel()
  TRH.display = not TRH.display
  if TRH.display then
      EVENT_MANAGER:UnregisterForEvent(TRH.name.."Hide", EVENT_RETICLE_HIDDEN_UPDATE)
      TRH_Marrow:SetHidden(false)
      TRH_Marrow:SetMovable(true)
      TRH_Marrow:SetMouseEnabled(true)
    else
      EVENT_MANAGER:RegisterForEvent(TRH.name.."Hide", EVENT_RETICLE_HIDDEN_UPDATE, TRH.HideFrame)
      TRH_Marrow:SetHidden(IsReticleHidden())
      TRH_Marrow:SetMovable(false)
      TRH_Marrow:SetMouseEnabled(false)
    end
end

function TRH.OnAddOnLoaded(event, addonName)
  if addonName == TRH.name then
    TRH.savedVars = ZO_SavedVars:NewAccountWide("Settings", TinyRockgroveHelper.varVersion, nil, TinyRockgroveHelper.defaults)
    EVENT_MANAGER:RegisterForEvent(TRH.name.."Hide", EVENT_RETICLE_HIDDEN_UPDATE, TRH.HideFrame)
    EVENT_MANAGER:RegisterForEvent(TRH.name.."CombatState", EVENT_PLAYER_COMBAT_STATE,  TRH.CombatState)
    TRH.RestorePosition()
    EVENT_MANAGER:UnregisterForEvent(TRH.name.."Load", EVENT_ADD_ON_LOADED)
  end
end

function TRH.Time(nd, multiplier)
	return math.floor((nd - GetGameTimeMilliseconds()/1000) * multiplier + 0.5)/multiplier
end

EVENT_MANAGER:RegisterForEvent(TRH.name.."Load", EVENT_ADD_ON_LOADED, TRH.OnAddOnLoaded)
EVENT_MANAGER:RegisterForEvent(TRH.name.."CombatEvent", EVENT_COMBAT_EVENT, TRH.OnCombatEvent)