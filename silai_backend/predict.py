import sys
import os
import json
import warnings

# Suppress warning outputs so they don't mess up our Node.js parser
warnings.filterwarnings("ignore")

try:
    from flask import Flask, request, jsonify
    from ultralytics import YOLO
    import cv2
except ImportError:
    print("[ERROR]: Missing packages. Run: pip install flask ultralytics opencv-python")
    sys.exit(1)

app = Flask(__name__)

# --- LOAD MODEL ONCE AT BOOT ---
model_path = os.path.join(os.path.dirname(__file__), 'best.pt')
if not os.path.exists(model_path):
    alt_path = os.path.join(os.path.dirname(__file__), 'runs', 'classify', 'train', 'weights', 'best.pt')
    if os.path.exists(alt_path):
        model_path = alt_path
    else:
        model_path = os.path.join(os.path.dirname(__file__), 'yolov8n-cls.pt')

print(f"🎯 Loading Model Weights from: {model_path}")
model = YOLO(model_path)

@app.route('/api/generate-blueprint', methods=['POST'])
@app.route('/api/analyze-garment', methods=['POST'])
def predict():
    temp_path = os.path.join(os.path.dirname(__file__), "temp_upload.jpg")
    
    try:
        print("\n📥 Inbound payload stream intercepted...")
        
        # Safe Strategy 1: Check standard multi-part form files
        if request.files and len(request.files) > 0:
            file_key = list(request.files.keys())[0]
            print(file_key)
            request.files[file_key].save(temp_path)
        
        # Safe Strategy 2: Check raw body payload parameters or JSON base64 text strings
        elif request.is_json:
            body = request.get_json(silent=True) or {}
            img_data = body.get("image") or body.get("filePath") or body.get("imagePath") or body.get("file")
            
            if img_data and isinstance(img_data, str):
                if os.path.exists(img_data):
                    import shutil
                    shutil.copy(img_data, temp_path)
                elif len(img_data) > 100: # Base64 string fallback
                    import base64
                    if "," in img_data:
                        img_data = img_data.split(",")[1]
                    with open(temp_path, "wb") as fh:
                        fh.write(base64.b64decode(img_data))
        
        # Safe Strategy 3: Raw direct byte stream block fallback
        elif request.data:
            with open(temp_path, "wb") as f:
                f.write(request.data)
                
        else:
            print("⚠️ Empty request body structure submitted.")
            return jsonify({"status": "error", "match": "fallback_dress", "message": "No valid data body found"}), 400

        # Verify if our extraction file actually exists and has data before passing to YOLO
        if not os.path.exists(temp_path) or os.path.getsize(temp_path) == 0:
            print("⚠️ Temporary image assembly file was empty or missing.")
            return jsonify({"status": "error", "match": "fallback_dress", "message": "Image assembly failed"}), 400

        # Run inference safely inside a guarded check block
        print("🧠 Running YOLO model evaluation matrix...")
        results = model(temp_path, verbose=False)
        
        # Instantly remove file to unlock resource handlers
        if os.path.exists(temp_path):
            os.remove(temp_path)

        # Parse final classification keys safely
        if results and len(results) > 0 and getattr(results[0], 'probs', None) is not None:
            top_class_idx = results[0].probs.top1
            class_name = results[0].names[top_class_idx].lower().strip()
            print(f"✨ Match Found -> [{class_name}]")
            return jsonify({"status": "success", "match": class_name})
        
        print("💡 Model executed but didn't return class probabilities. Defaulting.")
        return jsonify({"status": "success", "match": "fallback_dress"})

    except Exception as server_err:
        print(f"❌ Guarded Server Exception Intercepted: {str(server_err)}")
        if os.path.exists(temp_path):
            os.remove(temp_path)
        # Return a clean 500 JSON payload instead of dropping the connection abruptly!
        return jsonify({"status": "error", "match": "fallback_dress", "details": str(server_err)}), 500

if __name__ == "__main__":
    print("===========================================================")
    print("🚀 Silai Computer Vision Engine active on Port 3000...")
    print("===========================================================")
    app.run(host='127.0.0.1', port=3000, debug=False)