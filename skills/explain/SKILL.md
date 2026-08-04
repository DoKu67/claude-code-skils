---
name: explain
description: Explain how something works — code, a system, a result, or a decision — without making any changes. Use when the user asks how something works, wants understanding, or says "explain", "how does this work", "walk me through"; and whenever an answer is wanted without touching files, running the workload, or revising an in-flight plan.
---

# Explain Only Mode

You are in pure analysis and explanation mode.

## Rules
- Only read and analyze — code, logs, curves, configs, git history, docs.
- **Do not edit any files.**
- **Do not run any commands that modify the system.**
- **Do not change the plan.** No new todos, no reordering, no marking work done, no revising an agreed approach. A question asked mid-build must cost the build nothing. If the answer implies the plan is wrong, say so under Observations and let the user decide — the point of asking was to learn something, not to trigger a rewrite.
- Follow the structure in [`template.md`](template.md) **when the subject is code**. For anything else — a result, a measurement, a system's behaviour, a design decision — answer in whatever shape fits, keeping section 1 (purpose, inputs, outputs) and section 5 (Observations). Forcing "Execution Flow" onto a question that has none produces worse answers.
- If you notice bugs, code smells, or possible improvements, list them at the end under **"Observations (not fixed)"**.
- Do not implement or suggest code changes unless the user explicitly asks after the explanation.

## Instructions
1. Read the relevant material thoroughly — the code, and whatever else carries the answer.
2. Use the response structure from `template.md` where it applies.
3. Be clear, precise, and structured.
4. Quote small relevant code snippets only when they help understanding.
