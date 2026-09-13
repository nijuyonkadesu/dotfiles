#!/usr/bin/env python3
import subprocess, time, json, hashlib, base64, websocket

OBS_PASSWORD = "MdwShpvLgi54ULOA"
OBS_PORT = 4455
BOUNDARY_X = 1920
POLL_INTERVAL = 0.3
SCENE_NAME = "Scene"
SOURCE_EXTERNAL = "autofocus external"
SOURCE_INBUILT = "autofocus inbuilt"

with open("/tmp/cursor_pos.js", "w") as f:
    f.write('console.error(workspace.cursorPos.x + " " + workspace.cursorPos.y)\n')

def get_cursor_x():
    sid = subprocess.check_output([
        "qdbus6", "org.kde.KWin", "/Scripting",
        "org.kde.kwin.Scripting.loadScript", "/tmp/cursor_pos.js"
    ]).decode().strip()
    subprocess.call(
        ["qdbus6", "org.kde.KWin", f"/Scripting/Script{sid}", "org.kde.kwin.Script.run"],
        stderr=subprocess.DEVNULL
    )
    subprocess.call(
        ["qdbus6", "org.kde.KWin", "/Scripting", "org.kde.kwin.Scripting.unloadScript", "/tmp/cursor_pos.js"],
        stderr=subprocess.DEVNULL
    )
    out = subprocess.check_output([
        "journalctl", "--user", "-n", "3", "--no-pager", "-o", "cat"
    ]).decode()
    for line in reversed(out.strip().splitlines()):
        parts = line.strip().split()
        if len(parts) == 2:
            try:
                return int(float(parts[0]))
            except ValueError:
                continue
    return 0

def send(ws, payload):
    ws.send(json.dumps(payload))

def recv_response(ws):
    while True:
        msg = json.loads(ws.recv())
        if msg["op"] == 7:
            return msg

def authenticate(ws):
    msg = json.loads(ws.recv())
    salt = msg["d"]["authentication"]["salt"]
    challenge = msg["d"]["authentication"]["challenge"]
    secret = base64.b64encode(
        hashlib.sha256((OBS_PASSWORD + salt).encode()).digest()
    ).decode()
    auth = base64.b64encode(
        hashlib.sha256((secret + challenge).encode()).digest()
    ).decode()
    send(ws, {"op": 1, "d": {"rpcVersion": 1, "authentication": auth}})
    ws.recv()

def get_item_id(ws, scene, source_name):
    send(ws, {"op": 6, "d": {
        "requestType": "GetSceneItemId",
        "requestId": "gid",
        "requestData": {"sceneName": scene, "sourceName": source_name}
    }})
    resp = recv_response(ws)
    return resp["d"]["responseData"]["sceneItemId"]

def set_visible(ws, scene, item_id, visible):
    send(ws, {"op": 6, "d": {
        "requestType": "SetSceneItemEnabled",
        "requestId": "sie",
        "requestData": {
            "sceneName": scene,
            "sceneItemId": item_id,
            "sceneItemEnabled": visible
        }
    }})
    recv_response(ws)

def main():
    ws = websocket.WebSocket()
    ws.connect(f"ws://localhost:{OBS_PORT}")
    authenticate(ws)
    print("Connected to OBS")

    id_external = get_item_id(ws, SCENE_NAME, SOURCE_EXTERNAL)
    id_inbuilt = get_item_id(ws, SCENE_NAME, SOURCE_INBUILT)
    print(f"Source IDs — external: {id_external}, inbuilt: {id_inbuilt}")

    last_state = None

    while True:
        try:
            x = get_cursor_x()
            # external on right, inbuilt on left (<1920)
            on_external = x > BOUNDARY_X

            if on_external != last_state:
                print(f"→ {'external' if on_external else 'inbuilt'} (x={x})")
                set_visible(ws, SCENE_NAME, id_external, on_external)
                set_visible(ws, SCENE_NAME, id_inbuilt, not on_external)
                last_state = on_external

        except Exception as e:
            print(f"Error: {e}")

        time.sleep(POLL_INTERVAL)

if __name__ == "__main__":
    main()
