BEGIN;
UPDATE settings SET value = COALESCE((SELECT jsonb_agg(item || '{"enabled":false}'::jsonb) FROM jsonb_array_elements(value) item), '[]'::jsonb), updated_at=now() WHERE key IN ('smtp','messengers');
UPDATE campaigns SET status='paused', updated_at=now() WHERE status='running';
UPDATE campaigns SET status='draft', send_at=NULL, updated_at=now() WHERE status='scheduled';
COMMIT;
