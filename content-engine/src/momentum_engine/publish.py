from __future__ import annotations

import argparse
import json
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

REQUIRED_FIELDS = {"id", "topic", "type", "title", "body", "takeaway"}
TOPICS = {"dsa", "functional", "codeCraft"}
TYPES = {"concept", "quiz", "codeTip", "bugHunt"}
INTERACTIVE_TYPES = {"quiz", "bugHunt"}


def load_json(path: Path) -> Any:
    with path.open(encoding="utf-8") as file:
        return json.load(file)


def write_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as file:
        json.dump(value, file, indent=2, ensure_ascii=False)
        file.write("\n")


def validate_card(card: dict[str, Any]) -> None:
    missing = REQUIRED_FIELDS - card.keys()
    if missing:
        raise ValueError(f"{card.get('id', '<unknown>')}: missing {sorted(missing)}")
    if card["topic"] not in TOPICS:
        raise ValueError(f"{card['id']}: invalid topic {card['topic']!r}")
    if card["type"] not in TYPES:
        raise ValueError(f"{card['id']}: invalid type {card['type']!r}")
    if card["type"] in INTERACTIVE_TYPES:
        options = card.get("options")
        correct = card.get("correctOptionIndex")
        if not isinstance(options, list) or len(options) < 2:
            raise ValueError(f"{card['id']}: interactive card needs 2+ options")
        if not isinstance(correct, int) or not 0 <= correct < len(options):
            raise ValueError(f"{card['id']}: correctOptionIndex is out of range")


def existing_card_ids(catalog: Path, manifest: dict[str, Any]) -> set[str]:
    existing: set[str] = set()
    for batch in manifest.get("batches", []):
        path = catalog / batch["path"]
        if not path.exists():
            raise ValueError(f"Manifest references missing batch: {path}")
        for card in load_json(path):
            existing.add(card["id"])
    return existing


def next_batch_number(manifest: dict[str, Any]) -> int:
    numbers = [
        int(batch["id"])
        for batch in manifest.get("batches", [])
        if str(batch["id"]).isdigit()
    ]
    return max(numbers, default=0) + 1


def publish(input_path: Path, catalog: Path, weekly_limit: int) -> int:
    manifest_path = catalog / "manifest.json"
    manifest = (
        load_json(manifest_path)
        if manifest_path.exists()
        else {
            "version": 0,
            "generatedAt": "",
            "batchSize": 10,
            "dailyCap": 50,
            "minPrefetchUnseen": 20,
            "batches": [],
        }
    )
    batch_size = int(manifest.get("batchSize", 10))
    cards = load_json(input_path)
    if not isinstance(cards, list):
        raise ValueError("Input must be a JSON array of cards")

    seen_input: set[str] = set()
    for card in cards:
        validate_card(card)
        if card["id"] in seen_input:
            raise ValueError(f"Duplicate input id: {card['id']}")
        seen_input.add(card["id"])

    existing = existing_card_ids(catalog, manifest)
    pending = [card for card in cards if card["id"] not in existing][:weekly_limit]
    if not pending:
        print("No unpublished cards.")
        return 0
    if len(pending) % batch_size:
        raise ValueError(
            f"Pending card count ({len(pending)}) must be divisible by "
            f"batchSize ({batch_size})"
        )

    number = next_batch_number(manifest)
    for offset in range(0, len(pending), batch_size):
        batch_cards = pending[offset : offset + batch_size]
        batch_id = f"{number:04d}"
        relative_path = f"batches/{batch_id}.json"
        write_json(catalog / relative_path, batch_cards)
        manifest["batches"].append(
            {
                "id": batch_id,
                "path": relative_path,
                "cardCount": len(batch_cards),
            }
        )
        number += 1

    manifest["version"] = int(manifest.get("version", 0)) + 1
    manifest["generatedAt"] = datetime.now(UTC).isoformat().replace("+00:00", "Z")
    write_json(manifest_path, manifest)
    print(f"Published {len(pending)} cards in {len(pending) // batch_size} batches.")
    return len(pending)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Validate and append Momentum cards to a catalog."
    )
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--catalog", type=Path, required=True)
    parser.add_argument("--weekly-limit", type=int, default=350)
    args = parser.parse_args()
    publish(args.input, args.catalog, args.weekly_limit)


if __name__ == "__main__":
    main()
