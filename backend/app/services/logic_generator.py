import random


def generate_math(difficulty):
    if difficulty == 1:
        a = random.randint(50, 150)
        b = random.randint(10, 40)
        question = f"You have ₹{a}. You spend ₹{b}. How much is left?"
        answer = a - b

    elif difficulty == 2:
        a = random.randint(100, 300)
        b = random.randint(20, 80)
        c = random.randint(10, 50)
        question = f"You had ₹{a}. You spent ₹{b} and ₹{c}. How much is left?"
        answer = a - b - c

    else:
        a = random.randint(200, 500)
        b = random.randint(20, 100)
        c = random.randint(20, 100)
        d = random.randint(10, 50)
        question = f"You had ₹{a}. You spent ₹{b}, ₹{c}, and ₹{d}. How much is left?"
        answer = a - b - c - d

    return question, answer


def generate_time(difficulty):
    start = random.randint(6, 10)

    if difficulty == 1:
        add = random.randint(1, 2)
        question = f"You woke up at {start} AM. After {add} hours, what time is it?"
        answer = f"{start + add}:00"

    elif difficulty == 2:
        add1 = random.randint(1, 3)
        add2 = random.choice([15, 30, 45])
        question = f"You woke at {start} AM. After {add1} hours and {add2} minutes, what time is it?"
        answer = f"{start + add1}:{add2:02d}"

    else:
        add1 = random.randint(1, 3)
        add2 = random.choice([15, 30, 45])
        add3 = random.choice([10, 20])
        question = f"You woke at {start} AM. After {add1} hours, {add2} minutes, and {add3} minutes more, what time is it?"

        total_minutes = add2 + add3
        extra_hour = total_minutes // 60
        minutes = total_minutes % 60

        answer = f"{start + add1 + extra_hour}:{minutes:02d}"

    return question, answer


def generate_logic(difficulty):
    if difficulty == 1:
        question = "Apple, Banana, Car, Mango. Which is different?"
        answer = "Car"

    elif difficulty == 2:
        question = "Rahul is older than Amit. Amit is older than John. Who is youngest?"
        answer = "John"

    else:
        question = "A is older than B. B is older than C. C is older than D. Who is second oldest?"
        answer = "B"

    return question, answer


def generate_question(difficulty=1):
    q_type = random.choice(["math", "time", "logic"])

    if q_type == "math":
        question, answer = generate_math(difficulty)
    elif q_type == "time":
        question, answer = generate_time(difficulty)
    else:
        question, answer = generate_logic(difficulty)

    return {
        "type": q_type,
        "difficulty": difficulty,
        "question": question,
        "answer": answer
    }