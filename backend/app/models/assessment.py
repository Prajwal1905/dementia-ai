from sqlalchemy import Column, Integer, Float, String, DateTime, ForeignKey
from datetime import datetime
from app.db import Base

class Assessment(Base):
    __tablename__ = "assessments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    memory_score = Column(Float)
    time_taken = Column(Float)          

    avg_sentence_length = Column(Float)
    vocab_richness = Column(Float)
    hesitation_ratio = Column(Float)
    repetition_ratio = Column(Float)

    decline_rate = Column(Float)        

    ml_prediction = Column(Integer)
    confidence = Column(Float)

    risk_level = Column(String)
    cognitive_score = Column(Integer)
    trend = Column(String, nullable=True)
    change = Column(Float, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)