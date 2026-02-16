import pandas as pd
from sqlalchemy import create_engine
from sklearn.ensemble import RandomForestClassifier
import joblib

# DB connection
engine = create_engine("postgresql://postgres:postgres123@localhost:5432/dementia_ai")

# Load data
df = pd.read_sql("SELECT * FROM assessments", engine)

if len(df) < 6:
    print("Not enough data to train")
    exit()

# Label creation rule (bootstrap)
def create_label(row):
    if row["memory_score"] >= 70 and row["decline_rate"] <= 5:
        return 0
    elif row["memory_score"] >= 40:
        return 1
    else:
        return 2

df["label"] = df.apply(create_label, axis=1)

# Features
X = df[[
    "memory_score",
    "time_taken",
    "avg_sentence_length",
    "vocab_richness",
    "hesitation_ratio",
    "repetition_ratio",
    "decline_rate"
]]

y = df["label"]

# Train model
model = RandomForestClassifier(n_estimators=200, max_depth=5)
model.fit(X, y)

# Save model
joblib.dump(model, "ml_model.pkl")

print("Model trained successfully on", len(df), "records")
