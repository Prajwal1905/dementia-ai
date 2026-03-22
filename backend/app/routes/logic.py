from fastapi import APIRouter
from app.services.logic_generator import generate_question
import time

router = APIRouter()

QUESTION_STORE = {}
SESSION_STORE= {}
@router.get("/logic/question")
def get_question(difficulty: int = 1):
    q = generate_question(difficulty)

    q_id = str(len(QUESTION_STORE) + 1)
    QUESTION_STORE[q_id] = q["answer"]

    return {
        "id": q_id,
        "type": q["type"],
        "difficulty": q["difficulty"],
        "question": q["question"]
    }

@router.post("/logic/answer")
def submit_answer(q_id: str, user_answer: str):
    correct_answer = QUESTION_STORE.get(q_id)

    if not correct_answer:
        return {"error": "Invalid question ID"}

    # normalize answers
    user = str(user_answer).strip().lower()
    correct = str(correct_answer).strip().lower()

    is_correct = user == correct

    score = 100 if is_correct else 0

    return {
        "correct": is_correct,
        "score": score,
        "correct_answer": correct_answer
    }

@router.post("/logic/start")
def start_session():
    session_id = str(len(SESSION_STORE) + 1)

    SESSION_STORE[session_id] = {
        "questions": [],
        "answers": [],
        "score": 0,
        "current_q": 0,
        "difficulty":1
    }

    return {"session_id": session_id}


@router.get("/logic/session/question")
def get_session_question(session_id: str):
    session = SESSION_STORE.get(session_id)

    if not session:
        return {"error": "Invalid session"}
    difficulty=session["difficulty"]

    q = generate_question(difficulty)

    q_id = f"{session_id}_{session['current_q']}"
    QUESTION_STORE[q_id] = q["answer"]

    session["questions"].append({
        "question":q,
        "start_time":time.time()
    })
    session["current_q"] += 1

    return {
        "q_id": q_id,
        "question": q["question"],
        "difficulty": q["difficulty"]
    }

@router.post("/logic/session/answer")
def submit_session_answer(session_id: str, q_id: str, user_answer: str):
    session = SESSION_STORE.get(session_id)

    if not session:
        return {"error": "Invalid session"}

    correct_answer = QUESTION_STORE.get(q_id)

    if not correct_answer:
        return {"error": "Invalid question"}

    # normalize
    user = str(user_answer).strip().lower()
    correct = str(correct_answer).strip().lower()

    is_correct = user == correct

    # GET LAST QUESTION DATA
    last_q = session["questions"][-1]

    start_time = last_q["start_time"]
    time_taken = time.time() - start_time

    difficulty = last_q["question"]["difficulty"]

    #  SMART SCORING
    if is_correct:
        base = 100

        # difficulty weight
        diff_weight = {1: 1, 2: 1.5, 3: 2}[difficulty]

        # time factor
        if time_taken < 5:
            time_factor = 1.2
        elif time_taken < 10:
            time_factor = 1.0
        else:
            time_factor = 0.8

        score = base * diff_weight * time_factor
    else:
        score = 0

    session["score"] += score

    session["answers"].append({
        "q_id": q_id,
        "correct": is_correct,
        "time_taken": round(time_taken, 2),
        "score": round(score, 2)
    })
     
    if is_correct:
        session["difficulty"]=min(3,session["difficulty"]+1)
    else:
        session["difficulty"]=max(1,session["difficulty"]-1)

    return {
        "correct": is_correct,
        "score_added": round(score, 2),
        "time_taken": round(time_taken, 2),
        "current_score": round(session["score"], 2),
        "difficulty": difficulty,
        "message": (
           "Excellent speed!"
           if is_correct and time_taken < 5
           else "Good"
           if is_correct
           else " Incorrect"
        )
    }

@router.get("/logic/session/result")
def get_session_result(session_id: str):
    session = SESSION_STORE.get(session_id)

    if not session:
        return {"error": "Invalid session"}

    total_questions = len(session["answers"])
    total_score = session["score"]

    avg_score = total_score / max(1, total_questions)

    return {
        "total_questions": total_questions,
        "logic_score": round(avg_score, 2),
        "raw_score": round(session["score"], 2)
    }