import type { User } from "@supabase/supabase-js";

export interface AuthUser {
  id: string;
  email: string;
  email_confirmed_at: string | null;
  created_at: string;
}

export interface SignUpInput {
  email: string;
  password: string;
  confirmPassword: string;
}

export interface SignInInput {
  email: string;
  password: string;
}

export interface VerifyOtpInput {
  email: string;
  code: string;
}

export interface AuthResponse {
  success: boolean;
  message?: string;
  user?: AuthUser;
}

export type OAuthProvider = "google" | "github";

export interface Session {
  user: User | null;
  expires_at: number;
}
