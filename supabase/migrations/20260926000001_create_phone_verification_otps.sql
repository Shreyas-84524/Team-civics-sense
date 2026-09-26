-- CivicFix Phone Verification OTP Infrastructure
-- Migration: 20260926000001_create_phone_verification_otps.sql
-- Description: Stores temporary cryptographic OTP verification challenges

CREATE TABLE IF NOT EXISTS public.phone_verification_otps (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone VARCHAR(20) NOT NULL,
    otp_hash VARCHAR(128) NOT NULL,
    salt VARCHAR(64) NOT NULL,
    request_id UUID NOT NULL UNIQUE,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 3,
    expires_at TIMESTAMPTZ NOT NULL,
    consumed BOOLEAN NOT NULL DEFAULT false,
    consumed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT check_attempts_non_negative CHECK (attempts >= 0),
    CONSTRAINT check_max_attempts_positive CHECK (max_attempts > 0)
);

-- Index for phone rate-limiting checks (cooldown & hourly limits)
CREATE INDEX IF NOT EXISTS idx_otp_phone_created_at 
    ON public.phone_verification_otps (phone, created_at DESC);

-- Index for fast challenge lookup by request_id
CREATE INDEX IF NOT EXISTS idx_otp_request_id 
    ON public.phone_verification_otps (request_id);

-- Index for fast active challenge lookups
CREATE INDEX IF NOT EXISTS idx_otp_expires_at 
    ON public.phone_verification_otps (expires_at);

-- Row Level Security (RLS) Configuration
ALTER TABLE public.phone_verification_otps ENABLE ROW LEVEL SECURITY;

-- Revoke all permissions from untrusted public roles (anon and authenticated)
-- Ensures Flutter client cannot query, insert, or manipulate OTP challenges directly
REVOKE ALL ON public.phone_verification_otps FROM anon, authenticated;

-- Grant access exclusively to service_role (used by Supabase Edge Functions)
GRANT ALL ON public.phone_verification_otps TO service_role;
