import os
from dotenv import load_dotenv
from jose import jwt
from datetime import datetime, timedelta

load_dotenv()

SECRET = os.getenv("SECRET_KEY")
ALGORITHM = "HS256"

def create_token(user_id: int):
    payload = {
        "sub": str(user_id),
        "exp": datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(payload, SECRET, algorithm=ALGORITHM)