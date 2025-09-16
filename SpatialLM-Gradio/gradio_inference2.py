# Imports for Gradio and the processing pipeline
from datetime import datetime
import gradio as gr
import os
import shutil
import tempfile
import numpy as np
import torch
import cv2
import open3d as o3d
from transformers import AutoImageProcessor, AutoModelForDepthEstimation, AutoTokenizer, AutoModelForCausalLM
import threading
import atexit
import logging
import time
import psutil
import base64
import pyttsx3
from ctransformers import AutoModelForCausalLM as CTransformersAutoModelForCausalLM

# Imports for the Flask API
from flask import Flask, request, jsonify, send_from_directory

# Mocking these imports as they are not provided in the user's context
try:
    from inference import preprocess_point_cloud, generate_layout, create_default_code_template
    from spatiallm.pcd import load_o3d_pcd, get_points_and_colors, cleanup_pcd
    from spatiallm import Layout
except ImportError as e:
    logging.warning(f"Failed to import from local modules: {e}")
    # Define mock classes/functions to prevent errors
    class Layout:
        @staticmethod
        def get_grid_size(): return 0.1
        @staticmethod
        def get_num_bins(): return 10
        def translate(self, min_extent): pass
        def to_language_string(self): return "This is a mock layout description."
    def preprocess_point_cloud(*args): return np.zeros((10, 3, 3))
    def generate_layout(*args): return Layout(), "This is a mock layout string."
    def create_default_code_template(*args): return "template.txt"
    def load_o3d_pcd(*args): return o3d.geometry.PointCloud()
    def get_points_and_colors(*args): return np.zeros((1, 3)), np.zeros((1, 3))
    def cleanup_pcd(*args): return o3d.geometry.PointCloud()

# --- Flask API and Shared State Setup ---
flask_app = Flask(__name__)
frame_lock = threading.Lock()
latest_frame_path = None
last_processed_frame = None
latest_audio_path = None

# Logging setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# --- Core Processing Functions ---
model = None
tokenizer = None
simplify_model = None
template_file_path = "code_template.txt"
output_dir = "outputs"
depth_processor = None
depth_model = None

# Create a dedicated directory for point clouds, frames, and layouts
point_cloud_dir = os.path.join(output_dir, "pcd")
frame_dir = os.path.join(output_dir, "frames")
layout_dir = os.path.join(output_dir, "layouts")
os.makedirs(point_cloud_dir, exist_ok=True)
os.makedirs(frame_dir, exist_ok=True)
os.makedirs(layout_dir, exist_ok=True)

def load_model(model_path):
    global model, tokenizer
    if model is None or tokenizer is None:
        try:
            logger.info(f"Loading SpatialLM model from {model_path}...")
            tokenizer = AutoTokenizer.from_pretrained(model_path)
            model = AutoModelForCausalLM.from_pretrained(
                model_path,
                trust_remote_code=True,
                torch_dtype=torch.bfloat16,
                low_cpu_mem_usage=True,
                device_map="auto"
            )
            
            if torch.cuda.is_available():
                model.to("cuda")
            else:
                model.to("cpu")
                
            model.set_point_backbone_dtype(torch.float32)
            model.eval()
            logger.info("SpatialLM model loaded successfully.")
            return model, tokenizer
        except Exception as e:
            logger.error(f"Failed to load SpatialLM model: {e}")
            return None, None
    return model, tokenizer

def get_depth_models():
    global depth_processor, depth_model
    if depth_model is None or depth_processor is None:
        try:
            model_name = "LiheYoung/depth-anything-small-hf"
            logger.info(f"Loading depth models {model_name}...")
            depth_processor = AutoImageProcessor.from_pretrained(model_name)
            depth_model = AutoModelForDepthEstimation.from_pretrained(
                model_name,
                low_cpu_mem_usage=True,
            ).to("cpu")
            depth_model.eval()
            logger.info("Depth models loaded successfully.")
            return depth_processor, depth_model
        except Exception as e:
            logger.error(f"Failed to load depth models: {e}")
            return None, None
    return depth_processor, depth_model

