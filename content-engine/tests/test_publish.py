import json
import tempfile
import unittest
from pathlib import Path

from momentum_engine.publish import publish


class PublishTest(unittest.TestCase):
    def test_publishes_ten_cards_and_updates_manifest(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            input_path = root / "cards.json"
            catalog = root / "catalog"
            cards = [
                {
                    "id": f"card-{index}",
                    "topic": "dsa",
                    "type": "concept",
                    "title": f"Card {index}",
                    "body": "Body",
                    "takeaway": "Takeaway",
                }
                for index in range(10)
            ]
            input_path.write_text(json.dumps(cards), encoding="utf-8")

            count = publish(input_path, catalog, 350)

            manifest = json.loads(
                (catalog / "manifest.json").read_text(encoding="utf-8")
            )
            self.assertEqual(count, 10)
            self.assertEqual(manifest["version"], 1)
            self.assertEqual(manifest["batches"][0]["cardCount"], 10)
            self.assertTrue((catalog / "batches/0001.json").exists())


if __name__ == "__main__":
    unittest.main()
