# Report format

`compare.py` writes the markdown report and the machine-readable matrix. Do not rewrite its numbers
in prose — restate the top findings and add the judgment the script cannot make.

## Sections

1. **Verdict** — counts of `parity` / `deviation` / `gap` / `unknown` over criterion-by-platform
   cells, plus finding counts for the axes outside the feature matrix. The two do not agree by
   design; the report says so.
2. **Matrix** — one row per criterion, one column per platform.
3. **Backlog** — findings, most severe first, each with where it lives and its next command.
4. **Axis summaries** — the raw per-axis JSON, so any number in the prose can be traced.

## Severity order

```
unknown·contract  →  unknown·logic  →  unknown·strings/telemetry
  →  gap·logic  →  gap·tests  →  gap·ci  →  gap·capabilities  →  gap·strings/telemetry
```

`unknown` outranks every gap because debt has been priced and a question has not been asked.
Business logic outranks tests because untested working behaviour still works; missing behaviour does
not. CI outranks resources because a missing pipeline step is where a human forgets under pressure.

## Scores

Report the score as a trend and say what it is not. A score is not a target: a mature pair has
deviations, and driving the number to 100% means either the deviations were laundered into parity or
the contract stopped describing the apps. `deviation` is as healthy as `parity`.

## Where reports go

`parity-reports/<YYYY-MM-DD>-audit.md` beside the repos, or at the workspace root when there is one.
Reports are output, not contract: they are never mirrored into the repos and never locked.

## In chat

Lead with the count of `unknown` findings, then the highest-severity gap and its next command.
Do not paste the matrix. The report file is the artifact; chat is the summary.
