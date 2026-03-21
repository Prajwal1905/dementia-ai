def generate_explanation(data):
    memory = data["memory_score"]
    decline = data["decline_rate"]
    hesitation = data["hesitation_ratio"]
    repetition = data["repetition_ratio"]
    vocab = data["vocab_richness"]

    insights = []

    # -------- MEMORY --------
    if memory >= 80:
        insights.append("Memory performance is strong")
    elif memory >= 60:
        insights.append("Memory performance is average")
    else:
        insights.append("Memory recall is below expected")

    # -------- DECLINE --------
    if decline > 15:
        insights.append("Noticeable decline compared to baseline")
    elif decline > 5:
        insights.append("Slight decline observed")
    else:
        insights.append("No significant cognitive decline detected")

    # -------- SPEECH --------
    if hesitation < 0.02 and repetition < 0.02:
        insights.append("Speech patterns are fluent and normal")
    else:
        insights.append("Speech shows hesitation or repetition")

    if vocab > 0.7:
        insights.append("Good vocabulary richness")
    else:
        insights.append("Limited vocabulary usage")

    # -------- SUMMARY --------
    if decline > 15:
        summary = "Moderate cognitive decline detected"
    elif decline > 5:
        summary = "Mild cognitive changes observed"
    else:
        summary = "Cognitive performance appears stable"

    # -------- RECOMMENDATION --------
    if decline > 15:
        recommendation = "Monitor weekly and consult a neurologist if decline continues"
    elif decline > 5:
        recommendation = "Track cognitive performance regularly"
    else:
        recommendation = "Maintain regular cognitive exercises"

    return {
        "summary": summary,
        "insights": insights,
        "recommendation": recommendation
    }