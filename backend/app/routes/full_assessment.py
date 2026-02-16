from fastapi import APIRouter, UploadFile, File, Form, Depends
from fastapi.responses import FileResponse
from starlette.background import BackgroundTask

import shutil
import os

from app.services.speech_features import transcribe_audio, extract_features
from app.services.risk_model import calculate_risk
from app.services.pdf_report import create_report
from app.services.ml_predictor import predict_risk
from app.services.explainer import generate_explanation
from app.services.retrainer import retrain_if_needed
from app.services.dependencies import get_current_user

from app.db import SessionLocal
from app.models.assessment import Assessment
from sqlalchemy import desc


router = APIRouter()

UPLOAD_DIR = "storage/uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)


def delete_file(path: str):
    if os.path.exists(path):
        os.remove(path)


@router.post("/full-assessment")
async def full_assessment(
    file: UploadFile = File(...),
    shown_words: str = Form(...),
    recalled_words: str = Form(...),
    time_taken: float = Form(...),
    user_id: int = Depends(get_current_user)
):

    # ---------- MEMORY SCORE ----------
    shown = shown_words.split(",")
    recalled = recalled_words.split(",")

    correct = len(set(shown) & set(recalled))
    memory_score = correct * 20
    if time_taken > 30:
        memory_score -= 5
    memory_score = max(memory_score, 0)

    # ---------- SAVE AUDIO ----------
    path = os.path.join(UPLOAD_DIR, file.filename)
    with open(path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # ---------- SPEECH ANALYSIS ----------
    text = transcribe_audio(path)
    features = extract_features(text)

    # delete audio after extracting features
    delete_file(path)

    # ---------- FALLBACK RULE ----------
    rule_result = calculate_risk(memory_score, features)

    # ---------- DATABASE ----------
    db = SessionLocal()
    last = db.query(Assessment).order_by(desc(Assessment.created_at)).first()

    if last:
        decline_rate = last.memory_score - memory_score
    else:
        decline_rate = 0

    # ---------- ML PREDICTION ----------
    ml_prediction, confidence = predict_risk({
        "memory_score": memory_score,
        "time_taken": time_taken,
        "avg_sentence_length": features["avg_sentence_length"],
        "vocab_richness": features["vocab_richness"],
        "hesitation_ratio": features["hesitation_ratio"],
        "repetition_ratio": features["repetition_ratio"],
        "decline_rate": decline_rate
    })
    explanation = generate_explanation({ 
        "memory_score": memory_score,
        "time_taken": time_taken,
        "avg_sentence_length": features["avg_sentence_length"],
        "vocab_richness": features["vocab_richness"],
        "hesitation_ratio": features["hesitation_ratio"],
        "repetition_ratio": features["repetition_ratio"],
        "decline_rate": decline_rate
    })


    # ---------- FINAL DECISION ----------
    if ml_prediction is not None:
        if ml_prediction == 0:
            final_risk = "Normal"
        elif ml_prediction == 1:
            final_risk = "Mild Cognitive Impairment"
        else:
            final_risk = "High Dementia Risk"
    else:
        final_risk = rule_result["risk_level"]

    # ---------- SAVE RECORD ----------
    record = Assessment(
        user_id=user_id,
        memory_score=memory_score,
        time_taken=time_taken,
        avg_sentence_length=features["avg_sentence_length"],
        vocab_richness=features["vocab_richness"],
        hesitation_ratio=features["hesitation_ratio"],
        repetition_ratio=features["repetition_ratio"],
        decline_rate=decline_rate,
        ml_prediction=ml_prediction,
        confidence=confidence,
        risk_level=final_risk
    )

    db.add(record)
    db.commit()
    db.close()
    retrain_if_needed()


    # ---------- REPORT ----------
    ml_result = {
        "risk_score": round(confidence * 100, 2) if confidence else 0,
        "risk_level": final_risk
    }

    report_file = create_report(ml_result, memory_score, text, features, explanation)

    return FileResponse(
        report_file,
        media_type="application/pdf",
        filename="dementia_report.pdf",
        background=BackgroundTask(delete_file, report_file)
    )
