from fastapi import FastAPI
from app.routes import cognitive,report,speech,full_assessment,history
from app.db import engine, Base
from app.models.assessment import Assessment

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Dementia Risk Detection API")

app.include_router(cognitive.router)
app.include_router(speech.router)   
app.include_router(report.router)
app.include_router(full_assessment.router)
app.include_router(history.router)

@app.get("/")
def home():
    return {"message": "AI Dementia Detection Running"}
