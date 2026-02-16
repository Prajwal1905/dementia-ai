import subprocess
from sqlalchemy import create_engine, text

DB_URL = "postgresql://postgres:postgres123@localhost:5432/dementia_ai"

def retrain_if_needed():

    engine = create_engine(DB_URL)

    with engine.connect() as conn:
        count = conn.execute(text("SELECT COUNT(*) FROM assessments")).scalar()

    # retrain every 10 records
    if count % 10 == 0 and count != 0:
        subprocess.Popen(["python", "ml/train_from_db.py"])
