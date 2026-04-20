import { Injectable, inject } from '@angular/core';
import { BehaviorSubject, Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import { ApiService } from './api.service';
import { TodoList, CreateListPayload, ReorderItem } from '../models/todo.models';

@Injectable({ providedIn: 'root' })
export class ListService {
  private api = inject(ApiService);

  private _lists$ = new BehaviorSubject<TodoList[]>([]);
  readonly lists$ = this._lists$.asObservable();

  loadLists(): void {
    this.api.get<TodoList[]>('/lists').pipe(
      tap(lists => this._lists$.next(lists))
    ).subscribe({
      error: err => console.error('Failed to load lists', err)
    });
  }

  createList(data: CreateListPayload): Observable<TodoList> {
    return this.api.post<TodoList>('/lists', data).pipe(
      tap(newList => {
        const current = this._lists$.getValue();
        this._lists$.next([...current, newList]);
      })
    );
  }

  updateList(id: string, data: Partial<CreateListPayload>): Observable<TodoList> {
    return this.api.patch<TodoList>(`/lists/${id}`, data).pipe(
      tap(updated => {
        const current = this._lists$.getValue();
        this._lists$.next(current.map(l => (l.id === id ? updated : l)));
      })
    );
  }

  deleteList(id: string): Observable<unknown> {
    return this.api.delete(`/lists/${id}`).pipe(
      tap(() => {
        const current = this._lists$.getValue();
        this._lists$.next(current.filter(l => l.id !== id));
      })
    );
  }

  reorderLists(items: ReorderItem[]): Observable<unknown> {
    return this.api.patch('/lists/reorder', items);
  }

  getListWithDetails(id: string): Observable<TodoList> {
    // Backend returns list with sections and tasks when fetching by id
    return this.api.get<TodoList>(`/lists/${id}`);
  }
}
