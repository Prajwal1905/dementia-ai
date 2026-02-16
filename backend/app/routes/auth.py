from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from app.db import SessionLocal
from app.models.user import User
from app.services.security import hash_password, verify_password
from app.services.auth_handler import create_token

router = APIRouter(prefix="/auth")

class RegisterInput(BaseModel):
    name: str
    email: str
    password: str

@router.post("/register")
def register(data: RegisterInput):
    db = SessionLocal()

    if db.query(User).filter(User.email == data.email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password)
    )

    db.add(user)
    db.commit()
    db.close()

    return {"message": "User created"}


class LoginInput(BaseModel):
    email: str
    password: str

@router.post("/login")
def login(data: LoginInput):
    db = SessionLocal()
    user = db.query(User).filter(User.email == data.email).first()
    db.close()

    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_token(user.id)

    return {"token": token, "user_id": user.id}