def get_simplification_model():
    """Initializes the local LLM for text simplification only once."""
    global simplify_model
    if simplify_model is None:
        try:
            logger.info("Loading local simplification model: Mistral-7B-Instruct-v0.2...")
            simplify_model = CTransformersAutoModelForCausalLM.from_pretrained(
                "TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
                model_file="mistral-7b-instruct-v0.2.Q4_K_M.gguf",
                model_type="mistral",
                context_length=4096 # Pass the context length directly
            )
            logger.info("Local simplification model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load local simplification model: {e}")
            simplify_model = None
    return simplify_model

def get_intrinsics(H, W, fov=62.2):
    f = 0.5 * W / np.tan(0.5 * fov * np.pi / 180.0)
    return np.array([[f, 0, W/2], [0, f, H/2], [0, 0, 1]], dtype=np.float32)

def pixel_to_point(depth_image, camera_intrinsics=None):
    H, W = depth_image.shape
    if camera_intrinsics is None:
        camera_intrinsics = get_intrinsics(H, W)

    fx, fy = camera_intrinsics[0, 0], camera_intrinsics[1, 1]
    cx, cy = camera_intrinsics[0, 2], camera_intrinsics[1, 2]

    u, v = np.meshgrid(np.arange(W), np.arange(H))
    z = depth_image.astype(np.float32)
    x = (u - cx) * z / fx
    y = (v - cy) * z / fy

    return x, y, z

def create_point_cloud(depth_image, color_image):
    try:
        logger.info("Creating point cloud from depth and color images...")
        H, W = depth_image.shape
        color_image = cv2.resize(color_image, (W, H))

        depth_image = np.maximum(depth_image, 1e-5)
        x, y, z = pixel_to_point(depth_image)

        points = np.stack((x, y, z), axis=-1).reshape(-1, 3).astype(np.float32)
        colors = color_image.reshape(-1, 3).astype(np.float32) / 255.0

        valid_mask = np.isfinite(points).all(axis=1) & (z.flatten() > 0.1) & (z.flatten() < 50.0)
        points = points[valid_mask]
        colors = colors[valid_mask]

        cloud = o3d.geometry.PointCloud()
        cloud.points = o3d.utility.Vector3dVector(points)
        cloud.colors = o3d.utility.Vector3dVector(colors)
        logger.info("Point cloud created.")
        return cloud
    except Exception as e:
        logger.error(f"Point cloud creation failed: {e}")
        return None

def process_frame_to_pcd(frame_input, output_path=None):
    if frame_input is None:
        raise gr.Error("Please upload an image frame.")
    
    depth_processor, depth_model = get_depth_models()
    if depth_processor is None or depth_model is None:
        raise gr.Error("Depth models are not loaded. Server is unhealthy.")
    
    logger.info("Starting depth map generation...")
    with torch.no_grad():
        logger.info(f"Frame dtype: {frame_input.dtype}, shape: {frame_input.shape}, min: {frame_input.min()}, max: {frame_input.max()}")
        frame_input_rgb = cv2.cvtColor(frame_input, cv2.COLOR_BGR2RGB)
        inputs = depth_processor(images=frame_input_rgb, return_tensors="pt")
        outputs = depth_model(**inputs)
        depth_map = outputs.predicted_depth.squeeze().cpu().numpy()
    logger.info("Depth map generated.")

    depth_min, depth_max = depth_map.min(), depth_map.max()
    logger.info(f"Depth min: {depth_min}, max: {depth_max}")
    if depth_max > depth_min:
        depth_map = (depth_map - depth_min) * 10.0 / (depth_max - depth_min)
    else:
        depth_map = np.ones_like(depth_map) * 5.0
    
    cloud = create_point_cloud(depth_map, frame_input)
    if cloud is None:
        raise gr.Error("Failed to create point cloud.")

    if output_path is None:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_path = os.path.join(point_cloud_dir, f"frame_{timestamp}.pcd")

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    o3d.io.write_point_cloud(output_path, cloud)

    if not os.path.exists(output_path):
        raise gr.Error(f"Point cloud was not saved: {output_path}")
    logger.info(f"Point cloud saved to {output_path}")

    return output_path
    
