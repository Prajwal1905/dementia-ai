from fastapi import APIRouter
from pydantic import BaseModel
from app.services.risk_model import calculate_risk

router = APIRouter()

class AnalysisInput(BaseModel):
    memory_score: int
    speech_features: dict

@router.post("/analyze")
def analyze(data: AnalysisInput):
    result = calculate_risk(data.memory_score, data.speech_features)
    return result
