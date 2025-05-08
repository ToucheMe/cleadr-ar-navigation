import cv2
import os

target_directory = "A"

def extract_frames(video_path, output_folder, frame_interval=1):
    """
    Extracts frames from a video and saves them as images.

    :param video_path: Path to the input video file.
    :param output_folder: Directory to save extracted frames.
    :param frame_interval: Extract one frame every 'frame_interval' frames.
    """
    # Create output folder if it doesn't exist
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    # Open the video file
    cap = cv2.VideoCapture(video_path)

    if not cap.isOpened():
        print("Error: Could not open video file.")
        return

    frame_count = 0
    saved_count = 0

    while True:
        ret, frame = cap.read()
        if not ret:
            break  # Break the loop if no more frames

        # Save frame at the specified interval
        if frame_count % frame_interval == 0:
            frame_filename = os.path.join(output_folder, f"{target_directory}_frame_{saved_count:06d}.jpg")
            cv2.imwrite(frame_filename, frame)
            print(f"Saved: {frame_filename}")
            saved_count += 1

        frame_count += 1

    cap.release()
    print(f"Extraction completed. {saved_count} frames saved.")

# Example usage
video_file = f"{target_directory}.mp4"  # Change to your video file path
output_directory = target_directory
frame_step = 10  # Extract every 10th frame

extract_frames(video_file, output_directory, frame_step)
