-- ============================================================
-- 001_todo_schema.sql
-- Full schema for the AI-managed Todo application.
-- Run this against your Supabase project (SQL editor or CLI).
-- ============================================================

-- Enable UUID extension (may already exist on the instance)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create the todo schema namespace
CREATE SCHEMA IF NOT EXISTS todo;

-- ============================================================
-- Tables
-- ============================================================

-- Lists (categories like "Work", "Home", "Music")
CREATE TABLE IF NOT EXISTS todo.lists (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id     UUID        NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name        TEXT        NOT NULL,
    icon        TEXT        DEFAULT '📋',
    icon_bg     TEXT        DEFAULT '#f5f5f5',
    is_urgent   BOOLEAN     DEFAULT FALSE,
    position    INTEGER     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Sections (sub-sections within a list, e.g. "Instagram", "LinkedIn" inside "Content Creation")
CREATE TABLE IF NOT EXISTS todo.sections (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id     UUID        NOT NULL REFERENCES todo.lists(id) ON DELETE CASCADE,
    name        TEXT        NOT NULL,
    icon        TEXT        DEFAULT '📁',
    color       TEXT        DEFAULT 'purple',   -- orange | blue | purple | pink | green
    position    INTEGER     NOT NULL DEFAULT 0,
    created_at  TIMESTAMPTZ DEFAULT NOW(),
    updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Tasks
CREATE TABLE IF NOT EXISTS todo.tasks (
    id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    list_id        UUID        NOT NULL REFERENCES todo.lists(id) ON DELETE CASCADE,
    section_id     UUID        REFERENCES todo.sections(id) ON DELETE SET NULL,
    title          TEXT        NOT NULL,
    priority       TEXT        NOT NULL DEFAULT 'medium'
                               CHECK (priority IN ('urgent', 'high', 'medium', 'low')),
    time_estimate  TEXT,                          -- e.g. "30 min", "2–3h", "ongoing"
    details        TEXT,                          -- expanded notes / description
    sub_text       TEXT,                          -- one-liner shown below the title
    position       INTEGER     NOT NULL DEFAULT 0,
    is_completed   BOOLEAN     DEFAULT FALSE,
    completed_at   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ DEFAULT NOW(),
    updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Attachments
CREATE TABLE IF NOT EXISTS todo.attachments (
    id            UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    task_id       UUID        NOT NULL REFERENCES todo.tasks(id) ON DELETE CASCADE,
    file_name     TEXT        NOT NULL,
    file_size     BIGINT,
    mime_type     TEXT,
    storage_path  TEXT        NOT NULL,   -- path inside Supabase Storage bucket
    storage_url   TEXT,                   -- public URL (if bucket is public)
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_todo_lists_user_id       ON todo.lists(user_id);
CREATE INDEX IF NOT EXISTS idx_todo_sections_list_id    ON todo.sections(list_id);
CREATE INDEX IF NOT EXISTS idx_todo_tasks_list_id       ON todo.tasks(list_id);
CREATE INDEX IF NOT EXISTS idx_todo_tasks_section_id    ON todo.tasks(section_id);
CREATE INDEX IF NOT EXISTS idx_todo_tasks_completed     ON todo.tasks(is_completed);
CREATE INDEX IF NOT EXISTS idx_todo_attachments_task_id ON todo.attachments(task_id);

-- ============================================================
-- Row Level Security
-- ============================================================

ALTER TABLE todo.lists       ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo.sections    ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo.tasks       ENABLE ROW LEVEL SECURITY;
ALTER TABLE todo.attachments ENABLE ROW LEVEL SECURITY;

-- Lists: users can only see/modify their own
CREATE POLICY "Users manage own lists"
    ON todo.lists
    USING      (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- Sections: access inherited from parent list
CREATE POLICY "Users manage own sections"
    ON todo.sections
    USING (
        EXISTS (
            SELECT 1 FROM todo.lists
            WHERE id = list_id AND user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM todo.lists
            WHERE id = list_id AND user_id = auth.uid()
        )
    );

-- Tasks: access inherited from parent list
CREATE POLICY "Users manage own tasks"
    ON todo.tasks
    USING (
        EXISTS (
            SELECT 1 FROM todo.lists
            WHERE id = list_id AND user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM todo.lists
            WHERE id = list_id AND user_id = auth.uid()
        )
    );

-- Attachments: access inherited through task -> list
CREATE POLICY "Users manage own attachments"
    ON todo.attachments
    USING (
        EXISTS (
            SELECT 1 FROM todo.tasks t
            JOIN todo.lists l ON l.id = t.list_id
            WHERE t.id = task_id AND l.user_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM todo.tasks t
            JOIN todo.lists l ON l.id = t.list_id
            WHERE t.id = task_id AND l.user_id = auth.uid()
        )
    );

-- ============================================================
-- updated_at auto-trigger
-- ============================================================

CREATE OR REPLACE FUNCTION todo.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to every table that has updated_at
CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON todo.lists
    FOR EACH ROW EXECUTE FUNCTION todo.set_updated_at();

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON todo.sections
    FOR EACH ROW EXECUTE FUNCTION todo.set_updated_at();

CREATE TRIGGER set_updated_at
    BEFORE UPDATE ON todo.tasks
    FOR EACH ROW EXECUTE FUNCTION todo.set_updated_at();

-- ============================================================
-- Grant permissions to Supabase roles
-- ============================================================
GRANT USAGE ON SCHEMA todo TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA todo TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA todo TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA todo GRANT ALL ON TABLES TO anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA todo GRANT ALL ON SEQUENCES TO anon, authenticated, service_role;

-- ============================================================
-- Storage bucket hint (run manually in Supabase dashboard or via CLI)
-- ============================================================
-- INSERT INTO storage.buckets (id, name, public)
-- VALUES ('todo-attachments', 'todo-attachments', true)
-- ON CONFLICT (id) DO NOTHING;
