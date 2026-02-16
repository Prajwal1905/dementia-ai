from sqlalchemy import Column, Integer, Float, String, DateTime
from datetime import datetime
from app.db import Base

class Assessment(Base):
    __tablename__ = "assessments"

    id = Column(Integer, primary_key=True, index=True)

    memory_score = Column(Float)
    time_taken = Column(Float)          # NEW

    avg_sentence_length = Column(Float)
    vocab_richness = Column(Float)
    hesitation_ratio = Column(Float)
    repetition_ratio = Column(Float)

    decline_rate = Column(Float)        # NEW

    ml_prediction = Column(Integer)
    confidence = Column(Float)

    risk_level = Column(String)

    created_at = Column(DateTime, default=datetime.utcnow)