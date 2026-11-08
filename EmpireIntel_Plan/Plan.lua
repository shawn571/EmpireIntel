-- EmpireIntel_Plan / Plan.lua: your goals for /ei next, most important first. Save this file, then /reload.
-- Replace C1 and C2 with your characters' names (or Name-Realm when two share a name).
-- Goal kinds (format 1):
--   { char = 'Name', level = 45 }                            reach a level (2-60)
--   { char = 'Name', profession = 'Tailoring', skill = 150 } reach a skill (1-300)
--   { char = 'Name', rested = 1.0 }                          have this many levels of rested XP (0.05-1.5)
--   { account = true, challenges = 5 }                       complete this many Legacy challenges (1-65)
-- Any goal may add  note = 'your text'. A goal with a mistake is reported (UNEXPECTED) and skipped.
EmpireIntelPlan = {
  version = 1,
  goals = {
    { char = 'C1', level = 45, note = 'Experienced Paladin' },
    { char = 'C2', level = 25 },
    { char = 'C2', profession = 'Tailoring', skill = 150 },
    { char = 'C2', rested = 1.0 },
    { account = true, challenges = 5 },
  },
}