def generate_layout_from_pcd(
    point_cloud_file, 
    model_path, 
    custom_prompt=None,
    top_k=10, 
    top_p=0.95, 
    temperature=0.6, 
    num_beams=1,
    max_new_tokens=4096,
    progress=gr.Progress()
):
    logger.info(f"Generating layout from point cloud file: {point_cloud_file}")
    code_template_file = create_default_code_template()
    model, tokenizer = load_model(model_path)
    
    if model is None or tokenizer is None:
        raise gr.Error("SpatialLM models are not loaded. Server is unhealthy.")

    point_cloud = load_o3d_pcd(point_cloud_file)
    point_cloud = cleanup_pcd(point_cloud)
    points, colors = get_points_and_colors(point_cloud)
    min_extent = np.min(points, axis=0)
    grid_size = Layout.get_grid_size()
    num_bins = Layout.get_num_bins()
    input_pcd = preprocess_point_cloud(points, colors, grid_size, num_bins)
    layout, layout_str = generate_layout(
        model, input_pcd, tokenizer, code_template_file, custom_prompt,
        top_k, top_p, temperature, num_beams, max_new_tokens
    )
    layout.translate(min_extent)
    pred_language_string = layout.to_language_string()
    
    # Get the timestamp from the point cloud filename to create a unique txt file
    timestamp = os.path.splitext(os.path.basename(point_cloud_file))[0].replace('frame_', '')
    layout_path = os.path.join(layout_dir, f"layout_{timestamp}.txt")
    os.makedirs(os.path.dirname(layout_path), exist_ok=True)
    with open(layout_path, "w") as f:
        f.write(pred_language_string)
    logger.info(f"Layout description generated and saved to {layout_path}.")
    
    return layout_path, pred_language_string

def get_simplification_model():
    """Initializes the local LLM for text simplification only once."""
    global simplify_model
    if simplify_model is None:
        try:
            logger.info("Loading local simplification model: Mistral-7B-Instruct-v0.2...")
            simplify_model = CTransformersAutoModelForCausalLM.from_pretrained(
                "TheBloke/Mistral-7B-Instruct-v0.2-GGUF",
                model_file="mistral-7b-instruct-v0.2.Q4_K_M.gguf",
                model_type="mistral",
                context_length=4096 # Pass the context length directly
            )
            logger.info("Local simplification model loaded successfully.")
        except Exception as e:
            logger.error(f"Failed to load local simplification model: {e}")
            simplify_model = None
    return simplify_model

def generate_audio_from_text(text_input):
    global latest_audio_path
    if not text_input:
        raise gr.Error("No layout text to convert to audio.")
    
    logger.info("Generating audio from text using pyttsx3...")
    speech_file_path = os.path.join(output_dir, "audio", "output_speech.mp3")
    os.makedirs(os.path.dirname(speech_file_path), exist_ok=True)
    
    engine = pyttsx3.init()
    engine.save_to_file(text_input, speech_file_path)
    engine.runAndWait()
    
    latest_audio_path = speech_file_path
    logger.info(f"Audio file saved to {speech_file_path}.")
    
    return speech_file_path

# --- Flask API Endpoints ---
@flask_app.route("/process_frame", methods=["POST"])
def handle_frame():
    try:
        frame = None

        if "frame" in request.files:
            logging.info("Frame received as file upload")
            image_data = request.files["frame"].read()
            nparr = np.frombuffer(image_data, np.uint8)
            frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        elif request.is_json:
            logging.info("Frame received as Base64 JSON")
            data = request.get_json()
            image_data_base64 = data.get("image")
            if image_data_base64:
                image_bytes = base64.b64decode(image_data_base64)
                nparr = np.frombuffer(image_bytes, np.uint8)
                frame = cv2.imdecode(nparr, cv2.IMREAD_COLOR)

        if frame is None or frame.size == 0:
            return jsonify({"status": "error", "message": "No valid frame received"}), 400

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        frame_path = os.path.join(frame_dir, f"frame_{timestamp}.jpg")
        os.makedirs(frame_dir, exist_ok=True)
        cv2.imwrite(frame_path, frame)
        logging.info(f"Saved frame: {frame_path}")

        pcd_path = os.path.join(point_cloud_dir, f"frame_{timestamp}.pcd")
        generated_path = process_frame_to_pcd(frame, output_path=pcd_path)
        logging.info(f"Generated PCD: {generated_path}")

        return jsonify({"status": "success", "pcd_path": generated_path})

    except Exception as e:
        logging.error(f"Error processing frame: {e}")
        return jsonify({"status": "error", "message": str(e)}), 500

