def calculate_risk(memory_score, speech_features):

    risk = 0

    # Memory contribution (0–40)
    if memory_score < 40:
        risk += 40
    elif memory_score < 60:
        risk += 25
    else:
        risk += 5

    # Speech sentence length (0–30)
    if speech_features["avg_sentence_length"] < 5:
        risk += 30
    elif speech_features["avg_sentence_length"] < 8:
        risk += 15
    else:
        risk += 5

    # Vocabulary richness (0–30)
    if speech_features["vocab_richness"] < 0.4:
        risk += 30
    elif speech_features["vocab_richness"] < 0.6:
        risk += 15
    else:
        risk += 5

    # Final category
    if risk < 35:
        level = "Low Risk"
    elif risk < 65:
        level = "Mild Cognitive Concern"
    else:
        level = "High Risk — Clinical Check Recommended"

    return {"risk_score": risk, "risk_level": level}
