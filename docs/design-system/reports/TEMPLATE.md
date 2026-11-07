# Design and functionality review

- Commit: `<sha>`
- Agent: `<role>`
- Date: `YYYY-MM-DD`
- Environment: `<OS, Qt, desktop, renderer, scale>`
- Scope: `<screen/component/change>`
- Artifacts: `<actual relative screenshot/log paths>`
- HIG sources: `<exact official links actually read>`

For a new artistic experiment, assess all four current variants before the
findings. Keep historical two-option reports unchanged. Art direction may rank
acceptable variants; functional PASS is not an aesthetic ranking.

| Variant | Current screenshot/state | Verdict | Strength | Cost / limitation |
| --- | --- | --- | --- | --- |
| A — current control | `<current evidence>` | `<actual verdict>` | `<observed>` | `<observed>` |
| B | `<current evidence>` | `<actual verdict>` | `<observed>` | `<observed>` |
| C | `<current evidence>` | `<actual verdict>` | `<observed>` | `<observed>` |
| D | `<current evidence>` | `<actual verdict>` | `<observed>` | `<observed>` |

| ID | Severity | Area/state | Verdict | Evidence | Apple/project principle | Reproduction + acceptance criterion |
| --- | --- | --- | --- | --- | --- | --- |
| EX-01 | P1 | Resources/list, dark | UNVERIFIED | Screenshot missing | Project consistency | Capture and inspect current commit |

## Tests executed
```text
<exact command, exit code, log path, failing assertion or SKIPPED reason>
```

## Recommendation
`ACCEPT / CHANGES REQUESTED / BLOCKED / UNVERIFIED`

## Handoff to builder
One scoped change per finding, no speculative redesign. If accepted, explicitly say that no changes are needed.
