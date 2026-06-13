import os
import json
import shutil
import random

# Core system directory targets
# Core system directory targets (Adding \\?\ tells Windows to bypass path limits)
base_dataset_dir = r"\\?\C:\Users\maham\Downloads\silai_app\silai_project\silai_backend\dataset"
indo_fashion_dir = os.path.join(base_dataset_dir, "dataset_indo_fashion")
output_base_dir = os.path.join(base_dataset_dir, "training_ready")

# Explicitly ensure the destination workspace is built immediately
os.makedirs(output_base_dir, exist_ok=True)

# 1. Handle Indo-Fashion JSON mappings first
indo_mapping = {
    "women kurta": "kurti",
    "leggings & salwar": "churidar",
    "gowns": "anarkali"  
}

print("--- Step 1: Merging Indo-Fashion Data ---")
splits = ["train", "val"]
file_id = 0

for split in splits:
    json_path = os.path.join(indo_fashion_dir, f"{split}_data.json")
    image_source_dir = os.path.join(indo_fashion_dir, "images", split)
    
    if os.path.exists(json_path) and os.path.exists(image_source_dir):
        with open(json_path, 'r', encoding='utf-8') as f:
            for line in f:
                data = json.loads(line)
                raw_label = data.get("class_label", "").lower()
                
                if raw_label in indo_mapping:
                    target_class = indo_mapping[raw_label]
                    img_filename = data["image_path"].split("/")[-1]
                    src_path = os.path.join(image_source_dir, img_filename)
                    
                    if os.path.exists(src_path):
                        file_id += 1
                        ext = os.path.splitext(img_filename)[1]
                        dest_folder = os.path.join(output_base_dir, split, target_class)
                        os.makedirs(dest_folder, exist_ok=True)
                        
                        # Save with compact short unique numeric names
                        shutil.copy(src_path, os.path.join(dest_folder, f"img_{file_id}{ext}"))
    else:
        print(f"💡 Info: Skipping Indo-Fashion {split} loop (JSON or images not found in standard sub-paths).")

print("\n--- Step 2: Dynamically Merging ALL Other Downloaded Folders ---")
split_ratio = 0.8

# Strict check only on the final subfolder name, avoiding general path collisions
ignore_folders = ["training_ready", "images", "labels", "train", "test", "val", "validation", "data"]

# Gather immediate subdirectories inside your dataset folder
target_subfolders = [f.name for f in os.scandir(base_dataset_dir) if f.is_dir() and f.name != "training_ready"]

for subf in target_subfolders:
    target_path = os.path.join(base_dataset_dir, subf)
    
    for root, dirs, files in os.walk(target_path):
        folder_name = os.path.basename(root)
        
        # Skip internal utility splits or known export paths
        if folder_name.lower() in ignore_folders:
            continue
            
        valid_images = [f for f in files if f.lower().endswith(('.png', '.jpg', '.jpeg'))]
        
        if valid_images:
            # Create a clean uniform class name from the structural root component
            clean_class_name = subf.lower().replace("dataset_", "").replace(" ", "_").replace("-", "_")
            print(f"🚀 Processing {len(valid_images)} files from dataset segment: '{clean_class_name}'...")
            
            random.shuffle(valid_images)
            idx = int(len(valid_images) * split_ratio)
            
            # Move to Train split
            for img in valid_images[:idx]:
                file_id += 1
                ext = os.path.splitext(img)[1] # Extracts .jpg or .png safely
                src = os.path.join(root, img)
                
                # Using short unique numeric names to bypass Windows MAX_PATH limits
                dst = os.path.join(output_base_dir, "train", clean_class_name, f"img_{file_id}{ext}")
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy(src, dst)
                
            # Move to Val split
            for img in valid_images[idx:]:
                file_id += 1
                ext = os.path.splitext(img)[1]
                src = os.path.join(root, img)
                
                dst = os.path.join(output_base_dir, "val", clean_class_name, f"img_{file_id}{ext}")
                os.makedirs(os.path.dirname(dst), exist_ok=True)
                shutil.copy(src, dst)

print("\n--- DONE! Every single image from all datasets has been merged into training_ready! ---")