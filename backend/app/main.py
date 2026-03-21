from fastapi import FastAPI
from app.routes import report,speech,full_assessment,history,auth,memory
from app.db import engine, Base
from app.models.assessment import Assessment
from app.services.speech_features import get_model

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Dementia Risk Detection API")


app.include_router(speech.router)   
app.include_router(report.router)
app.include_router(full_assessment.router)
app.include_router(history.router)
app.include_router(auth.router)
app.include_router(memory.router)


@app.get("/")
def home():
    return {"message": "AI Dementia Detection Running"}

@app.on_event("startup")
def load_whisper():
    print(" Preloading Whisper model...")
    get_model()