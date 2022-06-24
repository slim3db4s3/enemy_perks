dofile_once("data/scripts/lib/utilities.lua")
dofile_once("data/scripts/lib/mod_settings.lua")
dofile_once("data/scripts/perks/perk.lua")
dofile("data/scripts/perks/perk_list.lua")


local perk_settings = {}
local DEFAULT = { boolean = false, number = 0, string = "" }
local dirty = false

function ModSettingsUpdate(init_scope)
	dofile("data/scripts/perks/perk_list.lua")

	local hidden_states = {}
	for i, setting in ipairs(perk_settings) do
   hidden_states[setting.id] = setting.hidden
 end

 perk_settings = {}
 for i,perk in ipairs(perk_list) do
   local setting = {
     id = perk.id,
     name = perk.ui_name,
     desc = perk.ui_description,
     icon = perk.ui_icon,
     key = "enemy_perks.perk_" .. perk.id,
     hidden = hidden_states[perk.id] or false
   }

   if not perk.stackable then
     setting.type = "boolean"
   elseif perk.stackable_maximum then
     setting.type = "number"
     setting.max = perk.stackable_maximum
   else
     setting.type = "string"
   end

   table.insert(perk_settings, setting)

	    -- set to default if unset or incorrect type
	    if type(ModSettingGetNextValue(setting.key)) ~= setting.type then
       ModSettingSetNextValue(setting.key, DEFAULT[setting.type], false)
     end
   end

   table.sort(perk_settings, function(a, b)
     return GameTextGetTranslatedOrNot(a.name)
     < GameTextGetTranslatedOrNot(b.name)
   end)

	-- update everything
	for _, setting in ipairs(perk_settings) do
    ModSettingSet(setting.key, ModSettingGetNextValue(setting.key))
  end
  if init_scope <= MOD_SETTING_SCOPE_NEW_GAME then
   dirty = false
 end
end

function ModSettingsGuiCount()
	return 1
end

local search_text = ""
function ModSettingsGui(gui, in_main_menu)

  local _id = 0
  local function id()
    _id = _id + 1
    return _id
  end

  local val = ModSettingGet("enemy_perks.perk_chance", "20")
  local perk_chance =
  GuiSlider(gui, id(), 0, 0, "Enemy spawn with perk percentage", val, 0, 100, 20, 1, " $0% ", 64)
  if val ~= perk_chance then
    ModSettingSet("enemy_perks.perk_chance", perk_chance, false)
    dirty = true
  end

  if in_main_menu then

    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
    GuiText(gui, 0, 0, "If any modded perks are missing, you'll need to be ingame to configure them.")
  end

  GuiOptionsAdd(gui, GUI_OPTION.DrawActiveWidgetCursorOnBothSides)

  GuiLayoutBeginHorizontal(gui, 0, 0)

  local clicked_clear_search = GuiButton(gui, id(), 0, 0, "Clear search")
  GuiText(gui, 0, 0, "  ")
  local clicked_reset_all = GuiButton(gui, id(), 0, 0, "Reset all")
  if not in_main_menu and dirty then
    GuiColorSetForNextWidget(gui, 1, 1, 1, 0.5)
    GuiText(gui, 0, 0, "   (Perks will apply in a new game)")
  end
  GuiLayoutEnd(gui)
  local input = GuiTextInput(gui, id(), 0, 0, search_text, 130, 30)
  GuiOptionsRemove(gui, GUI_OPTION.DrawActiveWidgetCursorOnBothSides)

  GuiLayoutAddVerticalSpacing(gui, 1.5)

  if clicked_clear_search then
    input = ""
  elseif clicked_reset_all then
    for _, setting in ipairs(perk_settings) do
      ModSettingSetNextValue(setting.key, DEFAULT[setting.type], false)
    end
  end
  if input ~= search_text then
    search_text = input
    if input == "" then
      for _, setting in ipairs(perk_settings) do setting.hidden = false end
    else
      input = input:lower()
      for _, setting in ipairs(perk_settings) do
        setting.hidden = not ((
          GameTextGetTranslatedOrNot(setting.name):lower():find(input, 0, true)
          or setting.id:lower():find(input, 0, true)
          or GameTextGetTranslatedOrNot(setting.desc):lower():find(input, 0, true)
          ) and true or false)
      end
    end
  end

  GuiLayoutBeginHorizontal(gui, 0, 0)
  GuiText(gui, 0, 0, "     ")
  GuiLayoutBeginVertical(gui, 0, 0)
  for _, setting in ipairs(perk_settings) do
    if not setting.hidden then
      local value = ModSettingGetNextValue(setting.key)
      local alpha = value == DEFAULT[setting.type] and 0.5 or 1
      local name = GameTextGetTranslatedOrNot(setting.name)
      local desc = GameTextGetTranslatedOrNot(setting.desc)

      GuiLayoutAddVerticalSpacing(gui, 2)
      GuiOptionsAddForNextWidget(gui, GUI_OPTION.Layout_InsertOutsideLeft)
      GuiImage(gui, id(), -3, -2, setting.icon, alpha, 1, 0)
      GuiColorSetForNextWidget(gui, 1, 1, 1, alpha)
      GuiText(gui, 0, 0, name)
      GuiTooltip(gui, name, desc)
    end
  end
  GuiLayoutEnd(gui)

  GuiText(gui, 0, 0, "  ") -- don't get too close to labels
  GuiLayoutBeginVertical(gui, 0, 0)
  for _, setting in ipairs(perk_settings) do
    if not setting.hidden then
      local value = ModSettingGetNextValue(setting.key)
      if type(value) ~= setting.type then
        value = DEFAULT[setting.type]
      end

      GuiLayoutAddVerticalSpacing(gui, 2)
      if setting.type == "boolean" then
        local text = value and GameTextGet("$option_on") or GameTextGet("$option_off")
        if GuiButton(gui, id(), 0, 0, text) then
          dirty = true
          ModSettingSetNextValue(setting.key, not value, false)
        end
      elseif setting.type == "number" then
        GuiLayoutAddVerticalSpacing(gui, 1.5)
        local next_value =
        GuiSlider(gui, id(), -2, 0, "", value, 0, setting.max, 0, 1, " x$0 ", 64)
        GuiLayoutAddVerticalSpacing(gui, 1.5)
        if next_value ~= value then
        	next_value = math.floor(next_value + 0.5)
          dirty = true
          ModSettingSetNextValue(setting.key, next_value, false)
        end
      else -- setting.type == "string"
      local next_value = GuiTextInput(gui, id(), 0, 0, value, 64, 10, "0123456789")
      if next_value ~= value then
        dirty = true
        if tonumber(next_value) == 0 then next_value = "" end
        ModSettingSetNextValue(setting.key, next_value, false)
      end

    end
  end
end
GuiLayoutEnd(gui)
GuiLayoutEnd(gui)

for _, setting in ipairs(perk_settings) do
  if not setting.hidden then
    GuiLayoutAddVerticalSpacing(gui, 2)
    GuiText(gui, 0, 0, " ")
  end
end
end
