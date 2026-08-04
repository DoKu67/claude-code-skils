---
id: new-skill-needs-an-inbound-caller
target: codify
kind: rule
signal: explicit
status: staged
occurrences: 1
threshold: 1
---

**Rule:** A new skill is not promoted until at least one existing skill names and links it
at the moment it fires — or the promotion records, explicitly, that it is user-invoked only.
A skill nothing calls is a skill that will not run, and its own `description` is not a
sufficient caller.

**Prediction:** If this fires, new skills stop being promoted with zero inbound references,
and the "never fired" count stops growing.
**Falsified if:** the pointer is added and the invocation count stays 0 (which would mean the
host skill is not loading either), or the requirement blocks a skill that genuinely has no
caller and is fine that way.

**Occurrences**
- 2026-08-04 · session 33c950a9 · explicit · "there semeed to be an issue with naming skills
  directly within other skills, and that this was not being done, how can we enforce this?"
  Asked directly as a request for enforcement, after the same defect was found four times in
  one session: `consistency` (unnamed by `mvp` and `tune-loop`), `prior-work` (unnamed by
  `mvp`), and `tune-report` (whose five sections `tune-loop` describes inline at Stopping
  without naming the skill).

**Evidence at staging time.** Three of the last four new-skill promotions had zero inbound
links and zero invocations across 83 transcripts: `consistency`, `prior-work`,
`checkpoint-commits`. All three were promoted on direct request, which the threshold rules
treat as needing no validation — so nothing checked whether anything would ever call them.

**Why the obvious enforcement does not work.** A static check for "mentions a skill without
linking it" was written and run against the whole skill set during this session. It found 9
hits, all of them worked examples and sample output — zero real defects. The actual failure
is the *absence* of a mention, which no grep can detect. Enforcement has to happen at
authoring time, in `codify`, not as a lint pass. See [[orphan-skill-finding]] for the
detection half, which works on invocation counts rather than on text.

**Relationship to the rejected [[load-companion-skill-at-its-trigger]].** Not a re-proposal.
That candidate placed the duty on the model at runtime — *load the companion when a skill
names one* — and was rejected as self-falsifying. This one places the duty on the author at
promotion time, and applies to the case that candidate did not cover: the companion is never
named at all. The rejection stands.
