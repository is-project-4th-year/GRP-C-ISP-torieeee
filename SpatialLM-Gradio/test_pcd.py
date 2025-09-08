import cv2
from gradio_inference2 import process_frame_to_pcd  # change this to your actual filename (without .py)

# Load the last saved frame
frame_path = "outputs/frames/latest_frame.jpg"
frame = cv2.imread(frame_path)

if frame is None:
    print(f"❌ Could not read frame at {frame_path}")
else:
    print(f"✅ Frame loaded: shape={frame.shape}, dtype={frame.dtype}")

    try:
        pcd_path = process_frame_to_pcd(frame)
        print("✅ Generated point cloud at:", pcd_path)
    except Exception as e:
        print("❌ Error generating point cloud:", e)
