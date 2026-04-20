import { Component, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-register',
  standalone: true,
  imports: [CommonModule, FormsModule, RouterLink],
  templateUrl: './register.html',
  styleUrl: './register.scss'
})
export class RegisterComponent {
  private auth = inject(AuthService);
  private router = inject(Router);

  fullName = '';
  email = '';
  password = '';
  loading = signal(false);
  error = signal<string | null>(null);

  onSubmit(): void {
    if (!this.email || !this.password) {
      this.error.set('Please fill in all required fields.');
      return;
    }

    this.loading.set(true);
    this.error.set(null);

    this.auth.register(this.email, this.password, this.fullName || undefined).subscribe({
      next: () => this.router.navigate(['/']),
      error: err => {
        const msg = err?.error?.detail || 'Registration failed. Please try again.';
        this.error.set(msg);
        this.loading.set(false);
      }
    });
  }
}
