import whisper
import re
import numpy as np
import torchaudio
from pydub import AudioSegment
import os
from collections import Counter

model = None


# ---------- LOAD MODEL ----------
def get_model():
    global model
    if model is None:
        print(" Loading Whisper model...")
        model = whisper.load_model("tiny")
    else:
        print(" Whisper already loaded")
    return model


# ---------- PAUSE DETECTION ----------
def detect_pauses(audio_path):
    wav_path = audio_path.replace(".aac", ".wav")

    audio = AudioSegment.from_file(audio_path)
    audio = audio.set_frame_rate(16000).set_channels(1)
    audio.export(wav_path, format="wav")

    waveform, sample_rate = torchaudio.load(wav_path)

    signal = waveform.numpy().flatten()
    signal = signal / (np.max(np.abs(signal)) + 1e-6)

    silence_threshold = 0.02
    silence = np.abs(signal) < silence_threshold

    pause_ratio = np.sum(silence) / len(signal)

    if os.path.exists(wav_path):
        os.remove(wav_path)

    return pause_ratio


# ---------- TRANSCRIBE ----------
def transcribe_audio(path):
    model = get_model()
    result = model.transcribe(path, fp16=False)
    text = result["text"]

    print(" TRANSCRIPT:", text)
    return text


# ---------- CLEAN ----------
def clean_words(text):
    return re.findall(r'\b[a-zA-Z]+\b', text.lower())


# ---------- FEATURE EXTRACTION ----------
def extract_features(text, audio_path):
    words = clean_words(text)
    word_count = len(words)

    print(" WORDS:", words)

    # ---------- SENTENCES ----------
    sentences = re.split(r'[.!?]', text)
    sentences = [s for s in sentences if s.strip() != ""]
    avg_sentence_length = word_count / max(len(sentences), 1)

    # ---------- VOCAB ----------
    unique_words = len(set(words))
    vocab_richness = unique_words / max(word_count, 1)

    # ---------- HESITATION ----------
    hesitation_ratio = detect_pauses(audio_path)

    # ---------- REPETITION 
    word_counts = Counter(words)
    repeated_words = sum(count - 1 for count in word_counts.values() if count > 1)
    repetition_ratio = repeated_words / max(word_count, 1)

    # ---------- SPEECH SCORE ----------
    speech_score = 100

    if hesitation_ratio > 0.3:
        speech_score -= 40
    elif hesitation_ratio > 0.1:
        speech_score -= 20

    if repetition_ratio > 0.2:
        speech_score -= 30

    if vocab_richness < 0.5:
        speech_score -= 20

    speech_score = max(0, speech_score)

    return {
        "word_count": word_count,
        "avg_sentence_length": float(avg_sentence_length),
        "vocab_richness": float(vocab_richness),
        "hesitation_ratio": float(hesitation_ratio),
        "repetition_ratio": float(repetition_ratio),
        "speech_score": int(speech_score)
    }