# Design Patterns

## Announce before you apply

Reaching this file is itself a reportable event. Before writing any code that introduces a pattern, tell the user in plain text:

1. **That you are consulting this reference** — name it, so the user knows a lock-in decision is being made rather than ordinary implementation.
2. **The module**, and the stage evidence that it is locked-in — which two changes its interface survived.
3. **The friction** you have, in the user's own terms, before naming any pattern.
4. **The pattern** you propose, and the cost from its entry below that you are accepting.
5. **What happens if you skip it** — the shape the code takes with no pattern at all.

Then wait for the user's go-ahead. A pattern applied silently is indistinguishable from a pattern applied prematurely, and this repo's standards treat premature abstraction as the more expensive error.

State each of the five even when a pattern seems obvious. Where several modules need patterns, report them one at a time — a batched list invites approval of the set rather than the choice.

**Done when:** the user has agreed to a named pattern for a named module, or has said to leave it as it is.

---

Reference for the *locked-in* stage only. A pattern introduced while the shape of the solution is still moving is a guess that every caller then has to honour.

Read this when you already have working code, an interface that has stopped moving, and a specific friction you can name. Entries are indexed by that friction, not by pattern name — if you can't find your friction below, you don't need a pattern yet.

Most interchangeability problems are solved by the composition rules in `CODING_STANDARDS.md` — inject the collaborator, keep the interface narrow — without naming a pattern at all. Reach here when composition alone leaves something awkward.

## Contents

- [Choosing an implementation at runtime](#choosing-an-implementation-at-runtime) — Strategy, Factory, Abstract Factory, Registry
- [Constructing something complicated](#constructing-something-complicated) — Builder
- [Making an outside thing fit your interface](#making-an-outside-thing-fit-your-interface) — Adapter, Facade
- [Adding behaviour without editing the thing](#adding-behaviour-without-editing-the-thing) — Decorator
- [Reacting to something happening](#reacting-to-something-happening) — Observer / pub-sub
- [Wiring the whole program together](#wiring-the-whole-program-together) — Dependency injection, Composition root
- [Patterns to avoid](#patterns-to-avoid) — Singleton, and the general trap

---

## Choosing an implementation at runtime

**Signal:** a config value selects between several components that do the same job — three optimizers, four data sources, two reward functions.

**Strategy** — the plain answer, and usually sufficient. Define the interface, write each variant as a class or function satisfying it, pass the chosen one in. No indirection beyond the interface itself.
*Cost:* almost none. Start here.

**Factory** — a single function mapping a config value to a constructed component. Add it when construction takes more than naming the class: reading extra config, ordering setup steps, validating combinations.
*Cost:* one more place to look when tracing what got built. Worth it once the mapping is more than a dictionary lookup.

**Abstract Factory** — a factory producing a *family* of components that must agree with each other. The real signal is a compatibility constraint: this tokenizer must match that model; this env wrapper must match that observation space. It exists to make mismatched combinations unconstructable.
*Cost:* significant structure. If your variants don't have to agree with each other, you want Factory, not this.

**Registry** — components register themselves under a name at import, and the factory looks them up. Buys extensibility without editing a central list.
*Cost:* the mapping becomes invisible — you can no longer read one file to know what's available, and import order starts to matter. Adopt only when adding variants without touching shared code is a genuine requirement, not a nicety.

## Constructing something complicated

**Builder** — step-by-step construction where the steps vary and the result is validated at the end.

**Signal:** a constructor with many optional parameters, or several near-identical construction sequences that differ in the middle. Not "this object takes eight arguments" — that's usually a Data Clump wanting to become a type.
*Cost:* two things to keep in sync. If a typed config object and a plain constructor would do, they usually do.

## Making an outside thing fit your interface

**Adapter** — wrap a third-party or legacy component so it satisfies *your* interface rather than leaking its own.

**Signal:** a vendor SDK's vocabulary appearing in your domain code, or a swap between two providers touching many files. The adapter is also the seam you fake in tests, which is often the stronger reason to build it.
*Cost:* one thin layer. This is among the highest-value patterns here and the one most often skipped.

**Facade** — one narrow entry point over a subsystem with many parts. Same idea, aimed inward: it's how a package presents a small public surface over a lot of internals.

## Adding behaviour without editing the thing

**Decorator** — wrap a component in something satisfying the same interface, adding behaviour around it.

**Signal:** a cross-cutting concern — caching, retries, timing, rate limiting, logging — that you want on several components and don't want written into any of them. Composes naturally: decorators stack.
*Cost:* stack traces get deeper and the order of wrapping becomes load-bearing. Keep each decorator to one concern.

## Reacting to something happening

**Observer / pub-sub** — a producer emits events; subscribers react without the producer knowing they exist.

**Signal:** several unrelated things must happen on one occurrence — a training step finishing should update metrics, checkpoint, and maybe stop early — and the producer shouldn't accumulate knowledge of all of them.
*Cost:* the highest debuggability cost in this document. Control flow stops being readable from the call site, and "what actually ran" becomes a runtime question. Use it where the set of reactions is genuinely open; where it's fixed and small, an explicit list of callbacks is easier to follow and easier to test.

## Wiring the whole program together

**Dependency injection** — components receive collaborators rather than constructing them. Already a Should-fix rule in the standards; listed here because it's the pattern the rest depend on.

**Composition root** — one place, near the entry point, where the config is read and the object graph is assembled. Everything below it receives what it needs and constructs nothing global.

**Signal:** you want to know what the program is actually made of by reading one file. Also the natural home for the factories above.
*Cost:* the entry point gets longer. That's the right place for it to be long.

## Patterns to avoid

**Singleton.** It reintroduces global mutable state: it breaks reproducibility (hidden state survives between runs), test isolation (tests leak into each other), and parallelism (shared instance across workers). If exactly one instance is wanted, construct one at the composition root and inject it — you get "one instance" without the global.

**The general trap.** Reaching for a pattern because the code feels unstructured, rather than because a named friction exists. The result reads as sophisticated and debugs as indirection: three files to trace one call, an interface with one implementation, a factory that returns the only thing it can return. When you can't name what the pattern is buying, the answer is that it isn't.
