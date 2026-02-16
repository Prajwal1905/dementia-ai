import joblib
import pandas as pd
import os

MODEL_PATH = "ml/ml_model.pkl"

model = None

def load_model():
    global model
    if model is None and os.path.exists(MODEL_PATH):
        model = joblib.load(MODEL_PATH)
    return model


def predict_risk(features_dict):

    model = load_model()
    if model is None:
        return None, None

    # Use DataFrame with column names (fix warning)
    X = pd.DataFrame([{
        "memory_score": features_dict["memory_score"],
        "time_taken": features_dict["time_taken"],
        "avg_sentence_length": features_dict["avg_sentence_length"],
        "vocab_richness": features_dict["vocab_richness"],
        "hesitation_ratio": features_dict["hesitation_ratio"],
        "repetition_ratio": features_dict["repetition_ratio"],
        "decline_rate": features_dict["decline_rate"]
    }])

    prediction = int(model.predict(X)[0])
    confidence = float(model.predict_proba(X)[0].max())

    return prediction, confidence