@flask_app.route("/get_audio", methods=["GET"])
def get_audio():
    """Serves the most recently generated audio file to the Raspberry Pi."""
    global latest_audio_path
    if latest_audio_path and os.path.exists(latest_audio_path):
        return send_from_directory(os.path.dirname(latest_audio_path), os.path.basename(latest_audio_path), as_attachment=True)
    else:
        return jsonify({"status": "error", "message": "Audio file not found"}), 404

@flask_app.route("/health", methods=["GET"])
def health_check():
    """Health check endpoint to report server status and model loading."""
    status = "healthy"
    message = "Server is running."
    
    depth_models_ok = get_depth_models() is not None
    spatiallm_models_ok = load_model("manycore-research/SpatialLM-Llama-1B")[0] is not None
    simplification_model_ok = get_simplification_model() is not None
    
    if not depth_models_ok or not spatiallm_models_ok or not simplification_model_ok:
        status = "unhealthy"
        message = "Required models are not loaded."
    
    return jsonify({
        "status": status,
        "message": message,
        "depth_models_loaded": depth_models_ok,
        "spatiallm_models_loaded": spatiallm_models_ok,
        "simplification_model_loaded": simplification_model_ok,
        "cpu_usage_percent": psutil.cpu_percent(),
        "memory_usage_mb": psutil.virtual_memory().used / (1024 * 1024),
        "gpu_available": torch.cuda.is_available()
    })
    
