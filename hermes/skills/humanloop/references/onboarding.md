# Onboarding interview

Goal: a first life model Sid agrees with. About 20-30 minutes, in sections; Sid can stop
after any section and resume later.

## Start

1. `cat /opt/data/humanloop/onboarding.md`. Resume at the first section not marked done.
2. First time only: say in two lines what HumanLoop is, that nothing is saved without Sid's
   OK, and that Sid can say "skip", "later" or "stop" any time.

## Each section

1. Ask 2-4 short questions, one at a time. Follow up on vague answers once ("by when?",
   "how many hours a week?"), then move on.
2. Turn the answers into model lines (format in SKILL.md), at most ~8 per section.
3. Show the lines and ask: "Save these? (yes / edit / skip)".
4. On yes: append them to the model file, mark the section done in `onboarding.md` with the
   date, and confirm in one line. On edit: change and show again. On skip: mark it skipped.

## Sections, in order

1. **Basics** (`preferences.md`): what Sid wants to be called, time zone, what Sid does now
   (study, work, studio, other roles), which Google account is used for what
   (sidhantbastola7, sibastola6ucl, disisidstudio).
2. **Goals** (`goals.md`): the 1-3 things that matter most in the next year, and why; one
   longer-term ambition. For each: what "done" looks like, and a target date if there is one.
3. **Projects** (`projects.md`): what Sid is actively working on now; for each, the goal it
   serves (g-id), its status, and the very next step.
4. **Commitments** (`commitments.md`): first ask what Sid has coming up (deadlines, exams,
   meetings, recurring obligations). Then read the next 14 days from all three calendars
   (`gacct all calendar list --start <today>T00:00:00Z --end <+14d>T00:00:00Z`) and propose
   the events that matter as `[verified]` lines with `src: calendar:<account>`. Skip
   anything that looks routine or declined.
5. **Routines** (`routines.md`): usual wake and sleep time, best hours for focused work,
   when energy dips, fixed weekly blocks (classes, gym, work shifts).
6. **How HumanLoop should work** (`preferences.md`): check-in frequency during active hours
   (suggest hourly), quiet hours, how to be reminded (direct, gentle, motivating), what to
   never do.

## Finish

1. Mark onboarding done in `onboarding.md`.
2. Show a short summary: counts per file, and the 3 goals in one line each.
3. Offer at most 3 `[inferred]` observations (patterns or tensions you noticed, e.g. "the
   dissertation and the studio project both peak in November"). Ask about each; save only
   the ones Sid confirms, as `[declared]` with `src: confirmed inference <date>`.
4. Tell Sid the files are in `~/humanloop/model/` on the Mac and can be edited directly.
