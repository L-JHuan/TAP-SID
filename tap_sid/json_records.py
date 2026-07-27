from __future__ import annotations

import json
from pathlib import Path
from typing import Any, Iterator


def iter_json_records(path: Path) -> Iterator[dict[str, Any]]:
    if not path.is_file():
        raise FileNotFoundError(path)
    with path.open("r", encoding="utf-8") as source:
        first_character = ""
        while True:
            character = source.read(1)
            if not character:
                break
            if not character.isspace():
                first_character = character
                break
        if not first_character:
            return
        source.seek(0)
        if first_character == "[":
            value = json.load(source)
            if not isinstance(value, list):
                raise ValueError(f"{path} 必须是 JSON 对象列表")
            for row in value:
                if not isinstance(row, dict):
                    raise ValueError(f"{path} 包含非对象记录")
                yield row
            return
        for line_number, line in enumerate(source, start=1):
            if not line.strip():
                continue
            row = json.loads(line)
            if not isinstance(row, dict):
                raise ValueError(f"{path}:{line_number} 包含非对象记录")
            yield row


def load_json_records(path: Path, limit: int = 0) -> list[dict[str, Any]]:
    rows: list[dict[str, Any]] = []
    for row in iter_json_records(path):
        rows.append(row)
        if limit > 0 and len(rows) >= limit:
            break
    return rows
