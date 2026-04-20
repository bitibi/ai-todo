import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { tap, catchError, map } from 'rxjs/operators';
import { ApiService } from './api.service';
import { User, AuthResponse } from '../models/todo.models';

@Injectable({ providedIn: 'root' })
export class AuthService {
  private api = inject(ApiService);

  private _currentUser$ = new BehaviorSubject<User | null>(null);
  private _isAuthenticated$ = new BehaviorSubject<boolean>(false);
  private _sessionReady$ = new BehaviorSubject<boolean>(false);

  readonly currentUser$ = this._currentUser$.asObservable();
  readonly isAuthenticated$ = this._isAuthenticated$.asObservable();
  /** Emits `true` once the initial session-restore attempt has completed (success or failure). */
  readonly sessionReady$ = this._sessionReady$.asObservable();

  private readonly TOKEN_KEY = 'todo_token';
  private readonly USER_KEY = 'todo_user';

  constructor() {
    // Rehydrate from localStorage on service init — no network round-trip
    // required. If the stored token is stale, the first real API call will
    // return 401 and the auth interceptor will clear the session.
    const token = localStorage.getItem(this.TOKEN_KEY);
    const userRaw = localStorage.getItem(this.USER_KEY);
    if (token && userRaw) {
      try {
        const user = JSON.parse(userRaw) as User;
        this._currentUser$.next(user);
        this._isAuthenticated$.next(true);
      } catch {
        localStorage.removeItem(this.USER_KEY);
      }
    }
    this._sessionReady$.next(true);
  }

  login(email: string, password: string): Observable<AuthResponse> {
    return this.api.post<AuthResponse>('/auth/login', { email, password }).pipe(
      tap(response => {
        localStorage.setItem(this.TOKEN_KEY, response.access_token);
        localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
        this._currentUser$.next(response.user);
        this._isAuthenticated$.next(true);
      })
    );
  }

  register(email: string, password: string, full_name?: string): Observable<AuthResponse> {
    return this.api.post<AuthResponse>('/auth/register', { email, password, full_name }).pipe(
      tap(response => {
        localStorage.setItem(this.TOKEN_KEY, response.access_token);
        localStorage.setItem(this.USER_KEY, JSON.stringify(response.user));
        this._currentUser$.next(response.user);
        this._isAuthenticated$.next(true);
      })
    );
  }

  logout(): Observable<unknown> {
    return this.api.post('/auth/logout').pipe(
      tap(() => this.clearSession()),
      catchError(() => {
        // Even if server fails, clear local session
        this.clearSession();
        return of(null);
      })
    );
  }

  clearSession(): void {
    localStorage.removeItem(this.TOKEN_KEY);
    localStorage.removeItem(this.USER_KEY);
    this._currentUser$.next(null);
    this._isAuthenticated$.next(false);
  }

  isLoggedIn(): boolean {
    return this._isAuthenticated$.getValue();
  }

  hasStoredToken(): boolean {
    return !!localStorage.getItem(this.TOKEN_KEY);
  }
}
