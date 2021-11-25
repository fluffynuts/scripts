import subprocess
import os


def play_pause():
    file_path = os.path.realpath(__file__)
    containing_dir = os.path.dirname(file_path)
    aud_tool = os.path.join(containing_dir, "audtool.exe")

    if !os.path.isfile(aud_tool):
        print("please copy this script into the folder containing audtool.exe")
        exit(1)

    status = fetch_status(aud_tool)
    if status == "stopped" or status == "paused":
        subprocess.check_output([ aud_tool, "--playback-play" ])
    elif status == "playing":
        subprocess.check_output([ aud_tool, "--playback-pause" ])
    next_status = fetch_status(aud_tool)
    print("%s -> %s" % (status, next_status))

def fetch_status(aud_tool):
    byte_string = subprocess.check_output([ aud_tool, "--playback-status"])
    raw_string = byte_string.decode().strip()
    return raw_string


if __name__ == "__main__":
    play_pause()
