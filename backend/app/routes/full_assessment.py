from fastapi import APIRouter, UploadFile, File, Form, Depends
from app.services.memory_score import calculate_memory_score
import shutil
import os

from app.services.speech_features import transcribe_audio, extract_features
from app.services.ml_predictor import predict_risk
from app.services.explainer import generate_explanation
from app.services.retrainer import retrain_if_needed
from app.services.dependencies import get_current_user
from app.services.cognitive_score import compute_cognitive_score
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
    shown_list = shown_words.split(",")
    recalled_list = recalled_words.split(",")

    memory_score, correct = calculate_memory_score(
        shown_list,
        recalled_list,
        time_taken
    )

    # ---------- SAVE AUDIO ----------
    path = os.path.join(UPLOAD_DIR, file.filename)
    with open(path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    # ---------- SPEECH  ----------
    text = transcribe_audio(path)
    features = extract_features(text, path)
    delete_file(path)

    # ---------- DATABASE ----------
    db = SessionLocal()

    records = (
        db.query(Assessment)
        .filter(Assessment.user_id == user_id)
        .order_by(Assessment.created_at.asc())
        .all()
    )

    # ---------- BASELINE DECLINE ----------
    if len(records) >= 3:
        baseline_scores = [r.memory_score for r in records[:3]]
        baseline = sum(baseline_scores) / 3
        decline_rate = max(0, baseline - memory_score)
    else:
        decline_rate = 0

    # ---------- SPEECH SCORE ----------
    speech_score = features["speech_score"]

    # ---------- FINAL COGNITIVE SCORE ----------
    result = compute_cognitive_score(
        memory_score,
        speech_score,
        decline_rate
    )

    final_score = result["final_score"]
    final_risk = result["risk"]

    # ---------- TREND ANALYSIS
    previous_scores = [r.cognitive_score for r in records]

    if len(previous_scores) >= 3:
        recent_scores = previous_scores[-3:]
        avg_past = sum(recent_scores) / len(recent_scores)
        change = final_score - avg_past
    else:
        avg_past = final_score
        change = 0

    if change < -10:
        trend = " Significant decline detected"
    elif change < -5:
        trend = " Slight decline observed"
    elif change > 5:
        trend = " Improvement observed"
    else:
        trend = " Stable performance"

    # ---------- ML ----------
    ml_prediction, confidence = predict_risk({
        "memory_score": memory_score,
        "time_taken": time_taken,
        "avg_sentence_length": features["avg_sentence_length"],
        "vocab_richness": features["vocab_richness"],
        "hesitation_ratio": features["hesitation_ratio"],
        "repetition_ratio": features["repetition_ratio"],
        "decline_rate": decline_rate
    })

    # ---------- EXPLANATION ----------
    explanation = generate_explanation({
        "memory_score": memory_score,
        "time_taken": time_taken,
        "avg_sentence_length": features["avg_sentence_length"],
        "vocab_richness": features["vocab_richness"],
        "hesitation_ratio": features["hesitation_ratio"],
        "repetition_ratio": features["repetition_ratio"],
        "decline_rate": decline_rate
    })

    # ---------- SAVE ----------
    record = Assessment(
        user_id=user_id,
        memory_score=memory_score,
        cognitive_score=final_score,
        time_taken=time_taken,
        avg_sentence_length=features["avg_sentence_length"],
        vocab_richness=features["vocab_richness"],
        hesitation_ratio=features["hesitation_ratio"],
        repetition_ratio=features["repetition_ratio"],
        decline_rate=decline_rate,
        ml_prediction=ml_prediction,
        confidence=confidence,
        risk_level=final_risk,
        trend=trend,
        change=change,
    )

    db.add(record)
    db.commit()
    db.close()

    retrain_if_needed()

    # ---------- RESPONSE ----------
    return {
        "memory_score": memory_score,
        "correct_words": correct,
        "speech_features": features,
        "decline_rate": decline_rate,
        "cognitive_score": final_score,
        "risk": final_risk,
        "confidence": round(confidence * 100, 2) if confidence else 0,
        "summary": explanation["summary"],
        "insights": explanation["insights"],
        "trend": trend,
        "change": round(change, 2),
        "recommendation": explanation["recommendation"]
    }