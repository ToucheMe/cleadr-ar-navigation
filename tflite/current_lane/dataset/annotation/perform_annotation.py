import os
import shutil
import tkinter as tk
import json
from PIL import Image, ImageTk
import re

# Constants
SOURCE_FOLDER = "A"  # Folder containing images
CATEGORIES = [str(i) for i in range(1, 6)]  # Categories 1 to 5
PROGRESS_FILE = "progress.json"  # File to save progress

# Ensure category folders exist
for category in CATEGORIES:
    os.makedirs(category, exist_ok=True)

# Function to extract numerical part of filename
def extract_number(filename):
    match = re.search(r'\d+', filename)
    return int(match.group()) if match else float('inf')

# Get list of images sorted numerically
image_files = sorted(
    [f for f in os.listdir(SOURCE_FOLDER) if f.lower().endswith(('.png', '.jpg', '.jpeg', '.gif', '.bmp'))],
    key=extract_number
)

image_index = 0  # Track current image

# Load progress if exists
if os.path.exists(PROGRESS_FILE):
    with open(PROGRESS_FILE, "r") as f:
        data = json.load(f)
        image_index = data.get("last_index", 0)

# GUI Setup
root = tk.Tk()
root.title("Image Categorization")

# Image Display
image_label = tk.Label(root)
image_label.grid(row=0, column=0, padx=20, pady=20)

# Preview Display Frame
preview_frame = tk.Frame(root)
preview_frame.grid(row=1, column=0, padx=20, pady=10)
preview_labels = [tk.Label(preview_frame) for _ in range(3)]
for i, label in enumerate(preview_labels):
    label.grid(row=0, column=i, padx=10)

# Function to display image
def show_image():
    if image_index < len(image_files):
        image_path = os.path.join(SOURCE_FOLDER, image_files[image_index])
        img = Image.open(image_path)
        img.thumbnail((1440, 1440))  # Resize for display
        img_tk = ImageTk.PhotoImage(img)
        image_label.config(image=img_tk)
        image_label.image = img_tk  # Keep reference
        show_previews()
    else:
        image_label.config(text="No more images.", font=("Arial", 16, "bold"))
        for label in preview_labels:
            label.config(image='', text='')

# Function to display next three previews
def show_previews():
    for i in range(3):
        preview_index = image_index + i + 1
        if preview_index < len(image_files):
            preview_path = os.path.join(SOURCE_FOLDER, image_files[preview_index])
            img = Image.open(preview_path)
            img.thumbnail((200, 200))  # Smaller preview size
            img_tk = ImageTk.PhotoImage(img)
            preview_labels[i].config(image=img_tk)
            preview_labels[i].image = img_tk  # Keep reference
        else:
            preview_labels[i].config(image='', text='')

# Function to categorize image
def categorize_image(category):
    global image_index
    if image_index < len(image_files):
        src_path = os.path.join(SOURCE_FOLDER, image_files[image_index])
        dst_path = os.path.join(category, image_files[image_index])
        shutil.copy(src_path, dst_path)  # Copy file

        # Save progress
        image_index += 1
        save_progress()
        show_image()  # Show next image

# Function to save progress
def save_progress():
    with open(PROGRESS_FILE, "w") as f:
        json.dump({"last_index": image_index}, f)

# Create category buttons (placed on the right)
button_frame = tk.Frame(root)
button_frame.grid(row=0, column=1, padx=30, pady=30, sticky="n")

# Button Layout
layout = [
    [1],
    [2],
    [3, 4],
    [5]
]

# Function to handle button hold
def start_categorization(category):
    root._running = True
    hold_categorization(category)

def hold_categorization(category):
    if root._running:
        categorize_image(category)
        root.after(5, lambda: hold_categorization(category))  # Constant speed

def stop_categorization(event):
    root._running = False

# Create buttons based on the layout
for row, categories in enumerate(layout):
    for col, category in enumerate(categories):
        btn = tk.Button(button_frame, text=f"{category}", font=("Arial", 18, "bold"), width=5, height=2, 
                        bg="#4CAF50", fg="white", 
                        command=lambda c=str(category): categorize_image(c))
        btn.bind('<ButtonPress-1>', lambda event, c=str(category): start_categorization(c))
        btn.bind('<ButtonRelease-1>', stop_categorization)
        btn.grid(row=row, column=col, padx=10, pady=5)

# Load first image
show_image()

# Start GUI
root.mainloop()

# Save progress on exit
save_progress()
