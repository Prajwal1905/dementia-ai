def calculate_memory_score(shown_words, recalled_words, time_taken):
    shown = [w.strip().lower() for w in shown_words]
    recalled = [w.strip().lower() for w in recalled_words]

    correct = sum(1 for w in recalled if w in shown)

    score = correct * 20

    if time_taken > 30:
        score -= 10

    return max(score, 0), correct