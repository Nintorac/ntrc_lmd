# Initialize FluidSynth for MIDI to audio conversion
from midi2audio import FluidSynth
import subprocess
import os
import tempfile

def render_midi_to_audio(midi_bytes, output_dir, filename, fs=16000):
    """Convert MIDI bytes to OGG audio at 16kHz and save to specified directory"""
    # Ensure output directory exists
    os.makedirs(output_dir, exist_ok=True)
    
    synth = FluidSynth(sample_rate=fs)
    with tempfile.TemporaryDirectory() as temp_dir:
        # Save MIDI bytes to temporary file
        midi_path = os.path.join(temp_dir, f"midi.mid")
        with open(midi_path, "wb") as f:
            f.write(midi_bytes)

        # Convert MIDI to WAV first (FluidSynth default)
        wav_path = os.path.join(temp_dir, f"audio.wav")
        synth.midi_to_audio(midi_path, wav_path)
        
        # Convert WAV to OGG using ffmpeg
        ogg_path = os.path.join(output_dir, f"{filename}.ogg")
        subprocess.run([
            'ffmpeg', '-i', wav_path, '-c:a', 'libvorbis', '-q:a', '4', 
            '-ar', str(fs), ogg_path, '-y'
        ], check=True, capture_output=True)

        return ogg_path