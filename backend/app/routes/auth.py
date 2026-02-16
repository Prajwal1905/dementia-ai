from fastapi import APIRouter, HTTPException, Request
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

    email = data.email.strip().lower()
    password = data.password.strip()

    if db.query(User).filter(User.email == email).first():
        raise HTTPException(status_code=400, detail="Email already registered")

    user = User(
        name=data.name.strip(),
        email=email,
        password_hash=hash_password(password)
    )

    db.add(user)
    db.commit()
    db.close()

    return {"message": "User created"}

class LoginInput(BaseModel):
    email: str
    password: str

@router.post("/login")
async def login(data: LoginInput, request: Request):

    raw = await request.body()
    print("RAW BODY FROM PHONE:", raw)

    email = data.email
    password = data.password

    print("PARSED EMAIL:", repr(email))
    print("PARSED PASSWORD:", repr(password))

    db = SessionLocal()
    user = db.query(User).filter(User.email == email).first()
    db.close()

    if not user or not verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    token = create_token(user.id)
    return {"token": token, "user_id": user.id}
