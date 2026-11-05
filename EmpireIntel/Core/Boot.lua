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
end)

P.Events.CheckLateLoad()
