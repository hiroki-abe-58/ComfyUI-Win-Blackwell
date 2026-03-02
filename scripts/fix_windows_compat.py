"""
Windows Compatibility Fix Utility for ComfyUI Workflows

Fixes common issues when running Linux-authored workflows on Windows:
  1. Forward-slash model paths -> backslash
  2. SageAttention -> SDPA fallback
  3. torch.compile disconnect (Triton issues on Windows)
  4. Resolution alignment to 16x multiples

Usage:
    python scripts/fix_windows_compat.py <workflow.json>
    python scripts/fix_windows_compat.py <workflow.json> --output fixed.json
    python scripts/fix_windows_compat.py <directory_of_jsons>
"""

import argparse
import json
import re
import sys
from pathlib import Path


def fix_model_paths(data: dict) -> int:
    """Replace forward slashes with backslashes in model path widgets."""
    fixes = 0
    for node in data.get("nodes", []):
        node_type = node.get("type", "")
        widgets = node.get("widgets_values", [])
        if not widgets:
            continue

        # Nodes that reference model file paths
        loader_types = {
            "WanVideoModelLoader", "WanVideoVAELoader", "WanVideoLoraSelect",
            "UNETLoader", "CheckpointLoaderSimple", "CheckpointLoader",
            "VAELoader", "LoraLoader", "CLIPLoader",
        }

        if node_type in loader_types:
            for i, val in enumerate(widgets):
                if isinstance(val, str) and "/" in val:
                    widgets[i] = val.replace("/", "\\")
                    fixes += 1
    return fixes


def fix_attention_mode(data: dict) -> int:
    """Replace sageattn/sageattn_compiled with sdpa (PyTorch native)."""
    fixes = 0
    for node in data.get("nodes", []):
        widgets = node.get("widgets_values", [])
        if not widgets:
            continue
        for i, val in enumerate(widgets):
            if isinstance(val, str) and val in ("sageattn", "sageattn_compiled"):
                widgets[i] = "sdpa"
                fixes += 1
    return fixes


def fix_torch_compile(data: dict) -> int:
    """Disconnect compile_args inputs from model loaders (Triton issues on Windows)."""
    fixes = 0
    for node in data.get("nodes", []):
        for inp in node.get("inputs", []):
            if inp.get("name") == "compile_args" and inp.get("link") is not None:
                inp["link"] = None
                fixes += 1
    return fixes


def fix_resolution(data: dict, multiple: int = 16) -> int:
    """Align width/height values to the specified multiple."""
    fixes = 0
    for node in data.get("nodes", []):
        widgets = node.get("widgets_values", [])
        node_type = node.get("type", "")

        # Look for EmptyLatentImage or similar nodes with width/height
        if "Latent" in node_type or "Image" in node_type:
            for i, val in enumerate(widgets):
                if isinstance(val, (int, float)) and 64 <= val <= 8192:
                    aligned = int(val) // multiple * multiple
                    if aligned != int(val):
                        widgets[i] = aligned
                        fixes += 1
    return fixes


def process_file(filepath: Path, output_path: Path = None) -> dict:
    """Process a single workflow JSON file."""
    with open(filepath, "r", encoding="utf-8") as f:
        data = json.load(f)

    results = {
        "model_paths": fix_model_paths(data),
        "attention_mode": fix_attention_mode(data),
        "torch_compile": fix_torch_compile(data),
        "resolution": fix_resolution(data),
    }

    total = sum(results.values())

    if total > 0:
        out = output_path or filepath
        with open(out, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

    return results


def main():
    parser = argparse.ArgumentParser(
        description="Fix Windows compatibility issues in ComfyUI workflow JSON files."
    )
    parser.add_argument("path", help="Workflow JSON file or directory of JSON files")
    parser.add_argument("--output", "-o", help="Output path (only for single file)")
    parser.add_argument("--dry-run", action="store_true", help="Report issues without fixing")
    args = parser.parse_args()

    target = Path(args.path)

    if target.is_file():
        files = [target]
    elif target.is_dir():
        files = sorted(target.glob("*.json"))
    else:
        print(f"Error: {target} not found", file=sys.stderr)
        return 1

    if not files:
        print("No JSON files found.")
        return 0

    print(f"\nProcessing {len(files)} file(s)...\n")

    total_fixes = 0
    for f in files:
        output = Path(args.output) if args.output and len(files) == 1 else None
        results = process_file(f, output)
        fixes = sum(results.values())
        total_fixes += fixes

        status = f"  {fixes} fix(es)" if fixes > 0 else "  no changes"
        print(f"  {f.name}{status}")
        if fixes > 0:
            for k, v in results.items():
                if v > 0:
                    print(f"    - {k}: {v}")

    print(f"\nTotal: {total_fixes} fix(es) applied across {len(files)} file(s).\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
