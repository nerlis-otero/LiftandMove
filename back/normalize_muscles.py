#!/usr/bin/env python3
"""Unifica primaryMuscles y secondaryMuscles de exercises.json al español canónico."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent
EXERCISES_PATH = ROOT / "exercises.json"
CANONICAL_PATH = ROOT / "canonical_muscles.json"


def load_canonical() -> tuple[set[str], dict[str, str]]:
    data = json.loads(CANONICAL_PATH.read_text(encoding="utf-8"))
    canonical = set(data["canonical"])
    aliases: dict[str, str] = {**data["aliases"]}
    for name in canonical:
        aliases.setdefault(name, name)
    return canonical, aliases


def normalize_list(muscles: list[str], aliases: dict[str, str]) -> tuple[list[str], list[str]]:
    """Devuelve (lista normalizada, alias desconocidos)."""
    unknown: list[str] = []
    seen: set[str] = set()
    result: list[str] = []

    for muscle in muscles:
        key = muscle.strip()
        if key not in aliases:
            unknown.append(key)
            normalized = key
        else:
            normalized = aliases[key]

        if normalized not in seen:
            seen.add(normalized)
            result.append(normalized)

    return result, unknown


def normalize_exercises(
    exercises: list[dict],
    aliases: dict[str, str],
) -> tuple[list[dict], dict[str, int]]:
    changes: dict[str, int] = {}

    for exercise in exercises:
        for field in ("primaryMuscles", "secondaryMuscles"):
            if field not in exercise:
                continue
            original = exercise[field]
            normalized, _ = normalize_list(original, aliases)
            if normalized != original:
                for old, new in zip(original, normalized):
                    if old != new:
                        changes[f"{old} → {new}"] = changes.get(f"{old} → {new}", 0) + 1
                exercise[field] = normalized

    return exercises, changes


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Solo muestra estadísticas sin escribir exercises.json",
    )
    parser.add_argument(
        "--input",
        type=Path,
        default=EXERCISES_PATH,
        help="Ruta al JSON de ejercicios",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Ruta de salida (por defecto sobrescribe --input)",
    )
    args = parser.parse_args()

    canonical, aliases = load_canonical()
    exercises = json.loads(args.input.read_text(encoding="utf-8"))

    all_unknown: set[str] = set()
    for exercise in exercises:
        for field in ("primaryMuscles", "secondaryMuscles"):
            for muscle in exercise.get(field, []):
                key = muscle.strip()
                if key not in aliases and key not in canonical:
                    all_unknown.add(key)

    exercises, _ = normalize_exercises(exercises, aliases)

    primary = {m for e in exercises for m in e.get("primaryMuscles", [])}
    secondary = {m for e in exercises for m in e.get("secondaryMuscles", [])}

    print(f"Ejercicios: {len(exercises)}")
    print(f"Primary únicos: {len(primary)}")
    print(f"Secondary únicos: {len(secondary)}")
    print("\nPrimary canónicos:")
    for name in sorted(primary):
        print(f"  - {name}")
    if all_unknown:
        print("\n⚠ Sin mapeo (revisar canonical_muscles.json):")
        for name in sorted(all_unknown):
            print(f"  - {name}")

    output = args.output or args.input
    if args.dry_run:
        print("\n(dry-run: no se escribió el archivo)")
        return

    output.write_text(
        json.dumps(exercises, ensure_ascii=False, indent=4) + "\n",
        encoding="utf-8",
    )
    print(f"\nGuardado: {output}")


if __name__ == "__main__":
    main()
