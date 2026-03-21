import torch
import torchaudio
from transformers import Wav2Vec2Processor, Wav2Vec2ForCTC
from pydub import AudioSegment
import os

processor = Wav2Vec2Processor.from_pretrained("facebook/wav2vec2-base-960h")
model = Wav2Vec2ForCTC.from_pretrained("facebook/wav2vec2-base-960h")


# ---------- CONVERT AUDIO ----------
def convert_to_wav(input_path):
    output_path = input_path.replace(".aac", ".wav")

    audio = AudioSegment.from_file(input_path)
    audio = audio.set_frame_rate(16000).set_channels(1)
    audio.export(output_path, format="wav")

    return output_path


# ---------- EXTRACT FEATURES ----------
def extract_audio_features(audio_path):
    wav_path = convert_to_wav(audio_path)

    waveform, sample_rate = torchaudio.load(wav_path)

    if sample_rate != 16000:
        resampler = torchaudio.transforms.Resample(
            orig_freq=sample_rate,
            new_freq=16000
        )
        waveform = resampler(waveform)

    input_values = processor(
        waveform.squeeze(),
        return_tensors="pt",
        sampling_rate=16000
    ).input_values

    with torch.no_grad():
        logits = model(input_values).logits

    predicted_ids = torch.argmax(logits, dim=-1)
    transcription = processor.batch_decode(predicted_ids)[0]

    print(" WAV2VEC TRANSCRIPT:", transcription)

    words = transcription.lower().split()
    word_count = len(words)

    # ---------- HESITATION ----------
    hesitations = ["um", "uh", "hmm", "erm", "ah"]
    hesitation_count = sum(words.count(h) for h in hesitations)
    hesitation_ratio = hesitation_count / max(word_count, 1)

    # ---------- REPETITION ----------
    repeated = sum(
        1 for i in range(1, len(words))
        if words[i] == words[i - 1]
    )
    repetition_ratio = repeated / max(word_count, 1)

    # cleanup temp wav
    if os.path.exists(wav_path):
        os.remove(wav_path)

    return {
        "transcription": transcription,
        "word_count": word_count,
        "hesitation_ratio": hesitation_ratio,
        "repetition_ratio": repetition_ratio
    }