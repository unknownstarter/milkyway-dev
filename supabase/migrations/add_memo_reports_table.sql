-- Migration: Add memo_reports table for reporting inappropriate content
-- Description: Creates tables for reporting memos and hiding reported memos from users
-- Date: 2026-01-02

-- 신고 사유 enum 타입 생성
CREATE TYPE report_reason_type AS ENUM (
  'spam',              -- 스팸/광고
  'inappropriate',     -- 부적절한 콘텐츠
  'harassment',        -- 혐오 발언/괴롭힘
  'sexual',            -- 성적 콘텐츠
  'violence',          -- 폭력적 콘텐츠
  'copyright',         -- 저작권 침해
  'other'              -- 기타
);

-- 메모 신고 테이블
CREATE TABLE IF NOT EXISTS memo_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  memo_id UUID NOT NULL REFERENCES memos(id) ON DELETE CASCADE,
  reporter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reason report_reason_type NOT NULL,
  description TEXT, -- 추가 설명 (선택사항)
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 한 사용자가 같은 메모를 중복 신고할 수 없도록 제약
  UNIQUE(memo_id, reporter_id)
);

-- 사용자가 신고한 메모를 숨기는 테이블 (신고 즉시 해당 사용자에게는 보이지 않음)
CREATE TABLE IF NOT EXISTS user_hidden_memos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  memo_id UUID NOT NULL REFERENCES memos(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  
  -- 한 사용자가 같은 메모를 중복으로 숨길 수 없도록 제약
  UNIQUE(user_id, memo_id)
);

-- 인덱스 생성 (조회 성능 향상)
CREATE INDEX IF NOT EXISTS idx_memo_reports_memo_id ON memo_reports(memo_id);
CREATE INDEX IF NOT EXISTS idx_memo_reports_reporter_id ON memo_reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_user_hidden_memos_user_id ON user_hidden_memos(user_id);
CREATE INDEX IF NOT EXISTS idx_user_hidden_memos_memo_id ON user_hidden_memos(memo_id);

-- RLS 정책 설정
ALTER TABLE memo_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_hidden_memos ENABLE ROW LEVEL SECURITY;

-- memo_reports RLS 정책: 사용자는 자신이 신고한 내용만 조회 가능
CREATE POLICY "Users can view their own reports"
  ON memo_reports
  FOR SELECT
  USING (auth.uid() = reporter_id);

-- memo_reports RLS 정책: 사용자는 신고를 생성할 수 있음
CREATE POLICY "Users can create reports"
  ON memo_reports
  FOR INSERT
  WITH CHECK (auth.uid() = reporter_id);

-- user_hidden_memos RLS 정책: 사용자는 자신이 숨긴 메모만 조회 가능
CREATE POLICY "Users can view their own hidden memos"
  ON user_hidden_memos
  FOR SELECT
  USING (auth.uid() = user_id);

-- user_hidden_memos RLS 정책: 사용자는 메모를 숨길 수 있음
CREATE POLICY "Users can hide memos"
  ON user_hidden_memos
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- user_hidden_memos RLS 정책: 사용자는 숨긴 메모를 다시 보이게 할 수 있음
CREATE POLICY "Users can unhide memos"
  ON user_hidden_memos
  FOR DELETE
  USING (auth.uid() = user_id);

-- 코멘트 추가
COMMENT ON TABLE memo_reports IS '사용자가 신고한 메모 정보';
COMMENT ON TABLE user_hidden_memos IS '사용자가 숨긴 메모 목록 (신고 시 자동으로 추가됨)';
COMMENT ON COLUMN memo_reports.reason IS '신고 사유';
COMMENT ON COLUMN memo_reports.description IS '신고 추가 설명 (선택사항)';

