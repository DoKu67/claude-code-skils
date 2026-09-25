---
name: prior-work
description: Survey how a problem has already been solved before designing a solution to it — search several angles, then report what implementations converge on and where they all fall short. Use before designing a system, format, protocol, workflow or algorithm that others have plausibly built; when choosing between approaches; when the user asks "has anyone done this", "search for prior art", or "I'm not the first person to do this"; and whenever you are about to invent something that sounds like it should already exist.
---

# prior-work

Almost nothing worth building is being built for the first time. The question is never
whether prior work exists — it is whether you find it before or after you have committed to
a design.

**The gaps are the design.** What every existing implementation does is table stakes; what
they all *fail* at is where the work actually is. A survey that produces only a list of
what exists has stopped one step short of being useful.

This is a method, not a rule. It ends in two tables and a recommendation, and it takes
minutes.

---

## When it fires

| Search first | Skip it |
|---|---|
| Designing a system, format, protocol or workflow | The task is mechanical and the shape is settled |
| Choosing between two approaches with real consequences | The question is purely about internal facts — what one repo does, what a config is set to — with no general problem underneath |
| About to invent something that sounds like it should exist | You have already surveyed this in the same session |
| A named technique you have not implemented before | The user has said to skip it |

The tell that you should have searched and did not: the user asks *"has anyone else done
this?"* By then the design already exists and the search becomes a check on it rather than
an input to it.

---

## Searching

**Search two places, always: the internet and the internal sources.** They answer
different questions and neither substitutes for the other.

| Where | Tools | What it answers |
|---|---|---|
| **Internet** | Devin: `web_search` / `web_fetch` and the browser; Claude Code: `WebSearch` / `WebFetch` | How the rest of the world has solved the *general* problem — the convergence and gaps tables come from here |
| **Internal** | Repos on disk, Slack, Notion, Linear, internal docs, past sessions — whatever the harness exposes | What the subject *is* here, what has already been tried in-house, what constraints and vocabulary the team uses — the recommendation is grounded here |

Do the internal pass first when the subject has internal names: work out what *general
problem* it is an instance of, then take that to the web. "Compare our rankers A and B"
becomes a web survey of how the field ranks under that constraint, plus an internal survey
of what A and B actually do and what was tried before them. Both appear in the write-up,
labelled as such. Skipping the web pass turns the survey into a description of the status
quo; skipping the internal pass produces advice that ignores what the team already knows.
If either set of tools is unavailable, say so in the write-up rather than quietly reporting
half a survey as a whole one.

**Search several angles.** Each surfaces things the others structurally cannot, and one
angle alone reliably produces a confident, partial picture.

| Angle | Gives you |
|---|---|
| **Papers** | The framing and the vocabulary — usually the fastest way to learn what the thing is *called* |
| **Repositories** | What actually ships, and what got cut between the paper and the code |
| **Practitioner writeups** | The failure reports. Blog posts say what broke, which papers rarely do |
| **Official docs** | The constraints of the tools you would actually build on |
| **Issues and discussions** | The traps, and the features people asked for and did not get |

**Run two rounds.** The first search teaches you the vocabulary — the term the field
actually uses, which is usually not the term you searched. Search again with the words you
just learned. Skipping the second round is the single most common reason a survey comes back
empty on a well-studied problem.

**Stop when two consecutive sources add no new mechanism.** Not when you have read
everything — that never happens — and not after a fixed count. If sources keep introducing
mechanisms you had not seen, keep going.

### Parallelising

The angles are independent, so round one fans out. **When three or more angles apply, run
each in its own subagent** (Devin: `run_subagent`; Claude Code: the Task/Agent tool), all
concurrently, each told: the problem in the reframed general terms, exactly one angle, and
to return sources with a one-line mechanism each and no recommendation. The internal pass
is one more angle and gets its own subagent on the same terms. Keeping the angles in
separate contexts is also what stops the first angle's framing from colouring the rest.

Round two stays with you: it depends on the vocabulary round one produced, so collect the
results, pick the terms, and either search yourself or fan out once more with the new
words. Synthesis — the two tables and the recommendation — is never delegated.

One or two angles do not warrant subagents; search them directly. Firing several tool calls
at once from a single context is *not* parallelising in this sense — it saves wall-clock but
not the anchoring.

---

## The output

Two tables and a recommendation. Anything longer is a literature review, which is a
different deliverable and rarely the one wanted.

### Convergence — what everyone does

| Source | Mechanism | What is distinctive about it |
|---|---|---|

Include the link for every row. A survey whose sources cannot be re-read is a set of
assertions.

### Gaps — where they all fall short

| Gap | Consequence if you inherit it |
|---|---|

This is the table that earns the exercise. A gap shared by every implementation you found is
either a genuinely hard problem or a blind spot in the field — and either way it is the part
of your design that has to be deliberate rather than inherited.

Then: **what to take, what to diverge from, and why.** Name the divergences explicitly.
"We do X differently from everyone because Y" is a design decision; silently doing X
differently is an accident waiting to be discovered by a user.

---

## Traps

- **Adopting the popular design because it is popular.** Convergence across implementations
  is evidence that something works, not evidence that it is best — and sometimes it is only
  evidence that they all copied each other. Ask what would have to be true for the consensus
  to be wrong.
- **Mistaking confidence for evidence.** A blog post claiming a 300% improvement is a claim.
  Note the number *and* that it is unverified; do not launder it into a fact by restating it
  without the source.
- **Copying an implementation whose constraints differ from yours.** Scale, hardware, team
  size and data availability change which design is correct. A design that is right at 100
  users can be wrong at one.
- **Letting the survey become the deliverable.** It is an input to a decision. If it has not
  changed the design, say so and move on — that is a legitimate outcome and it is worth one
  sentence, not another round of searching.
- **Reporting nothing found.** Finding nothing on a problem that sounds common almost always
  means the wrong vocabulary, not an empty field. Say what you searched for, so the gap in
  the search is visible rather than reported as a gap in the world.

---

## Credit

Every source that changed the design gets a link in the final write-up, and every claim
taken from one is attributed where it is used. This is not a formality — it is what lets a
later reader check whether the source actually said what the design assumes it said.

---

## Out of scope

Deciding what to build — that is [`mvp`](../mvp/SKILL.md), and this feeds its stage 1.
Deep literature review, benchmarking existing implementations, or evaluating a library for
adoption: all larger exercises that start where this one ends.

---

## Done when

Both the web and the internal sources were searched and each is labelled in the write-up,
with the subject restated as the general problem it instances for the web pass; at least two angles were searched, in
separate subagents when three or more applied, and a second round used the vocabulary the first one
taught; the convergence table has a link per row; the gaps table names what every
implementation shares as a weakness; the write-up says what to take and what to diverge from
with a reason for each divergence; unverified claims are marked as claims; and if the survey
changed nothing, that is stated rather than hidden.
