local ADDON, EI = ...
-- EmpireIntel / Core / Boot.lua  (last file in the TOC)
-- Installs /ei at once, then opens the saved data and starts the snapshot once the player is logged in.

EI = EI or {}
local P = EI.Platform

EI.Commands.Install()

P.OnReady(function()
  local st = EI.Store.Open()
  if st and st.state == 'readonly' then
    P.Print('saved data is newer than this version; it is left untouched and nothing is saved this session.')
  end
  EI.Snapshot.Start()
  -- D-065: repeated steps in my plan are removed at load (the first kept) and chat says which; after the first
  -- snapshot, so the chat line can name the played character
  P.After(EI.Snapshot.FIRST_DELAY + 1, function()
    local okD, removed, why = pcall(EI.Plan.Dedupe)
    if not okD then P.Print('UNEXPECTED: plan check: ' .. tostring(removed))
    else
      local byGuid = {}
      if removed and #removed > 0 and EI.Views then
        local okV, rows = pcall(EI.Views.Collect)
        if okV then for _, r in ipairs(rows) do if r.guid then byGuid[r.guid] = r end end end
      end
      local t = EI.Plan.DedupeText(removed, why, byGuid)
      if t then P.Print('plan: ' .. t) end
    end
  end)
  if EI.MinimapButton then
    local ok, err = pcall(EI.MinimapButton.Init)
    if not ok then P.Print('UNEXPECTED: minimap button: ' .. tostring(err)) end
  end
end)

P.Events.CheckLateLoad()
