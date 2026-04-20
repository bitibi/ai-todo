import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiService } from './api.service';
import { Task, CreateTaskPayload, ReorderItem } from '../models/todo.models';

export interface TaskFilters {
  list_id?: string;
  section_id?: string;
  priority?: string;
  is_completed?: boolean;
}

@Injectable({ providedIn: 'root' })
export class TaskService {
  private api = inject(ApiService);

  getTasks(filters: TaskFilters = {}): Observable<Task[]> {
    const params = new URLSearchParams();
    if (filters.list_id) params.set('list_id', filters.list_id);
    if (filters.section_id) params.set('section_id', filters.section_id);
    if (filters.priority) params.set('priority', filters.priority);
    if (filters.is_completed !== undefined) {
      params.set('is_completed', String(filters.is_completed));
    }
    const query = params.toString();
    return this.api.get<Task[]>(`/tasks${query ? '?' + query : ''}`);
  }

  createTask(data: CreateTaskPayload): Observable<Task> {
    return this.api.post<Task>('/tasks', data);
  }

  updateTask(id: string, data: Partial<CreateTaskPayload>): Observable<Task> {
    return this.api.patch<Task>(`/tasks/${id}`, data);
  }

  deleteTask(id: string): Observable<unknown> {
    return this.api.delete(`/tasks/${id}`);
  }

  completeTask(id: string): Observable<Task> {
    return this.api.post<Task>(`/tasks/${id}/complete`);
  }

  uncompleteTask(id: string): Observable<Task> {
    return this.api.post<Task>(`/tasks/${id}/uncomplete`);
  }

  reorderTasks(items: ReorderItem[]): Observable<unknown> {
    return this.api.patch('/tasks/reorder', items);
  }
}
