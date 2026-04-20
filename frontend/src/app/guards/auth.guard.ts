import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { AuthService } from '../services/auth.service';

/**
 * Optimistic auth guard.
 *
 * A valid-looking token in localStorage is enough to let the user in. If the
 * token is actually expired/invalid, the first API call will get a 401 and
 * the auth interceptor will wipe the session and redirect to /login.
 * This avoids blocking navigation on a synchronous round-trip to /auth/me.
 */
export const authGuard: CanActivateFn = () => {
  const auth = inject(AuthService);
  const router = inject(Router);

  if (auth.hasStoredToken() || auth.isLoggedIn()) {
    return true;
  }
  return router.createUrlTree(['/login']);
};
