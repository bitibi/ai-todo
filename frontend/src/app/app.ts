import { Component } from '@angular/core';
import { RouterOutlet } from '@angular/router';
import { VoiceInputComponent } from './components/voice-input/voice-input';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [RouterOutlet, VoiceInputComponent],
  template: `<router-outlet /><app-voice-input />`,
  styles: []
})
export class App {}
