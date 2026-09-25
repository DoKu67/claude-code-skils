---
name: brainstorm
description: Generate genuinely different options before evaluating any of them — reframe the problem, name the obvious answers and set them aside, rotate the axes, generate in parallel without cross-talk (one generator searching prior art), attack the survivors, then restate the goal and cut requirements until the scope is smaller than it started. Use when the shape of a problem is not settled: designing a reward function or RL environment, choosing how to structure something with no obvious right answer, when the same few ideas keep resurfacing, or when the user says "brainstorm", "what are my options", "what else could we do", "I'm stuck". Ends by handing off; it does not build or write files.
---

# brainstorm

The default failure is not a shortage of ideas. It is that **the first plausible idea gets
built** — chosen in one pass, phrased in the words the question arrived in, and never
compared against anything that was not already implied by the question.

**Generation and evaluation must not touch.** The moment an option is proposed alongside a
recommendation, the strange option is dead — it loses to the safe one before anyone has
worked out what it would cost to be wrong. Every stage below exists to keep those two apart
for longer than feels comfortable.

And it ends by **subtracting**. Divergence inflates scope as a side effect of working
properly, so the last stage restates the goal and cuts it back — a brainstorm that hands over
a bigger project than it received has failed, however good the ideas were.

This ends in a decision, a shortened objective, and a handoff. Minutes, not a session.

## When it fires

| Brainstorm | Skip it |
|---|---|
| The shape of the problem is not settled | The approach is already chosen and the work is mechanical |
| Several designs are plausible and the choice has consequences | The choice is cheap and reversible — just pick one |
| The same three ideas keep coming back | Someone else has plainly solved this — [`prior-work`](../prior-work/SKILL.md) first |
| A reward, objective, or evaluation is being designed | A capability list is what is actually needed — that is [`mvp`](../mvp/SKILL.md) stage 1 |
| The user is stuck, or asks what else there is | The user has already decided and wants it built |

Firing on a settled question is the way this skill becomes ceremony. If in doubt, say what
it would cost — a few minutes and a handful of parallel agents, watchable in `/workflows` —
and let the user decide.

## 1 — Reframe

Restate the problem **in words that are not the user's**. One or two sentences, not a phase.

Then name the premise and ask whether it is load-bearing: *what would have to be true for
this to be the wrong problem?* The framing arrives carrying assumptions — what the unit of
work is, who it is for, what counts as success. Options generated inside a frame all inherit
the frame's blind spot.

If the reframe lands somewhere genuinely different, say so and check before continuing. A
brainstorm that quietly redefines the problem is worse than one that never started.

## 2 — Name the defaults, then set them aside

Say the obvious answers out loud — the two or three anyone would reach for — and write them
down as **defaults, not candidates**.

Unnamed defaults get regenerated. Named ones stop occupying the search. This also makes the
honest outcome visible: sometimes the default is correct, and discovering that in thirty
seconds is a good result, not a wasted exercise.

## 3 — Rotate the axes

Ideation is a navigation problem, not a generation problem. Each axis is a direction to walk
in, and each one surfaces things the others structurally cannot:

| Axis | The rotation |
|---|---|
| **Who** | Who else touches this? What would a non-expert, an adversary, or the person maintaining it in a year choose? |
| **When** | What if this ran once? Continuously? Only on failure? Before the thing it currently follows? |
| **Scale** | What if it were 100× cheaper, or had to work at 100× the size, or ran on one GPU? |
| **Method** | What is the mechanism doing the work — and what else does that job? Separate the function from the form |
| **Inversion** | What if the opposite were true? What would guarantee failure — and are we near it? |
| **Constraint removal** | Which constraint is assumed rather than real? Drop it and see what opens |
| **Prior art** | Who has already built this, and what did they do that nobody here would have thought of? |

Pick the axes that fit the problem. Three used properly beat six used nominally.

**Prior art is not optional whenever the problem sounds like one others have had.** It is the
only axis that generates from what exists in the world rather than from the model's priors,
and it is the one that stops a brainstorm from confidently reinventing a solved thing under a
different name.

## 4 — Diverge, in parallel, without cross-talk

One agent per axis, running concurrently and **unable to see each other's output**.
Sequential generation in one context anchors every option on the first one written;
independent generation is the only mechanism that reliably avoids it.

