#!/usr/bin/env python3
"""Vocabulary-free metric checks for any run that follows the ml_logging layout.

The per-project `scripts/verify_metrics.py` knows what a project *declared* and can say "this
metric was promised and never arrived". This one knows nothing about the project, so it can
only ask questions that are true of every run — but those questions caught two of the three
real failures anyway.

Runs when a project has no verifier of its own. **A project with no verifier must not appear
verified**, so the caller reports which of the two ran.

Reads any number of `metrics.jsonl` files given as arguments. Exits non-zero on a finding.
"""

from __future__ import annotations

import json
import math
import sys
from pathlib import Path

# Below this, a "series" is too short for identical values to mean anything.
MIN_SERIES_LENGTH = 5

# Keys that are identical across names by convention in common trainers, so flagging them
# teaches people to ignore this output. Substring match, deliberately conservative.
BENIGN_SUBSTRINGS = ("rewards/", "/min_", "/max_")


def numeric_series(records: list[dict], name: str) -> list[float]:
    values = []
    for record in records:
        value = record.get(name)
        if isinstance(value, bool) or not isinstance(value, (int, float)):
            continue
        if math.isnan(value):
            continue
        values.append(float(value))
    return values


def find_step_key(records: list[dict], names: list[str]) -> str | None:
    """Any strictly non-decreasing integer series that advances is a plausible x-axis."""
    for name in names:
        if "step" not in name.lower():
            continue
        values = numeric_series(records, name)
        if len(values) >= MIN_SERIES_LENGTH and len(set(values)) > 1:
            if all(later >= earlier for earlier, later in zip(values, values[1:])):
                return name
    return None


def check_file(path: Path) -> list[str]:
    try:
        records = [json.loads(line) for line in path.read_text().splitlines() if line.strip()]
    except (OSError, json.JSONDecodeError) as error:
        return [f"{path}: unreadable — {type(error).__name__}: {error}"]
    if len(records) < MIN_SERIES_LENGTH:
        return []

    names = sorted({key for record in records for key in record if not key.startswith("_")})
    problems: list[str] = []

    # 1. An x-axis that never advances means every panel plots against a constant.
    if find_step_key(records, names) is None:
        step_like = [name for name in names if "step" in name.lower()]
        problems.append(
            f"{path.name}: no usable x-axis — "
            + (
                f"step-like keys {step_like} are constant or non-monotonic"
                if step_like
                else "no step-like metric is logged at all"
            )
        )

    # 2. Two names, one series. The only vocabulary-free handle on a metric whose name lies
    #    about what it measures, and it is what caught the real one.
    logged = [name for name in names if len(numeric_series(records, name)) >= MIN_SERIES_LENGTH]
    for index, left in enumerate(logged):
        if any(token in left for token in BENIGN_SUBSTRINGS):
            continue
        for right in logged[index + 1 :]:
            if any(token in right for token in BENIGN_SUBSTRINGS):
                continue
            left_values, right_values = numeric_series(records, left), numeric_series(records, right)
            if len(left_values) != len(right_values) or len(set(left_values)) == 1:
                continue
            if left_values == right_values:
                problems.append(
                    f"{path.name}: {left} and {right} are bit-identical across "
                    f"{len(left_values)} points — they measure one thing and one name is wrong"
                )
    return problems


def main(argv: list[str]) -> int:
    paths = [Path(arg) for arg in argv[1:]]
    if not paths:
        print("usage: verify_metrics_generic.py <metrics.jsonl> [...]", file=sys.stderr)
        return 2
    problems = [problem for path in paths for problem in check_file(path)]
    if not problems:
        return 0
    for problem in problems:
        print(f"  - {problem}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
