def generate_explanation(features):

    reasons = []

    # memory performance
    if features["memory_score"] <= 50:
        reasons.append("Below-average memory recall performance")

    # decline trend
    if features["decline_rate"] >= 5:
        reasons.append("Recent decline in cognitive performance")

    # response speed
    if features["time_taken"] >= 18:
        reasons.append("Slower response time than expected")

    # speech quality
    if features["vocab_richness"] < 0.7:
        reasons.append("Reduced vocabulary diversity")

    if features["hesitation_ratio"] > 0.02:
        reasons.append("Frequent pauses while speaking")

    if features["repetition_ratio"] > 0.02:
        reasons.append("Repetition in speech patterns")

    # fallback
    if not reasons:
        reasons.append("Pattern resembles learned high-risk behavioural profile")

    return reasons
