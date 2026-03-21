import whisper
import re

model = None  # global


# ---------- LOAD MODEL ----------
def get_model():
    global model
    if model is None:
        print(" Loading Whisper model...")
        model = whisper.load_model("tiny")  # fast + good enough
    else:
        print(" Whisper already loaded")
    return model


# ---------- TRANSCRIBE ----------
def transcribe_audio(path):
    model = get_model()
    result = model.transcribe(path)
    text = result["text"]

    print(" TRANSCRIPT:", text)  # DEBUG

    return text


# ---------- CLEAN TEXT ----------
def clean_words(text):
    # Extract only words (removes punctuation like "um...", "uh...")
    words = re.findall(r'\b[a-zA-Z]+\b', text.lower())
    return words


# ---------- FEATURE EXTRACTION ----------
def extract_features(text):
    words = clean_words(text)
    word_count = len(words)

    print(" WORDS:", words)  # DEBUG

    # ---------- SENTENCES ----------
    sentences = re.split(r'[.!?]', text)
    sentences = [s for s in sentences if s.strip() != ""]
    avg_sentence_length = word_count / max(len(sentences), 1)

    # ---------- VOCABULARY ----------
    unique_words = len(set(words))
    vocab_richness = unique_words / max(word_count, 1)

    # ---------- HESITATION DETECTION ----------
    hesitations = ["um", "uh", "hmm", "erm", "ah", "like"]

    hesitation_count = sum(
        1 for w in words if w in hesitations
    )

    hesitation_ratio = hesitation_count / max(word_count, 1)

    # ---------- REPETITION DETECTION ----------
    repeated = sum(
        1 for i in range(1, len(words)) if words[i] == words[i - 1]
    )

    repetition_ratio = repeated / max(word_count, 1)

    # ---------- NORMALIZE TO 0–100 SCORE ----------
    # (useful for scoring later)
    speech_score = 100

    if hesitation_ratio > 0.1:
        speech_score -= 30
    elif hesitation_ratio > 0.05:
        speech_score -= 15

    if repetition_ratio > 0.1:
        speech_score -= 30
    elif repetition_ratio > 0.05:
        speech_score -= 15

    if vocab_richness < 0.5:
        speech_score -= 20

    speech_score = max(0, speech_score)

    return {
        "word_count": word_count,
        "avg_sentence_length": avg_sentence_length,
        "vocab_richness": vocab_richness,
        "hesitation_ratio": hesitation_ratio,
        "repetition_ratio": repetition_ratio,
        "speech_score": speech_score,
        "is_valid_speech":False
    }