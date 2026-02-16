from fastapi import APIRouter, UploadFile, File
import shutil
from app.services.speech_features import transcribe_audio, extract_features

router = APIRouter()

@router.post("/upload-speech")
async def upload_audio(file: UploadFile = File(...)):
    path = f"temp_{file.filename}"

    with open(path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    text = transcribe_audio(path)
    features = extract_features(text)

    return {
        "transcript": text,
        "features": features
    }
