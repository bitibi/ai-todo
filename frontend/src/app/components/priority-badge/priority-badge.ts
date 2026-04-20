import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Priority } from '../../models/todo.models';

@Component({
  selector: 'app-priority-badge',
  standalone: true,
  imports: [CommonModule],
  template: `
    <span class="priority-badge priority-badge--{{ priority }}">
      {{ priority }}
    </span>
  `,
  styles: [`
    .priority-badge {
      display: inline-block;
      padding: 2px 8px;
      border-radius: 12px;
      font-size: 0.7rem;
      font-weight: 600;
      text-transform: uppercase;
      letter-spacing: 0.04em;
      white-space: nowrap;

      &--urgent {
        background: rgba(230, 57, 70, 0.15);
        color: var(--urgent);
      }
      &--high {
        background: rgba(240, 147, 43, 0.15);
        color: var(--high);
      }
      &--medium {
        background: rgba(108, 92, 231, 0.15);
        color: var(--accent);
      }
      &--low {
        background: rgba(108, 117, 125, 0.15);
        color: #6c757d;
      }
    }
  `]
})
export class PriorityBadgeComponent {
  @Input({ required: true }) priority!: Priority;
}