Run it as a workflow — see [Mechanics](#mechanics--running-stages-45-as-a-workflow) — so the
axes are visible in flight rather than arriving as a finished list.

Each generator gets:

- the reframed problem — **not** the original phrasing, and **not** your preferred approach
- exactly one axis, with the rotation spelled out
- the defaults, marked as already taken
- an instruction to return options with **the mechanism** for each, one line, **and no ranking**

Scale the fleet to the stakes: three agents for an ordinary question, five or six when the
decision is expensive or hard to reverse.

**One of them is the prior-art scout**, running [`prior-work`](../prior-work/SKILL.md)'s
method against the reframed problem: **search both the internet and the internal sources**
— the web (Devin: `web_search` / `web_fetch`; Claude Code: `WebSearch` / `WebFetch`) for
how the world solved the general problem, and repos, Slack, Notion and docs for what has
already been tried in-house — across several angles, second round with the vocabulary the
first taught, returning **mechanisms with links** labelled by where they came from.
It returns options like any other generator, and its findings enter the same dedupe. Two
things make it worth a slot of its own:

- the mechanisms it brings back are ones no amount of rotation would have produced, because
  they came from someone hitting the problem in reality rather than from a prompt
- **the gap every implementation shares is a candidate in its own right** — a weakness nobody
  has solved is either the hard part or a blind spot, and either way it belongs on the list

If the scout comes back with a close match, say so plainly before continuing. Discovering the
thing already exists is a good outcome and it arrives cheapest here.

Then dedupe, and apply the test that decides whether this worked:

> **Two options that differ only in a parameter, a name, or a wording are one option.**

If the deduped list collapses to the defaults, rotate a different axis and go again. **Stop
when two consecutive rounds add no new mechanism** — not at a fixed count, and not when the
list looks long enough.

## 5 — Attack

Now, and not before, turn adversarial. Take the survivors and ask what kills each one:
where it breaks, what it assumes, what it costs when it fails rather than when it works.

**Attack the front-runner hardest.** The favourite is the option whose weaknesses everyone
has the least incentive to find, and the one that will actually get built if nobody does.

An attack that produces only "it might be complex" is a formality, not a test. Name the
concrete failure — the input, the scale, or the condition under which it goes wrong.

## 6 — Converge

Pick, in one sentence, and **name what is being traded away**. An option chosen without a
stated cost has not been chosen; it has been defaulted to.

Report the rejected options in one line each — what they were and why they lost. That list
is the most reusable output here: when the choice is revisited in a month, it is what stops
the same ground being covered again.

## 7 — Restate, then cut

Everything so far has added. **Nothing in stages 1–6 subtracts, and a brainstorm that ends
here reliably produces a bigger project than the one that walked in** — every good idea
survived, every attack got answered with a mitigation, and the objective quietly grew a
dozen requirements nobody chose.

So restate first, compactly, in [`tldr`](../tldr/SKILL.md)'s shape — **what this is, the one
goal, what blocks it**. Write it as if the brainstorm had not happened and this were the
opening description of the work. If that restatement takes more than a short paragraph, the
scope has already inflated.

Then cut, by the **delete-first test**: remove each requirement and say what actually breaks.

| Verdict | Where it goes |
|---|---|
| Something concrete breaks | Keep — and it is now justified rather than assumed |
| Nothing breaks, but it would be nice | Out of scope, written down, not deleted from memory |
| Only a hypothetical future breaks | Out of scope. It waits its turn |
| It was inherited from an option that lost | Delete. It was never chosen |

The target is a shorter list than the one stage 6 handed over. **If the objective list is
longer than when the brainstorm started, the exercise has cost more than it produced** — say
so plainly rather than shipping the inflation.

### Loop if the cut moved the ground

Cutting reopens the design space: a smaller objective can have a different best option, and
often the option that lost on complexity wins once half the requirements are gone. When the
cut removes something the pick was chosen to satisfy, **return to stage 3 with the reduced
problem** — one rotation, not a full restart.

Stop looping when a cut no longer changes the pick. Two passes is normal; a third means the
objective itself is unstable, which is a question for the user, not another round.

## Mechanics — running stages 4–5 as a workflow

**Invoking this skill is the opt-in.** Stages 4–5 run as a `Workflow`, not as loose agent
calls, so the user can watch the axes work in `/workflows` instead of waiting for a finished
list. Stages 1–3 and 6–7 stay conversational — they are where the user's judgement enters,
and a workflow cannot ask a question.

The barrier between the phases is deliberate and is the one case the tool's own guidance
calls justified: **dedupe needs every generator's output at once**, because merging by
mechanism is a cross-item judgement. Attack then pipelines per survivor.

```javascript
export const meta = {
  name: 'brainstorm-diverge',
  description: 'Generate options along independent axes, dedupe by mechanism, attack survivors',
  phases: [
    { title: 'Diverge', detail: 'one agent per axis, no cross-talk' },
    { title: 'Dedupe',  detail: 'merge options sharing a mechanism' },
    { title: 'Attack',  detail: 'concrete failure per survivor' },
  ],
}

const { problem, defaults, axes } = args   // reframed problem — never the original phrasing

phase('Diverge')
const raw = (await parallel(axes.map(a => () =>
  agent(`${problem}\n\nRotate this axis only: ${a.rotation}\n` +
        `Already taken, do not repeat: ${defaults.join('; ')}\n` +
        `Return options, each with its mechanism in one line. Do NOT rank or recommend.`,
        { label: `axis:${a.name}`, phase: 'Diverge', schema: OPTIONS_SCHEMA }))))
  .filter(Boolean).flatMap(r => r.options)          // barrier: dedupe needs all of them

phase('Dedupe')
const kept = await agent(
  `Merge options sharing a mechanism. Two that differ only in a parameter, a name or a ` +
  `wording are ONE option. Return survivors and note which axes produced each.\n\n` +
  JSON.stringify(raw), { schema: OPTIONS_SCHEMA })

phase('Attack')
const attacked = await parallel(kept.options.map(o => () =>
  agent(`Find what kills this option. Name the concrete failure — the input, scale or ` +
        `condition where it breaks. "It might be complex" is not an answer.\n\n${o.mechanism}`,
        { label: `attack:${o.name}`, phase: 'Attack', schema: ATTACK_SCHEMA })
    .then(v => ({ ...o, attack: v }))))

return { options: attacked.filter(Boolean), dropped: raw.length - kept.options.length }
```

Rules that survive the move into a script:

- **The prior-art scout is one of the `axes`**, given `prior-work`'s method rather than a
  rotation — search the web *and* internal sources across several angles, second round with
  the vocabulary the first taught, return mechanisms with links labelled by origin. Its
  prompt must name both; left unsaid, agents default to grepping the repo and come back with
  nothing from outside it.
- **No generator sees another's output, and none of them rank.** If a generator returns a
  recommendation, drop the ranking and keep the options.
- **Scale the fleet to the stakes**: three axes for an ordinary question, five or six when the
  decision is expensive or hard to reverse. With the dedupe and attack agents this stays
  inside a dozen — do not let it grow into a fleet that costs more than the decision.
- **The no-new-mechanism stop rule still applies.** If the dedupe returns roughly what the
  defaults already were, that is a round that added nothing: change the axes and re-run rather
  than re-running the same ones.
- **Say what was dropped.** `dropped` is reported, not silently discarded — a dedupe that
  collapses fifteen options into two is a finding about the problem.

Fall back to plain parallel agent calls when the question is small enough that the workflow's
setup costs more than the divergence is worth. The mechanism that matters is the absence of
cross-talk, not the tool that provides it.

## Handoff

Then hand off, and stop:

| Next | Skill |
|---|---|
| Build it | [`mvp`](../mvp/SKILL.md) — the pick becomes its stage 1 input |
| Has anyone already built it | [`prior-work`](../prior-work/SKILL.md) |
| Keep the reasoning | [`notes`](../notes/SKILL.md) → `notes.md`, ideas and what they meant |
| Only the user can decide | [`escalate`](../escalate/SKILL.md) |

## Traps

- **Ranking during generation.** The most common failure, and it destroys the exercise
  silently — the list still looks like a brainstorm. No comparative language before stage 5.
- **Variations dressed as alternatives.** Three learning rates are one option. If two entries
  share a mechanism, they are one entry.
- **Anchoring the generators.** Including your preferred approach, or the user's original
  phrasing, in a generator's prompt guarantees it comes back with that approach's neighbours.
- **Brainstorming instead of checking.** If the answer is knowable — someone has built it,
  the constraint is measurable, the run would tell you — generating options is procrastination
  wearing a method.
- **Letting the option list become the deliverable.** It is an input to a decision. If the
  brainstorm ends without a pick, it has not finished.
- **Scope inflation, the failure this skill causes.** Divergence is generative by
  construction: good ideas accumulate, attacks get answered by adding a mitigation, and the
  project grows without anyone deciding it should. Stage 7 is not optional, and skipping it
  turns a brainstorm into the reason a two-week job became a two-month one.
- **Answering an attack by adding a requirement.** The usual response to "this breaks at
  scale" is a mitigation. Often the right response is a *smaller* objective that never meets
  the failing condition — cheaper, and it survives stage 7.
- **Firing on a settled question.** Ceremony on top of a decision the user already made is
  how a skill earns its way into a [`skill-audit`](../skill-audit/SKILL.md) prune list.

## Out of scope

Deciding *what to build* and building it — [`mvp`](../mvp/SKILL.md). The full prior-art
survey as its own deliverable — [`prior-work`](../prior-work/SKILL.md), which stage 4 borrows
the method of and which is the better first move on its own whenever the problem sounds
common. Status of work already underway — [`tldr`](../tldr/SKILL.md), whose shape stage 7
borrows. Recording the outcome — [`notes`](../notes/SKILL.md). Writing it up as a document —
[`report`](../report/SKILL.md). This skill writes no files.

## Done when

The problem was restated in words that were not the user's and the premise was tested; the
obvious answers were named as defaults before anything else was generated; generators ran in
parallel without seeing each other — as a workflow unless the question was too small to
warrant one — with one of them searching prior art when the problem was not unique to this
repo; options that share a mechanism were merged and the count dropped was reported;
generation stopped on the no-new-mechanism rule rather than a count; the front-runner was
attacked with a concrete failure rather than a hedge; the pick names what it trades away,
with the rejected options recorded in one line each; and **the objective was restated and
cut, ending no longer than it started** — with a loop back to stage 3 if the cut changed what
the right option was.
