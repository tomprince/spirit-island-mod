import json
from pathlib import Path

import attr


@attr.s(auto_attribs=True)
class Config:
    savegame: Path
    unpacked_savegame: Path
    global_script: Path
    script_state: Path
    note: Path
    objects: Path
    xml_ui: Path


config = Config(
    savegame=Path("built/savegame.json"),
    unpacked_savegame=Path("unpacked-savegame.json"),
    global_script=Path("global-script.lua"),
    script_state=Path("script-state.json"),
    note=Path("note.txt"),
    xml_ui=Path("ui.xml"),
    objects=Path('objects')
)


def format_json(value):
    return json.dumps(value, indent=2, separators=(",", ": "))
