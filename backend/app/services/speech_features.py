import whisper
import re

model = whisper.load_model("base")

def transcribe_audio(path):
    result = model.transcribe(path)
    return result["text"]


def extract_features(text):
    text = text.lower()

    words = text.split()
    word_count = len(words)

    # sentences
    sentences = re.split(r'[.!?]', text)
    sentences = [s for s in sentences if s.strip() != ""]
    avg_sentence_length = word_count / max(len(sentences), 1)

    # vocabulary richness
    unique_words = len(set(words))
    vocab_richness = unique_words / max(word_count, 1)

    # hesitation detection
    hesitations = ["um","uh","hmm","erm","ah"]
    hesitation_count = sum(words.count(h) for h in hesitations)
    hesitation_ratio = hesitation_count / max(word_count, 1)

    # repetition detection
    repeated = sum(words[i] == words[i-1] for i in range(1, len(words)))
    repetition_ratio = repeated / max(word_count, 1)

    return {
        "word_count": word_count,
        "avg_sentence_length": avg_sentence_length,
        "vocab_richness": vocab_richness,
        "hesitation_ratio": hesitation_ratio,
        "repetition_ratio": repetition_ratio
    }
