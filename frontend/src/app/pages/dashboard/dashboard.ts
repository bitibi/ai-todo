import { Component, OnInit, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';
import { forkJoin, of } from 'rxjs';
import { catchError } from 'rxjs/operators';
import { AuthService } from '../../services/auth.service';
import { ListService } from '../../services/list.service';
import { TaskService } from '../../services/task.service';
import { TodoList, Task } from '../../models/todo.models';
import { TaskItemComponent } from '../../components/task-item/task-item';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  imports: [CommonModule, FormsModule, TaskItemComponent],
  templateUrl: './dashboard.html',
  styleUrl: './dashboard.scss'
})
export class DashboardComponent implements OnInit {
  private auth = inject(AuthService);
  private listService = inject(ListService);
  private taskService = inject(TaskService);
  private router = inject(Router);

  lists = signal<TodoList[]>([]);
  urgentTasks = signal<Task[]>([]);
  loading = signal(true);
  urgentExpanded = signal(false);

  // New List modal state
  showNewListModal = signal(false);
  creatingList = signal(false);
  // Plain properties for ngModel two-way binding
  newListName = '';
  newListIcon = '📋';

  totalTaskCount = computed(() =>
    this.lists().reduce((sum, l) => sum + (l.tasks?.length ?? 0), 0)
  );

  totalEstimatedHours = computed(() => {
    let minutes = 0;
    for (const list of this.lists()) {
      for (const task of list.tasks ?? []) {
        const match = task.time_estimate?.match(/(\d+(?:\.\d+)?)\s*h/i);
        if (match) minutes += parseFloat(match[1]) * 60;
        const mMatch = task.time_estimate?.match(/(\d+)\s*m/i);
        if (mMatch) minutes += parseInt(mMatch[1]);
      }
    }
    return Math.round(minutes / 60 * 10) / 10;
  });

  currentUser$ = this.auth.currentUser$;

  ngOnInit(): void {
    this.loadData();
  }

  private loadData(): void {
    this.loading.set(true);
    // Load all lists; then for each list, fetch full details
    this.listService.lists$.subscribe(lists => {
      if (lists.length > 0) {
        this.loadListDetails(lists);
      } else {
        this.loading.set(false);
      }
    });

    this.listService.loadLists();

    // Also fetch urgent tasks directly
    this.taskService.getTasks({ priority: 'urgent', is_completed: false }).pipe(
      catchError(() => of([]))
    ).subscribe(tasks => this.urgentTasks.set(tasks));
  }

  private loadListDetails(lists: TodoList[]): void {
    // Load full details for each list (with tasks) in parallel
    const detailRequests = lists.map(l =>
      this.listService.getListWithDetails(l.id).pipe(catchError(() => of(l)))
    );

    forkJoin(detailRequests).subscribe(detailedLists => {
      this.lists.set(detailedLists);
      this.loading.set(false);
    });
  }

  navigateToList(list: TodoList): void {
    this.router.navigate(['/lists', list.id]);
  }

  toggleUrgentPanel(): void {
    this.urgentExpanded.update(v => !v);
  }

  logout(): void {
    this.auth.logout().subscribe(() => this.router.navigate(['/login']));
  }

  onTaskCompleted(task: Task): void {
    this.taskService.completeTask(task.id).subscribe(() => {
      this.urgentTasks.update(tasks => tasks.filter(t => t.id !== task.id));
    });
  }

  onTaskUncompleted(task: Task): void {
    this.taskService.uncompleteTask(task.id).subscribe();
  }

  onTaskDeleted(task: Task): void {
    this.taskService.deleteTask(task.id).subscribe(() => {
      this.urgentTasks.update(tasks => tasks.filter(t => t.id !== task.id));
    });
  }

  onTaskUpdated(event: { task: Task; changes: Partial<Task> }): void {
    this.taskService.updateTask(event.task.id, event.changes).subscribe(updated => {
      this.urgentTasks.update(tasks => tasks.map(t => t.id === updated.id ? updated : t));
      // If priority changed off urgent, remove from list
      if (updated.priority !== 'urgent') {
        this.urgentTasks.update(tasks => tasks.filter(t => t.id !== updated.id));
      }
    });
  }

  /** Returns an incomplete task count for a list (active tasks only) */
  activeTaskCount(list: TodoList): number {
    return (list.tasks ?? []).filter(t => !t.is_completed).length;
  }

  trackByListId(_: number, list: TodoList): string {
    return list.id;
  }

  trackByTaskId(_: number, task: Task): string {
    return task.id;
  }

  openNewListModal(): void {
    this.newListName = '';
    this.newListIcon = '📋';
    this.showNewListModal.set(true);
  }

  closeNewListModal(): void {
    this.showNewListModal.set(false);
  }

  createList(): void {
    const name = this.newListName.trim();
    if (!name) return;
    this.creatingList.set(true);
    this.listService.createList({ name, icon: this.newListIcon, icon_bg: '#f5f5f5' }).subscribe({
      next: () => {
        this.creatingList.set(false);
        this.showNewListModal.set(false);
        this.loadData();
      },
      error: () => this.creatingList.set(false)
    });
  }
}
