export interface User {
  id: string;
  email: string;
  full_name?: string;
}

export interface AuthResponse {
  access_token: string;
  token_type: string;
  user: User;
}

export type Priority = 'urgent' | 'high' | 'medium' | 'low';
export type SectionColor = 'orange' | 'blue' | 'purple' | 'pink' | 'green';

export interface TodoList {
  id: string;
  user_id: string;
  name: string;
  icon: string;
  icon_bg: string;
  is_urgent: boolean;
  position: number;
  created_at: string;
  updated_at: string;
  sections?: Section[];
  tasks?: Task[];
}

export interface Section {
  id: string;
  list_id: string;
  name: string;
  icon: string;
  color: SectionColor;
  position: number;
  created_at: string;
  updated_at: string;
  tasks?: Task[];
}

export interface Task {
  id: string;
  list_id: string;
  section_id?: string;
  title: string;
  priority: Priority;
  time_estimate?: string;
  details?: string;
  sub_text?: string;
  position: number;
  is_completed: boolean;
  completed_at?: string;
  created_at: string;
  updated_at: string;
}

export interface Attachment {
  id: string;
  task_id: string;
  file_name: string;
  file_size?: number;
  mime_type?: string;
  storage_url?: string;
  created_at: string;
}

export interface CreateListPayload {
  name: string;
  icon: string;
  icon_bg: string;
  is_urgent?: boolean;
}

export interface CreateTaskPayload {
  list_id: string;
  section_id?: string;
  title: string;
  priority: Priority;
  time_estimate?: string;
  details?: string;
  sub_text?: string;
}

export interface ReorderItem {
  id: string;
  position: number;
}
