def compute_cognitive_score(memory_score, speech_score, decline_rate):
    """
    Central brain function for cognitive scoring (0–100 safe, realistic)
    """

    # ---------- DECLINE SCORE ----------
    if decline_rate <= 5:
        decline_score = 100
    elif decline_rate <= 15:
        decline_score = 70
    else:
        decline_score = 40

    # ---------- FINAL SCORE ----------
    final_score = (
        memory_score * 0.4 +
        speech_score * 0.3 +
        decline_score * 0.3
    )

    #  Clamp score (VERY IMPORTANT)
    final_score = int(max(0, min(100, final_score)))

    # ---------- RISK (IMPROVED LOGIC) ----------
    # Priority to memory (clinical relevance)
    if memory_score < 50:
        risk = "Mild Cognitive Impairment"
    elif final_score >= 75:
        risk = "Normal"
    elif final_score >= 50:
        risk = "Mild Cognitive Impairment"
    else:
        risk = "High Dementia Risk"

    return {
        "final_score": final_score,
        "risk": risk,
        "decline_score": decline_score
    }