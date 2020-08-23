import json

from tts import config, format_json


def to_win(text):
    return text.replace("\n", "\r\n")


game = json.loads(config.savegame.read_text())

global_script = config.global_script.read_text()
game["LuaScript"] = to_win(global_script)

script_state = json.loads(config.script_state.read_text())
game["LuaScriptState"] = json.dumps(script_state)

note = config.note.read_text()
game["Note"] = note

xml_ui = config.xml_ui.read_text()
game["XmlUI"] = to_win(xml_ui)


def repack_objects(objects, base_path):
    for path in sorted(base_path.iterdir(), key=lambda path: int(path.name, base=16)):
        if not path.is_dir():
            raise Exception("Objects must be directories")
        obj = json.loads(path.joinpath("object.json").read_text())
        obj["GUID"] = path.name
        script_path = path.joinpath("script.lua")
        if script_path.exists():
            obj["LuaScript"] = to_win(script_path.read_text())
        else:
            obj["LuaScript"] = ""
        obj["ContainedObjects"] = []
        if path.joinpath("contained").is_dir():
            repack_objects(obj["ContainedObjects"], path.joinpath("contained"))

        objects.append(obj)


game["ObjectStates"] = []
repack_objects(game["ObjectStates"], config.objects)

config.savegame.write_text(format_json(game))
