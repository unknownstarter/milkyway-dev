-- Migration: Add referral_code to users table
-- Description: Adds referral_code column and auto-generates unique 6-character codes
-- Date: 2025-01-22

-- 1. Add referral_code column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE;

-- 2. Create function to generate unique referral code
CREATE OR REPLACE FUNCTION generate_referral_code()
RETURNS TEXT AS $$
DECLARE
  chars TEXT := 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  result TEXT := '';
  i INTEGER;
  char_count INTEGER := 62; -- 26 uppercase + 26 lowercase + 10 digits
  code_length INTEGER := 6;
  max_attempts INTEGER := 100;
  attempt INTEGER := 0;
BEGIN
  LOOP
    result := '';
    -- Generate random 6-character code
    FOR i IN 1..code_length LOOP
      result := result || substr(chars, floor(random() * char_count + 1)::INTEGER, 1);
    END LOOP;
    
    -- Check if code already exists
    IF NOT EXISTS (SELECT 1 FROM users WHERE referral_code = result) THEN
      RETURN result;
    END IF;
    
    attempt := attempt + 1;
    IF attempt >= max_attempts THEN
      -- If too many attempts, raise exception
      RAISE EXCEPTION 'Failed to generate unique referral code after % attempts', max_attempts;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 3. Create trigger function to auto-generate referral_code on insert
CREATE OR REPLACE FUNCTION set_referral_code_on_insert()
RETURNS TRIGGER AS $$
BEGIN
  -- Only set if referral_code is NULL or empty
  IF NEW.referral_code IS NULL OR NEW.referral_code = '' THEN
    NEW.referral_code := generate_referral_code();
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 4. Create trigger
DROP TRIGGER IF EXISTS trigger_set_referral_code ON users;
CREATE TRIGGER trigger_set_referral_code
  BEFORE INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION set_referral_code_on_insert();

-- 5. Update existing users with referral codes
DO $$
DECLARE
  user_record RECORD;
  new_code TEXT;
BEGIN
  FOR user_record IN 
    SELECT id FROM users WHERE referral_code IS NULL OR referral_code = ''
  LOOP
    -- Generate unique code for each user
    LOOP
      new_code := generate_referral_code();
      -- Double check uniqueness (race condition 방지)
      IF NOT EXISTS (SELECT 1 FROM users WHERE referral_code = new_code) THEN
        UPDATE users 
        SET referral_code = new_code 
        WHERE id = user_record.id;
        EXIT;
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- 6. Add comment to column
COMMENT ON COLUMN users.referral_code IS 'Unique 6-character referral code (uppercase, lowercase, numbers)';

