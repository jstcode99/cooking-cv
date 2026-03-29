"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { signUpValidation, signInValidation, verifyOtpValidation } from "./schema";
import type { OAuthProvider } from "./types";

export async function signUpAction(formData: FormData) {
  const rawData = {
    email: formData.get("email"),
    password: formData.get("password"),
    confirmPassword: formData.get("confirmPassword"),
  };

  const validated = signUpValidation.parse(rawData);

  const supabase = await createClient();

  const { error } = await supabase.auth.signUp({
    email: validated.email,
    password: validated.password,
    options: {
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });

  if (error) {
    return { success: false, message: error.message };
  }

  revalidatePath("/", "layout");
  return {
    success: true,
    message: "auth.signUp.success",
    email: validated.email,
  };
}

export async function signInAction(formData: FormData) {
  const rawData = {
    email: formData.get("email"),
    password: formData.get("password"),
  };

  const validated = signInValidation.parse(rawData);

  const supabase = await createClient();

  const { error } = await supabase.auth.signInWithPassword({
    email: validated.email,
    password: validated.password,
  });

  if (error) {
    return { success: false, message: error.message };
  }

  revalidatePath("/", "layout");
  return { success: true, message: "auth.signIn.success" };
}

export async function verifyOtpAction(formData: FormData) {
  const rawData = {
    email: formData.get("email"),
    code: formData.get("code"),
  };

  const validated = verifyOtpValidation.parse(rawData);

  const supabase = await createClient();

  const { error } = await supabase.auth.verifyOtp({
    email: validated.email,
    token: validated.code,
    type: "email",
  });

  if (error) {
    return { success: false, message: error.message };
  }

  revalidatePath("/", "layout");
  return { success: true, message: "auth.verifyOtp.success" };
}

export async function signInWithOAuth(provider: OAuthProvider) {
  const supabase = await createClient();

  const { data, error } = await supabase.auth.signInWithOAuth({
    provider,
    options: {
      redirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });

  if (error) {
    return { success: false, message: error.message };
  }

  if (data.url) {
    redirect(data.url);
  }

  return { success: false, message: "auth.oauth.error" };
}

export async function signOutAction() {
  const supabase = await createClient();

  const { error } = await supabase.auth.signOut();

  if (error) {
    return { success: false, message: error.message };
  }

  revalidatePath("/", "layout");
  return { success: true, message: "auth.signOut.success" };
}

export async function getSession() {
  const supabase = await createClient();

  const {
    data: { session },
    error,
  } = await supabase.auth.getSession();

  if (error) {
    return null;
  }

  return session;
}

export async function resendOtpAction(email: string) {
  const supabase = await createClient();

  const { error } = await supabase.auth.resend({
    type: "signup",
    email,
    options: {
      emailRedirectTo: `${process.env.NEXT_PUBLIC_APP_URL}/auth/callback`,
    },
  });

  if (error) {
    return { success: false, message: error.message };
  }

  return { success: true, message: "auth.verifyOtp.resendSuccess" };
}
