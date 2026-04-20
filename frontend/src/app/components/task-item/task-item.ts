import { Component, Input, Output, EventEmitter, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { FormsModule } from '@angular/forms';
import { Task, Priority } from '../../models/todo.models';
import { PriorityBadgeComponent } from '../priority-badge/priority-badge';

interface EditForm {
  title: string;
  priority: Priority;
  time_estimate: string;
  details: string;
}

@Component({
  selector: 'app-task-item',
  standalone: true,
  imports: [CommonModule, FormsModule, PriorityBadgeComponent],
  template: `
    @if (editing()) {
      <div class="task-edit-form">
        <input
          type="text"
          class="form-control form-control-sm mb-2"
          placeholder="Task title…"
          [(ngModel)]="editModel.title"
          (keydown.enter)="saveEdit()"
          (keydown.escape)="cancelEdit()"
        />
        <div class="d-flex gap-2 mb-2">
          <select class="form-select form-select-sm" [(ngModel)]="editModel.priority">
            @for (p of priorities; track p) {
              <option [value]="p">{{ p | titlecase }}</option>
            }
          </select>
          <input
            type="text"
            class="form-control form-control-sm"
            placeholder="Time estimate (e.g. 2h)"
            [(ngModel)]="editModel.time_estimate"
          />
        </div>
        <textarea
          class="form-control form-control-sm mb-2"
          rows="2"
          placeholder="Details (optional)…"
          [(ngModel)]="editModel.details"
        ></textarea>
        <div class="d-flex gap-2">
          <button class="btn btn-sm btn-primary" (click)="saveEdit()" [disabled]="!editModel.title.trim()">Save</button>
          <button class="btn btn-sm btn-outline-secondary" (click)="cancelEdit()">Cancel</button>
        </div>
      </div>
    } @else {
      <div class="task-row" [class.task-row--completed]="task.is_completed">
        <!-- Drag grip -->
        <span class="task-row__grip" title="Drag to reorder">&#8942;&#8942;</span>

        <!-- Checkbox -->
        @if (showCheckbox) {
          <input
            type="checkbox"
            class="form-check-input task-row__checkbox"
            [checked]="task.is_completed"
            (change)="onCheckboxChange($event)"
            [attr.aria-label]="'Mark ' + task.title + ' as ' + (task.is_completed ? 'incomplete' : 'complete')"
          />
        }

        <!-- Title and priority -->
        <div class="task-row__body flex-grow-1">
          <span class="task-row__title" [class.task-row__title--done]="task.is_completed">
            {{ task.title }}
          </span>
          @if (task.sub_text) {
            <span class="task-row__subtext">{{ task.sub_text }}</span>
          }
        </div>

        <!-- Priority badge -->
        <app-priority-badge [priority]="task.priority" />

        <!-- Time estimate -->
        @if (task.time_estimate) {
          <span class="task-row__time">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/>
            </svg>
            {{ task.time_estimate }}
          </span>
        }

        <!-- Expand / collapse details -->
        @if (task.details) {
          <button
            class="task-row__expand-btn"
            (click)="toggleDetails()"
            [attr.aria-expanded]="detailsExpanded()"
            [title]="detailsExpanded() ? 'Collapse details' : 'Expand details'"
          >
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5"
              [style.transform]="detailsExpanded() ? 'rotate(180deg)' : 'rotate(0deg)'"
              style="transition: transform 0.2s ease;">
              <polyline points="6 9 12 15 18 9"/>
            </svg>
          </button>
        }

        <!-- Edit button -->
        <button
          class="task-row__edit-btn"
          (click)="startEdit()"
          title="Edit task"
          aria-label="Edit task"
        >
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2">
            <path d="M12 20h9"/><path d="M16.5 3.5a2.121 2.121 0 1 1 3 3L7 19l-4 1 1-4 12.5-12.5z"/>
          </svg>
        </button>

        <!-- Delete button -->
        <button
          class="task-row__delete-btn"
          (click)="onDelete()"
          title="Delete task"
          aria-label="Delete task"
        >
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
            <polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14H6L5 6"/><path d="M10 11v6"/><path d="M14 11v6"/>
            <path d="M9 6V4h6v2"/>
          </svg>
        </button>
      </div>

      <!-- Expanded details panel -->
      @if (detailsExpanded() && task.details) {
        <div class="task-details">
          {{ task.details }}
        </div>
      }
    }
  `,
  styles: [`
    .task-row {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 10px 12px;
      border-radius: 8px;
      background: #fff;
      margin-bottom: 4px;
      transition: background 0.15s;

      &:hover {
        background: #f8f7ff;
      }

      &--completed {
        opacity: 0.6;
      }
    }

    .task-row__grip {
      color: #ccc;
      cursor: grab;
      font-size: 0.9rem;
      letter-spacing: -3px;
      user-select: none;

      &:active {
        cursor: grabbing;
      }
    }

    .task-row__checkbox {
      flex-shrink: 0;
      width: 16px;
      height: 16px;
      cursor: pointer;
      accent-color: var(--accent);
    }

    .task-row__body {
      display: flex;
      flex-direction: column;
      min-width: 0;
    }

    .task-row__title {
      font-size: 0.9rem;
      font-weight: 500;
      color: #2d3436;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;

      &--done {
        text-decoration: line-through;
        color: #aaa;
      }
    }

    .task-row__subtext {
      font-size: 0.75rem;
      color: #888;
      margin-top: 1px;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .task-row__time {
      display: flex;
      align-items: center;
      gap: 3px;
      font-size: 0.75rem;
      font-family: 'JetBrains Mono', monospace;
      color: #888;
      white-space: nowrap;
      flex-shrink: 0;
    }

    .task-row__expand-btn,
    .task-row__edit-btn,
    .task-row__delete-btn {
      background: none;
      border: none;
      padding: 2px 4px;
      cursor: pointer;
      color: #bbb;
      border-radius: 4px;
      display: flex;
      align-items: center;
      transition: color 0.15s, background 0.15s;
      flex-shrink: 0;

      &:hover {
        color: var(--accent);
        background: rgba(108, 92, 231, 0.08);
      }
    }

    .task-row__delete-btn:hover {
      color: var(--urgent);
      background: rgba(230, 57, 70, 0.08);
    }

    .task-details {
      padding: 8px 12px 12px 44px;
      font-size: 0.85rem;
      color: #555;
      line-height: 1.5;
      background: #fafafa;
      border-radius: 0 0 8px 8px;
      margin-top: -4px;
      margin-bottom: 4px;
      border-left: 3px solid var(--accent);
    }

    .task-edit-form {
      background: #f8f7ff;
      border: 1.5px solid rgba(108, 92, 231, 0.3);
      border-radius: 8px;
      padding: 12px;
      margin-bottom: 4px;

      .form-control,
      .form-select {
        border-color: #e0dff5;
        font-size: 0.85rem;

        &:focus {
          border-color: var(--accent);
          box-shadow: 0 0 0 2px rgba(108, 92, 231, 0.1);
        }
      }

      .btn-primary {
        background: var(--accent);
        border-color: var(--accent);

        &:hover:not(:disabled) {
          background: #5a49d6;
          border-color: #5a49d6;
        }
      }
    }
  `]
})
export class TaskItemComponent {
  @Input({ required: true }) task!: Task;
  @Input() showCheckbox = true;

  @Output() completed = new EventEmitter<Task>();
  @Output() uncompleted = new EventEmitter<Task>();
  @Output() deleted = new EventEmitter<Task>();
  @Output() updated = new EventEmitter<{ task: Task; changes: Partial<Task> }>();

  detailsExpanded = signal(false);
  editing = signal(false);

  readonly priorities: Priority[] = ['urgent', 'high', 'medium', 'low'];

  editModel: EditForm = { title: '', priority: 'medium', time_estimate: '', details: '' };

  toggleDetails(): void {
    this.detailsExpanded.update(v => !v);
  }

  onCheckboxChange(event: Event): void {
    const checked = (event.target as HTMLInputElement).checked;
    if (checked) {
      this.completed.emit(this.task);
    } else {
      this.uncompleted.emit(this.task);
    }
  }

  onDelete(): void {
    this.deleted.emit(this.task);
  }

  startEdit(): void {
    this.editModel = {
      title: this.task.title,
      priority: this.task.priority,
      time_estimate: this.task.time_estimate ?? '',
      details: this.task.details ?? ''
    };
    this.editing.set(true);
  }

  cancelEdit(): void {
    this.editing.set(false);
  }

  saveEdit(): void {
    const title = this.editModel.title.trim();
    if (!title) return;
    const changes: Partial<Task> = {
      title,
      priority: this.editModel.priority,
      time_estimate: this.editModel.time_estimate.trim() || undefined,
      details: this.editModel.details.trim() || undefined
    };
    this.updated.emit({ task: this.task, changes });
    this.editing.set(false);
  }
}
