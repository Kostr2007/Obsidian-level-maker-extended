#!/usr/bin/env python3
"""Validate the agent design-QA scaffolding without requiring Codex/Qt."""
from pathlib import Path
import json
import sys
import tomllib

ROOT = Path(__file__).resolve().parents[2]
config_path = ROOT / ".codex/config.toml"
errors = []
try:
    config = tomllib.loads(config_path.read_text())
    roles = config.get("agents", {})
    expected = {"apple_researcher":"high", "ui_builder":"medium",
                "visual_critic":"high", "art_director":"high",
                "functional_tester":"medium", "accessibility_critic":"medium"}
    if config.get("model_reasoning_effort") != "ultra":
        errors.append("coordinator model_reasoning_effort must request ultra")
    for name in sorted(expected):
        cfg = roles.get(name)
        if not isinstance(cfg, dict):
            errors.append(f"missing role: {name}")
            continue
        p = config_path.parent / cfg.get("config_file", "")
        if not p.is_file():
            errors.append(f"missing role config: {p}")
            continue
        role = tomllib.loads(p.read_text())
        if role.get("model_reasoning_effort") != expected[name]:
            errors.append(f"unexpected role effort: {name}; expected {expected[name]}")
        if role.get("model") in {"low","medium","high","xhigh","ultra"}:
            errors.append(f"reasoning level used as a model name: {name}")
        if not role.get("developer_instructions"):
            errors.append(f"missing instructions: {name}")
    mf = ROOT / "docs/design-system/references/apple/manifest.json"
    entries = json.loads(mf.read_text())["entries"]
    if len(entries) < 10: errors.append("reference catalog too small")
    for item in entries:
        if not item.get("url", "").startswith("https://"): errors.append(f"invalid source URL: {item.get('id')}")
        if item.get("local_image") is not None and not (ROOT/item["local_image"]).is_file():
            errors.append(f"missing local reference: {item['id']}")
    for p in ["AGENTS.md","docs/design-system/README.md","docs/design-system/APPLE_RESEARCH.md","docs/design-system/WORKFLOW.md","docs/design-system/REVIEW_CHECKLIST.md","docs/design-system/reports/TEMPLATE.md","docs/design-system/references/obsidian/README.md"]:
        if not (ROOT/p).is_file(): errors.append(f"missing: {p}")
except Exception as exc:
    errors.append(f"setup parse error: {exc}")
if errors:
    print("FAIL: " + "\nFAIL: ".join(errors))
    sys.exit(1)
print(f"PASS: {len(expected)} agent roles, {len(entries)} external reference entries and documentation scaffolding")
print("NOTE: this does not execute Codex agents, Qt tests, browser checks or visual review.")
