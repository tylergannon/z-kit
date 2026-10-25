#!/usr/bin/env python3
"""Run the small configuration experiment with an explicit Zig 0.17 compiler."""
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent
LOCAL = ROOT / ".local"
COMPILER = Path(os.environ.get("ZIG017_EXE", LOCAL / "zig-aarch64-macos-0.17.0/zig")).resolve()
ARCHIVE = LOCAL / "zig-aarch64-macos-0.17.0.tar.xz"
EXPECTED_HASH = "b607e9b9234790a008116ae5bdb71c6243b84b9fb42a53a9e70fde41c06c536a"
LOGS = LOCAL / "results"
LOGS.mkdir(parents=True, exist_ok=True)
env = os.environ | {"ZIG_GLOBAL_CACHE_DIR": str(LOCAL / "global-cache")}
version = subprocess.check_output([str(COMPILER), "version"], text=True).strip()
assert version == "0.17.0", f"Expected Zig 0.17.0; found {version}"
archive_hash = hashlib.sha256(ARCHIVE.read_bytes()).hexdigest() if ARCHIVE.exists() else None
if archive_hash is not None:
    assert archive_hash == EXPECTED_HASH, "Compiler archive hash mismatch"

cases = [
    ("shape_test.zig", True, ["All 13 tests passed."]),
    ("comptime_test.zig", True, []),
    ("negative_unknown_field.zig", False, ["no field named 'owenr'"]),
    ("negative_unknown_option.zig", False, ["no field named 'requried'"]),
    ("negative_wrong_value.zig", False, ["expected type '?bool'"]),
    ("negative_nonoptional.zig", False, ["required override requires an optional field"]),
    ("negative_wrong_owner.zig", False, ["expected type 'projector.Projection", "found 'projector.Projection"]),
    ("negative_nonstruct.zig", False, ["Projection expects a struct type"]),
    ("negative_array_duplicate.zig", False, ["duplicate field entry: owner"]),
    ("negative_array_field.zig", False, ["has no member named 'owenr'"]),
    ("negative_inferred_literal.zig", False, ["expected type 'projector.Projection", "projection__struct_"]),
    ("negative_namespace_collision.zig", False, ["duplicate struct member name 'projection'"]),
    ("negative_runtime_metadata.zig", False, ["unable to evaluate comptime expression", "initializer of container-level variable must be comptime-known"]),
]
results = []
for filename, positive, expected in cases:
    command = [str(COMPILER), "test", filename, "--cache-dir", str(LOCAL / "local-cache")]
    if not positive or filename == "comptime_test.zig":
        command += ["-fno-emit-bin"]
    process = subprocess.run(command, cwd=ROOT, env=env, text=True, capture_output=True)
    (LOGS / (filename + ".stdout")).write_text(process.stdout)
    (LOGS / (filename + ".stderr")).write_text(process.stderr)
    output = process.stdout + process.stderr
    passed = (process.returncode == 0) == positive and all(s in output for s in expected)
    expected_result = "compile-time assertions without executable" if filename == "comptime_test.zig" else "success" if positive else "compile error"
    results.append({"source": filename, "expected": expected_result,
                    "exit_code": process.returncode, "expected_fragments": expected, "passed": passed})
    print(f"{'PASS' if passed else 'FAIL'} {filename}")
    if not passed:
        print(output)

build_command = [str(COMPILER), "build", "test", "--summary", "all",
                 "--cache-dir", str(LOCAL / "build-cache"), "--prefix", str(LOCAL / "install")]
build = subprocess.run(build_command, cwd=ROOT, env=env, text=True, capture_output=True)
(LOGS / "module-build.stdout").write_text(build.stdout)
(LOGS / "module-build.stderr").write_text(build.stderr)
build_passed = build.returncode == 0 and "3/3 steps succeeded" in build.stdout + build.stderr
results.append({"source": "build.zig", "expected": "module integration success",
                "exit_code": build.returncode, "expected_fragments": ["3/3 steps succeeded"],
                "execution": "cached" if "run test cached" in build.stdout + build.stderr else "ran",
                "passed": build_passed})
print(f"{'PASS' if build_passed else 'FAIL'} module build")
if not build_passed:
    print(build.stdout + build.stderr)

local_compiler = COMPILER == (LOCAL / "zig-aarch64-macos-0.17.0/zig").resolve()
source_hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest()
                 for p in sorted(ROOT.glob("*.zig"))}
source_hashes["run.py"] = hashlib.sha256(Path(__file__).read_bytes()).hexdigest()
summary = {"compiler": version,
           "compiler_origin": "local verified release archive" if local_compiler else "externally supplied executable; version checked",
           "compiler_archive_sha256": archive_hash if local_compiler else None,
           "source_pin": "7647adab80dd088f4de3610fd245915a912eb6ad",
           "scope": "Configuration type synthesis, discovery and diagnostics; no mapping/codec/backend implementation.",
           "positive_tests": 13, "module_tests": 1, "explicit_comptime_compilations": 1,
           "source_sha256": source_hashes,
           "cases": results, "passed": all(r["passed"] for r in results)}
(ROOT / "results.json").write_text(json.dumps(summary, indent=2) + "\n")
raise SystemExit(0 if summary["passed"] else 1)
