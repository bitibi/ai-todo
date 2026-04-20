import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HttpClient, HttpHeaders } from '@angular/common/http';
import { environment } from '../../../environments/environment';

@Component({
  selector: 'app-voice-input',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './voice-input.html',
  styleUrl: './voice-input.scss'
})
export class VoiceInputComponent {
  private http = inject(HttpClient);

  isRecording = signal(false);
  isProcessing = signal(false);
  transcript = signal<string | null>(null);
  error = signal<string | null>(null);

  private mediaRecorder: MediaRecorder | null = null;
  private audioChunks: Blob[] = [];
  private recordingTimeout: any = null;

  async toggleRecording(): Promise<void> {
    if (this.isRecording()) {
      this.stopRecording();
    } else {
      await this.startRecording();
    }
  }

  private async startRecording(): Promise<void> {
    this.error.set(null);
    this.transcript.set(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(stream);
      this.mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) this.audioChunks.push(e.data);
      };
      this.mediaRecorder.onstop = () => {
        stream.getTracks().forEach(t => t.stop());
        this.sendAudio();
      };
      this.mediaRecorder.start();
      this.isRecording.set(true);
      // Auto-stop after 60 seconds
      this.recordingTimeout = setTimeout(() => this.stopRecording(), 60000);
    } catch (err) {
      this.error.set('Microphone access denied. Please allow microphone access and try again.');
    }
  }

  private stopRecording(): void {
    clearTimeout(this.recordingTimeout);
    this.mediaRecorder?.stop();
    this.isRecording.set(false);
    this.isProcessing.set(true);
  }

  private sendAudio(): void {
    const mimeType = this.mediaRecorder?.mimeType || 'audio/webm';
    const extension = mimeType.includes('ogg') ? 'ogg' : mimeType.includes('mp4') ? 'mp4' : 'webm';
    const blob = new Blob(this.audioChunks, { type: mimeType });
    const formData = new FormData();
    formData.append('audio', blob, `recording.${extension}`);

    const token = localStorage.getItem('todo_token');
    const headers = token ? new HttpHeaders({ Authorization: `Bearer ${token}` }) : new HttpHeaders();

    this.http.post<{ text: string }>(`${environment.apiUrl}/ai/transcribe`, formData, { headers })
      .subscribe({
        next: (res) => {
          this.isProcessing.set(false);
          this.transcript.set(res.text);
        },
        error: (err) => {
          this.isProcessing.set(false);
          this.error.set(err?.error?.detail || 'Transcription failed. Please try again.');
        }
      });
  }

  closePopup(): void {
    this.transcript.set(null);
    this.error.set(null);
  }
}
