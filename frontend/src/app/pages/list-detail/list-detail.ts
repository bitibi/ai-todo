import {
  Component, OnInit, OnDestroy, inject, signal, computed
} from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Router, ActivatedRoute } from '@angular/router';
import { CdkDragDrop, DragDropModule, moveItemInArray } from '@angular/cdk/drag-drop';
import { Subject } from 'rxjs';
import { takeUntil, catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import { ListService } from '../../services/list.service';
import { TaskService } from '../../services/task.service';
import { TodoList, Section, Task, Priority, CreateTaskPayload } from '../../models/todo.models';
import { TaskItemComponent } from '../../components/task-item/task-item';

type FilterPriority = 'all' | Priority;

interface NewTaskForm {
  title: string;
  priority: Priority;
  time_estimate: string;
  details: string;
}

@Component({
  selector: 'app-list-detail',
  standalone: true,
  imports: [CommonModule, FormsModule, DragDropModule, TaskItemComponent],
  templateUrl: './list-detail.html',
  styleUrl: './list-detail.scss'
})
export class ListDetailComponent implements OnInit, OnDestroy {
  private route = inject(ActivatedRoute);
  private router = inject(Router);
  private listService = inject(ListService);
  private taskService = inject(TaskService);

  private destroy$ = new Subject<void>();

  list = signal<TodoList | null>(null);
  loading = signal(true);
  error = signal<string | null>(null);

  activeFilter = signal<FilterPriority>('all');
  completedVisible = signal(false);

  /** Map of sectionId → collapsed state */
  collapsedSections = signal<Record<string, boolean>>({});

  /** Section id currently showing add-task form, or null / 'root' for unsectioned */
  addTaskTarget = signal<string | null>(null);

  newTask: NewTaskForm = {
    title: '',
    priority: 'medium',
    time_estimate: '',
    details: ''
  };

  savingTask = signal(false);
  taskError = signal<string | null>(null);

  // Rename / delete list modals
  showRenameModal = signal(false);
  renameName = '';
  renameIcon = '';
  renamingList = signal(false);
  renameError = signal<string | null>(null);

  showDeleteModal = signal(false);
  deletingList = signal(false);

  readonly priorities: Priority[] = ['urgent', 'high', 'medium', 'low'];
  readonly filterOptions: FilterPriority[] = ['all', 'urgent', 'high', 'medium', 'low'];

  // ── Derived state ──────────────────────────────────────────────────────────

  unsectionedActiveTasks = computed(() => {
    const tasks = (this.list()?.tasks ?? []).filter(t =>
      !t.section_id && !t.is_completed
    );
    return this.applyFilter(tasks);
  });

  unsectionedCompletedTasks = computed(() =>
    (this.list()?.tasks ?? []).filter(t => !t.section_id && t.is_completed)
  );

  allCompletedTasks = computed(() =>
    (this.list()?.tasks ?? []).filter(t => t.is_completed)
  );

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  ngOnInit(): void {
    this.route.paramMap.pipe(takeUntil(this.destroy$)).subscribe(params => {
      const id = params.get('id');
      if (id) this.loadList(id);
    });
  }

  ngOnDestroy(): void {
    this.destroy$.next();
    this.destroy$.complete();
  }

  // ── Data loading ───────────────────────────────────────────────────────────

  private loadList(id: string): void {
    this.loading.set(true);
    this.error.set(null);

    this.listService.getListWithDetails(id).pipe(
      catchError(err => {
        this.error.set(err?.error?.detail || 'Failed to load list.');
        this.loading.set(false);
        return of(null);
      })
    ).subscribe(list => {
      if (list) {
        this.list.set(list);
      }
      this.loading.set(false);
    });
  }

  private reload(): void {
    const id = this.list()?.id;
    if (id) this.loadList(id);
  }

  // ── Filter ─────────────────────────────────────────────────────────────────

  setFilter(f: FilterPriority): void {
    this.activeFilter.set(f);
  }

  private applyFilter(tasks: Task[]): Task[] {
    const f = this.activeFilter();
    return f === 'all' ? tasks : tasks.filter(t => t.priority === f);
  }

  sectionActiveTasks(section: Section): Task[] {
    const tasks = (section.tasks ?? []).filter(t => !t.is_completed);
    return this.applyFilter(tasks);
  }

  sectionCompletedTasks(section: Section): Task[] {
    return (section.tasks ?? []).filter(t => t.is_completed);
  }

  // ── Section collapse ───────────────────────────────────────────────────────

  isSectionCollapsed(sectionId: string): boolean {
    return this.collapsedSections()[sectionId] ?? false;
  }

  toggleSection(sectionId: string): void {
    this.collapsedSections.update(map => ({
      ...map,
      [sectionId]: !map[sectionId]
    }));
  }

  // ── Add task form ──────────────────────────────────────────────────────────

  openAddTask(target: string): void {
    this.addTaskTarget.set(target);
    this.newTask = { title: '', priority: 'medium', time_estimate: '', details: '' };
    this.taskError.set(null);
  }

  cancelAddTask(): void {
    this.addTaskTarget.set(null);
  }

  submitAddTask(): void {
    if (!this.newTask.title.trim()) {
      this.taskError.set('Title is required.');
      return;
    }

    const listId = this.list()?.id;
    if (!listId) return;

    const target = this.addTaskTarget();
    const sectionId = target && target !== 'root' ? target : undefined;

    const payload: CreateTaskPayload = {
      list_id: listId,
      title: this.newTask.title.trim(),
      priority: this.newTask.priority,
      ...(sectionId && { section_id: sectionId }),
      ...(this.newTask.time_estimate && { time_estimate: this.newTask.time_estimate }),
      ...(this.newTask.details && { details: this.newTask.details })
    };

    this.savingTask.set(true);
    this.taskError.set(null);

    this.taskService.createTask(payload).subscribe({
      next: () => {
        this.addTaskTarget.set(null);
        this.savingTask.set(false);
        this.reload();
      },
      error: err => {
        this.taskError.set(err?.error?.detail || 'Failed to create task.');
        this.savingTask.set(false);
      }
    });
  }

  // ── Task actions ───────────────────────────────────────────────────────────

  onTaskCompleted(task: Task): void {
    this.taskService.completeTask(task.id).subscribe(() => this.reload());
  }

  onTaskUncompleted(task: Task): void {
    this.taskService.uncompleteTask(task.id).subscribe(() => this.reload());
  }

  onTaskDeleted(task: Task): void {
    this.taskService.deleteTask(task.id).subscribe(() => this.reload());
  }

  onTaskUpdated(event: { task: Task; changes: Partial<Task> }): void {
    this.taskService.updateTask(event.task.id, event.changes).subscribe(() => this.reload());
  }

  onUnsectionedDrop(event: CdkDragDrop<Task[]>): void {
    const tasks = [...this.unsectionedActiveTasks()];
    if (event.previousIndex === event.currentIndex) return;
    moveItemInArray(tasks, event.previousIndex, event.currentIndex);

    // Optimistic local update
    this.list.update(l => {
      if (!l) return l;
      const other = (l.tasks ?? []).filter(t => t.section_id || t.is_completed);
      return { ...l, tasks: [...tasks, ...other] };
    });

    this.taskService.reorderTasks(
      tasks.map((t, idx) => ({ id: t.id, position: idx }))
    ).subscribe({
      error: () => this.reload()
    });
  }

  // ── List rename / delete ───────────────────────────────────────────────────

  openRenameModal(): void {
    const l = this.list();
    if (!l) return;
    this.renameName = l.name;
    this.renameIcon = l.icon;
    this.renameError.set(null);
    this.showRenameModal.set(true);
  }

  closeRenameModal(): void {
    if (this.renamingList()) return;
    this.showRenameModal.set(false);
  }

  submitRename(): void {
    const id = this.list()?.id;
    const name = this.renameName.trim();
    if (!id || !name) {
      this.renameError.set('Name is required.');
      return;
    }
    this.renamingList.set(true);
    this.renameError.set(null);
    this.listService.updateList(id, { name, icon: this.renameIcon }).subscribe({
      next: updated => {
        this.renamingList.set(false);
        this.showRenameModal.set(false);
        // Merge new top-level fields, keep sections/tasks
        this.list.update(l => l ? { ...l, ...updated } : l);
      },
      error: err => {
        this.renameError.set(err?.error?.detail || 'Failed to rename list.');
        this.renamingList.set(false);
      }
    });
  }

  openDeleteModal(): void {
    this.showDeleteModal.set(true);
  }

  closeDeleteModal(): void {
    if (this.deletingList()) return;
    this.showDeleteModal.set(false);
  }

  confirmDelete(): void {
    const id = this.list()?.id;
    if (!id) return;
    this.deletingList.set(true);
    this.listService.deleteList(id).subscribe({
      next: () => {
        this.deletingList.set(false);
        this.showDeleteModal.set(false);
        this.router.navigate(['/']);
      },
      error: () => {
        this.deletingList.set(false);
      }
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  goBack(): void {
    this.router.navigate(['/']);
  }

  // ── Track fns ──────────────────────────────────────────────────────────────

  trackByTaskId(_: number, task: Task): string { return task.id; }
  trackBySectionId(_: number, section: Section): string { return section.id; }

  getSectionColorClass(color: string): string {
    return `section-color--${color}`;
  }
}
