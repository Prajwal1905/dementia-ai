from passlib.context import CryptContext
import unicodedata

pwd_context = CryptContext(schemes=["pbkdf2_sha256"], deprecated="auto")

def normalize(text: str) -> str:
    # prevents mobile vs browser encoding differences
    return unicodedata.normalize("NFKC", text.strip())

def hash_password(password: str):
    return pwd_context.hash(normalize(password))

def verify_password(password: str, hashed: str):
    return pwd_context.verify(normalize(password), hashed)
