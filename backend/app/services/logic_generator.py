import random


# ---------------- REASONING ----------------
def generate_reasoning(difficulty):
    type_choice = random.choice(["story", "pattern"])

    # ---------- STORY ----------
    if type_choice == "story":
        people = ["Ravi", "Amit", "Suresh", "Karan"]
        random.shuffle(people)

        if difficulty == 1:
            q = f"{people[0]} has more money than {people[1]}. Who has more money?"
            ans = people[0]

        elif difficulty == 2:
            q = f"{people[0]} is older than {people[1]}, and {people[1]} is older than {people[2]}. Who is youngest?"
            ans = people[2]

        else:
            q = (
                f"{people[0]} is taller than {people[1]}, "
                f"{people[1]} is taller than {people[2]}, "
                f"{people[2]} is taller than {people[3]}. "
                f"Who is second shortest?"
            )
            ans = people[2]

    # ---------- PATTERN ----------
    else:
        if difficulty == 1:
            # simple arithmetic
            start = random.randint(1, 10)
            diff = random.randint(2, 5)
            seq = [start + i * diff for i in range(4)]
            ans = seq[-1] + diff

        elif difficulty == 2:
            # geometric
            start = random.randint(1, 5)
            ratio = random.randint(2, 3)
            seq = [start * (ratio ** i) for i in range(4)]
            ans = seq[-1] * ratio

        else:
            # mixed hard 
            start = random.randint(1, 10)
            seq = [start]
            for i in range(1, 4):
                seq.append(seq[-1] + i * 2)
            ans = seq[-1] + 4 * 2

        q = f"Find next number: {', '.join(map(str, seq))}"

    return {
        "question": q,
        "answer": str(ans).lower(),
        "type": "reasoning",
        "difficulty": difficulty
    }

# ---------------- MATH ----------------
def generate_math(difficulty):
    if difficulty == 1:
        a, b = random.randint(1, 50), random.randint(1, 50)
        q = f"{a} + {b} = ?"
        ans = a + b

    elif difficulty == 2:
        a, b = random.randint(10, 100), random.randint(5, 50)
        q = f"{a} - {b} = ?"
        ans = a - b

    else:
        a, b = random.randint(2, 20), random.randint(2, 20)
        q = f"{a} × {b} = ?"
        ans = a * b

    return {
        "question": q,
        "answer": str(ans),
        "type": "math",
        "difficulty": difficulty
    }


# ---------------- CLOCK ----------------
def generate_clock(difficulty):
    hour = random.randint(1, 12)
    minute = random.choice([0, 15, 30, 45])

    if difficulty == 1:
        add = random.choice([15, 30])
    elif difficulty == 2:
        add = random.choice([30, 45, 60])
    else:
        add = random.choice([60, 90, 120])

    total = hour * 60 + minute + add

    new_hour = (total // 60) % 12
    if new_hour == 0:
        new_hour = 12

    new_min = total % 60

    q = f"What time is {add} minutes after {hour}:{str(minute).zfill(2)}?"
    ans = f"{new_hour}:{str(new_min).zfill(2)}"

    return {
        "question": q,
        "answer": ans,
        "type": "clock",
        "difficulty": difficulty
    }


# ---------------- MAIN GENERATOR ----------------
def generate_question_set():
    questions = []

    # 2 reasoning
    questions.append(generate_reasoning(1))
    questions.append(generate_reasoning(2))

    # 2 math
    questions.append(generate_math(1))
    questions.append(generate_math(2))

    # 2 clock
    questions.append(generate_clock(1))
    questions.append(generate_clock(2))

    random.shuffle(questions)

    return questions