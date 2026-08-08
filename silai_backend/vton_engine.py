import sys
import base64
import io
import sys
# This is mandatory:
sys.path.insert(0, r"D:\python_libs") 

import torch
print("Torch imported successfully from:", torch.__file__)
print(f"CUDA Available: {torch.cuda.is_available()}")
if torch.cuda.is_available():
    print(f"GPU Name: {torch.cuda.get_device_name(0)}")
from PIL import Image
from diffusers import StableDiffusionXLInpaintPipeline

def run_vton(human_path, garment_path):
    # Set to half precision for 4GB VRAM limit
    device = "cuda"
    
    # Load pipeline with specific memory optimizations
    pipe = StableDiffusionXLInpaintPipeline.from_pretrained(
        "yisol/IDM-VTON", 
        torch_dtype=torch.float16,
        use_safetensors=True
    ).to(device)
    
    # Enable these to stop your 4GB VRAM from running out
    pipe.enable_model_cpu_offload() 
    pipe.enable_vae_tiling() # This is critical for low VRAM
    
    # ... rest of your processing logic ...
    print("SUCCESS_PROCESSING")