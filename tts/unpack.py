import json

from tts import config, format_json


def to_unix(text):
    return text.replace("\r\n", "\n")


game = json.loads(config.savegame.read_text())

global_script = to_unix(game.pop("LuaScript"))
config.global_script.write_text(global_script)

script_state = json.loads(game.pop("LuaScriptState"))
config.script_state.write_text(format_json(script_state))

note = game.pop("Note")
config.note.write_text(note)

xml_ui = to_unix(game.pop("XmlUI"))
config.xml_ui.write_text(xml_ui)


def unpack_objects(objects, base_path):
    for obj in objects:
        path = base_path.joinpath(obj.pop("GUID"))
        path.mkdir(parents=True, exist_ok=True)
        obj_script = obj.pop("LuaScript")
        script_path = path.joinpath("script.lua")
        if obj_script.strip():
            script_path.write_text(to_unix(obj_script))
        elif script_path.exists():
            script_path.unlink()
        contained_objects = obj.pop("ContainedObjects", [])
        unpack_objects(contained_objects, path.joinpath("contained"))
        path.joinpath("object.json").write_text(format_json(obj))


unpack_objects(game.pop("ObjectStates"), config.objects)

config.unpacked_savegame.write_text(format_json(game))
