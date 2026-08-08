import asyncio
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
# Ensure these imports point to your actual service files
from .services import tutorial_service, voice_service

app = FastAPI()

class BlueprintData(BaseModel):
    blueprint_json: dict

@app.post("/api/generate-tutorial")
async def generate_tutorial(data: BlueprintData):
    try:
        # 1. Generate the structured tutorial steps
        tutorial_json = await tutorial_service.generate(data.blueprint_json)
        
        # 2. Define a helper to process a single step asynchronously
        async def process_step(step):
            try:
                audio_url = await voice_service.text_to_speech(
                    step['instruction_tamil'], 
                    language="ta-IN"
                )
                step['audio_url'] = audio_url
            except Exception as e:
                # Log error and provide a fallback if necessary
                print(f"Error generating audio for step: {e}")
                step['audio_url'] = None 
            return step

        # 3. Process all steps concurrently using asyncio.gather
        if 'steps' in tutorial_json:
            tutorial_json['steps'] = await asyncio.gather(
                *[process_step(step) for step in tutorial_json['steps']]
            )
        
        return tutorial_json
        
    except Exception as e:
        # Raise an HTTPException to provide a clean 500 error to the client
        raise HTTPException(status_code=500, detail=f"Failed to generate tutorial: {str(e)}")