# --- Gradio Interface Setup ---
def gradio_interface():
    with gr.Blocks(title="SpatialLM Gradio | 3D Scene Understanding with Large Language Model ") as demo:
        gr.Markdown("# SpatialLM Gradio | 3D Scene Understanding with Large Language Model ")
        gr.Markdown("SpatialLM: A 3D Large Language Model for Structured Scene Understanding, Processing Point Cloud Data from Monocular Videos, RGBD Images, and LiDAR.")
        gr.Markdown("Receiving frames from a Raspberry Pi...")
        
        last_processed_pcd_state = gr.State(value=None)
        
        with gr.Row():
            with gr.Column(scale=1):
                frame_display = gr.Image(label="Latest Frame from Raspberry Pi", type="numpy", interactive=False)
                
                model_path = gr.Dropdown(
                    label="Model Selection", 
                    choices=[
                        "manycore-research/SpatialLM-Llama-1B",
                        "manycore-research/SpatialLM-Qwen-0.5B"
                    ],
                    value="manycore-research/SpatialLM-Llama-1B"
                )                
                custom_prompt = gr.Textbox(
                    label="Custom Prompt",
                    placeholder="Detect walls, doors, windows, boxes...",
                    value="Detect walls, doors, windows, boxes"
                )
                       
                with gr.Accordion("Generation Settings", open=False):
                    top_k = gr.Slider(minimum=1, maximum=100, value=10, step=1, label="Top K")
                    top_p = gr.Slider(minimum=0.0, maximum=1.0, value=0.95, step=0.05, label="Top P")
                    temperature = gr.Slider(minimum=0.1, maximum=2.0, value=0.6, step=0.1, label="Temperature")
                    num_beams = gr.Slider(minimum=1, maximum=10, value=1, step=1, label="Number of Beams")
                    max_new_tokens = gr.Slider(minimum=100, maximum=8192, value=4096, step=100, label="Max New Tokens")
                
                process_btn = gr.Button("Process New PCD", variant="primary", size="lg")
                audio_btn = gr.Button("Generate Audio from Description", variant="secondary", size="lg")

            with gr.Column(scale=1):
                point_cloud_viewer = gr.Model3D(label="Point Cloud Visualization", display_mode="point_cloud", height=700)
                layout_text_output = gr.Textbox(label="Layout Description")
                audio_output = gr.Audio(label="Audio Output")
        
        def process_latest_pcd(last_processed_pcd_file, model_path, custom_prompt, top_k, top_p, temperature, num_beams, max_new_tokens):
            pcd_dir = "outputs/pcd"
            if not os.path.exists(pcd_dir):
                return last_processed_pcd_file, None, None, None, None
            
            list_of_pcd_files = [os.path.join(pcd_dir, f) for f in os.listdir(pcd_dir) if f.endswith('.pcd')]
            if not list_of_pcd_files:
                gr.Warning("No PCD files found to process.")
                return last_processed_pcd_file, None, None, None, None

            latest_pcd_file = max(list_of_pcd_files, key=os.path.getctime)

            if latest_pcd_file != last_processed_pcd_file:
                logger.info(f"New PCD file detected: {latest_pcd_file}")
                
                try:
                    layout_path, technical_layout_str = generate_layout_from_pcd(
                        latest_pcd_file, model_path, custom_prompt, top_k, top_p, temperature, num_beams, max_new_tokens
                    )
                    
                    # New step: Simplify the technical layout description
                    simplified_layout_str = simplify_layout_description(technical_layout_str)
                    
                    audio_path = generate_audio_from_text(simplified_layout_str) if simplified_layout_str else None
                    
                    timestamp = os.path.basename(latest_pcd_file).split('.')[0].replace('frame_', '')
                    frame_path = os.path.join("outputs/frames", f"frame_{timestamp}.jpg")
                    frame = cv2.imread(frame_path)
                    
                    if frame is None:
                        logger.warning(f"Could not find matching frame for PCD: {frame_path}")

                    gr.Info("Pipeline completed successfully.")
                    return latest_pcd_file, frame, latest_pcd_file, simplified_layout_str, audio_path
                except Exception as e:
                    logger.error(f"Processing pipeline failed for {latest_pcd_file}: {e}")
                    gr.Error(f"Processing failed: {e}")
                    return last_processed_pcd_file, None, None, None, None
            else:
                gr.Info("No new PCD file found. Please send a new frame to the Flask API.")
                return last_processed_pcd_file, None, None, None, None
        
        def handle_audio_button_click(layout_text):
            if layout_text and layout_text != "":
                return generate_audio_from_text(layout_text)
            else:
                gr.Warning("No layout text to convert to audio.")
                return None

        # Event handling
        process_btn.click(
            fn=process_latest_pcd,
            inputs=[
                last_processed_pcd_state,
                model_path,
                custom_prompt,
                top_k,
                top_p,
                temperature,
                num_beams,
                max_new_tokens,
            ],
            outputs=[last_processed_pcd_state, frame_display, point_cloud_viewer, layout_text_output, audio_output]
        )

        audio_btn.click(
            fn=handle_audio_button_click,
            inputs=[layout_text_output],
            outputs=[audio_output]
        )
        
    return demo

def cleanup():
    if os.path.exists(frame_dir):
        try:
            shutil.rmtree(frame_dir)
            logger.info(f"Cleaned up frame directory: {frame_dir}")
        except OSError as e:
            logger.error(f"Error removing frame directory: {e}")
    
    if os.path.exists(point_cloud_dir):
        try:
            shutil.rmtree(point_cloud_dir)
            logger.info(f"Cleaned up point cloud directory: {point_cloud_dir}")
        except OSError as e:
            logger.error(f"Error removing point cloud directory: {e}")

if __name__ == "__main__":
    # Ensure the simplification model is loaded at startup
    get_simplification_model()
    
    gradio_demo = gradio_interface()

    flask_thread = threading.Thread(target=lambda: flask_app.run(host="0.0.0.0", port=5002, use_reloader=False))
    flask_thread.daemon = True
    flask_thread.start()

    atexit.register(cleanup)
    gradio_demo.launch(share=False)