-- ====================================================================
-- GRIT FITNESS WORKOUT TRACKER - SUPABASE DATABASE INITIAL SCHEMA
-- ====================================================================

-- 1. Create Users Table
CREATE TABLE IF NOT EXISTS public.users (
    user_id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    profile_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Create Exercises Master Table
CREATE TABLE IF NOT EXISTS public.exercises_master (
    exercise_id TEXT PRIMARY KEY,
    session_day TEXT NOT NULL,
    sort_order INT NOT NULL,
    exercise_name TEXT NOT NULL,
    target_muscle TEXT,
    target_reps TEXT,
    equipment TEXT,
    status TEXT DEFAULT 'Active' CHECK (status IN ('Active', 'Archived')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Create Workout Logs Table
CREATE TABLE IF NOT EXISTS public.workout_logs (
    log_id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
    workout_date DATE NOT NULL DEFAULT CURRENT_DATE,
    user_id TEXT NOT NULL REFERENCES public.users(user_id) ON DELETE CASCADE,
    exercise_id TEXT NOT NULL REFERENCES public.exercises_master(exercise_id) ON DELETE RESTRICT,
    set_number INT NOT NULL CHECK (set_number BETWEEN 1 AND 10),
    weight_kg NUMERIC(6,2) NOT NULL DEFAULT 0,
    reps INT NOT NULL DEFAULT 0,
    volume_kg NUMERIC(8,2) GENERATED ALWAYS AS (weight_kg * reps) STORED,
    est_1rm NUMERIC(6,2) GENERATED ALWAYS AS (ROUND(weight_kg * (1 + reps::numeric / 30.0), 1)) STORED,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for lightning fast queries
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_date ON public.workout_logs(user_id, workout_date);
CREATE INDEX IF NOT EXISTS idx_workout_logs_exercise ON public.workout_logs(exercise_id);
CREATE INDEX IF NOT EXISTS idx_exercises_master_session ON public.exercises_master(session_day, sort_order);

-- 4. Enable Supabase Realtime
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'workout_logs'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.workout_logs;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables 
        WHERE pubname = 'supabase_realtime' AND tablename = 'exercises_master'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.exercises_master;
    END IF;
END $$;

-- 5. Row Level Security (RLS) - Permissive public access for gym pair usage
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.exercises_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.workout_logs ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    DROP POLICY IF EXISTS "Public access for users" ON public.users;
    CREATE POLICY "Public access for users" ON public.users FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Public access for exercises_master" ON public.exercises_master;
    CREATE POLICY "Public access for exercises_master" ON public.exercises_master FOR ALL USING (true) WITH CHECK (true);

    DROP POLICY IF EXISTS "Public access for workout_logs" ON public.workout_logs;
    CREATE POLICY "Public access for workout_logs" ON public.workout_logs FOR ALL USING (true) WITH CHECK (true);
END $$;

-- 6. SQL View: v_weekly_progression
-- Calculates Week 1 to Week 4 working weights and Weight Trend per exercise and athlete automatically
CREATE OR REPLACE VIEW public.v_weekly_progression AS
WITH min_date AS (
    SELECT COALESCE(MIN(workout_date), '2026-10-06'::date) AS start_date FROM public.workout_logs
),
ranked_logs AS (
    SELECT 
        l.user_id,
        l.exercise_id,
        l.weight_kg,
        l.reps,
        -- Week 1 to 4 determined by 7-day windows from start_date
        LEAST(4, GREATEST(1, 1 + ((l.workout_date - m.start_date) / 7)::int)) AS week_number
    FROM public.workout_logs l
    CROSS JOIN min_date m
    WHERE l.weight_kg > 0
),
weekly_stats AS (
    SELECT 
        user_id,
        exercise_id,
        week_number,
        MAX(weight_kg) AS max_weight
    FROM ranked_logs
    GROUP BY user_id, exercise_id, week_number
),
pivoted AS (
    SELECT 
        e.exercise_id,
        e.exercise_name,
        e.session_day,
        e.sort_order,
        e.target_muscle,
        e.target_reps,
        e.equipment,
        e.status,
        u.user_id,
        u.name AS user_name,
        MAX(CASE WHEN ws.week_number = 1 THEN ws.max_weight END) AS week_1_kg,
        MAX(CASE WHEN ws.week_number = 2 THEN ws.max_weight END) AS week_2_kg,
        MAX(CASE WHEN ws.week_number = 3 THEN ws.max_weight END) AS week_3_kg,
        MAX(CASE WHEN ws.week_number = 4 THEN ws.max_weight END) AS week_4_kg
    FROM public.exercises_master e
    CROSS JOIN public.users u
    LEFT JOIN weekly_stats ws ON ws.exercise_id = e.exercise_id AND ws.user_id = u.user_id
    GROUP BY 
        e.exercise_id, e.exercise_name, e.session_day, e.sort_order,
        e.target_muscle, e.target_reps, e.equipment, e.status,
        u.user_id, u.name
)
SELECT 
    exercise_id,
    exercise_name,
    session_day,
    sort_order,
    target_muscle,
    target_reps,
    equipment,
    status,
    user_id,
    user_name,
    week_1_kg,
    week_2_kg,
    week_3_kg,
    week_4_kg,
    CASE 
        WHEN week_2_kg IS NOT NULL AND week_1_kg IS NOT NULL THEN 
            CASE 
                WHEN week_2_kg > week_1_kg THEN 'up'
                WHEN week_2_kg < week_1_kg THEN 'down'
                ELSE 'flat'
            END
        WHEN week_1_kg IS NOT NULL THEN 'flat'
        ELSE 'none'
    END AS weight_trend
FROM pivoted
ORDER BY user_id, session_day, sort_order;
