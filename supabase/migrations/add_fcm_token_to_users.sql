-- Migration: Add FCM token and notification settings to users table
-- Description: Adds fcm_token and notification_enabled columns for push notifications
-- Date: 2026-01-02

-- 1. Add fcm_token column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Add notification_enabled column to users table (기본값: true)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS notification_enabled BOOLEAN DEFAULT true;

-- 3. Add comments to columns
COMMENT ON COLUMN users.fcm_token IS 'Firebase Cloud Messaging token for push notifications';
COMMENT ON COLUMN users.notification_enabled IS 'Whether the user wants to receive push notifications';

