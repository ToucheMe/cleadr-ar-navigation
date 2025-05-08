1. Extracting Frames:
/frames
/videos
extract_frames.py

- Place a video in the same directory (e.g. A.mp4)
- Edit the target_directory variable in extract_frames.py (e.g. target_directory = "A")
- Run extract_frames.py
- A folder (e.g. A) is produced containing all the video frames
- Put A.mp4 into "videos", A folder into "frames"

2. Annotating Frames:
/1
/2
/3
/4
/5
...
perform_annotation.py

- Place the video frames folder (e.g. A) from "frames" in the same directory
- Edit the SOURCE_FOLDER variable in extract_frames.py (e.g. SOURCE_FOLDER = "A")
* Delete progress.json if you want to start over
- Folders of 1 to 5 are created and categorised / annotated accordingly
* Folders must be in numbers form only

# You have categorised / annotated and prepared the dataset, next is to create the /train, /val, /test, and labels.json with current_lane.ipynb #