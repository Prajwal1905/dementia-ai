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

    # -------- DECLINE 
    if decline > 15:
        insights.append("Cognitive decline trend detected over time")
    elif decline > 5:
        insights.append("Slight decline observed compared to baseline")
    else:
        insights.append("Performance stable compared to baseline")

    # -------- SPEECH 
    if hesitation > 0.2:
        insights.append("Frequent pauses detected in speech")
    elif hesitation > 0.1:
        insights.append("Mild hesitation observed during speech")

    if repetition > 0.15:
        insights.append("Repetition in speech patterns detected")

    if hesitation < 0.1 and repetition < 0.1:
        insights.append("Speech patterns are fluent and natural")

    # -------- VOCAB --------
    if vocab > 0.7:
        insights.append("Good vocabulary richness")
    else:
        insights.append("Limited vocabulary usage")

    # -------- SUMMARY
    if decline > 15:
        summary = "Noticeable cognitive decline detected with speech irregularities."
    elif decline > 5:
        summary = "Mild cognitive decline observed with minor speech hesitation."
    else:
        summary = "Cognitive performance remains stable with minor speech variations."

    # -------- RECOMMENDATION --------
    if decline > 15:
        recommendation = "Monitor weekly and consult a neurologist if decline continues"
    elif decline > 5:
        recommendation = "Track cognitive performance regularly and maintain cognitive exercises"
    else:
        recommendation = "Maintain regular cognitive exercises and a healthy routine"

    return {
        "summary": summary,
        "insights": insights,
        "recommendation": recommendation
    }