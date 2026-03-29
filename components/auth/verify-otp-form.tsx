"use client";

import { useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { useRouter, useSearchParams } from "next/navigation";
import Link from "next/link";
import { verifyOtpValidation, defaultVerifyOtpValues, type VerifyOtpInput } from "../../src/modules/auth/schema";
import { verifyOtpAction, resendOtpAction } from "../../src/modules/auth/actions";
import { AuthCard } from "./auth-card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { toast } from "sonner";

export function VerifyOtpForm() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const emailParam = searchParams.get("email") || "";
  const [isLoading, setIsLoading] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);

  const form = useForm<VerifyOtpInput>({
    resolver: zodResolver(verifyOtpValidation),
    defaultValues: {
      ...defaultVerifyOtpValues,
      email: emailParam,
    },
    mode: "onBlur",
  });

  useEffect(() => {
    if (resendCooldown > 0) {
      const timer = setTimeout(() => setResendCooldown(resendCooldown - 1), 1000);
      return () => clearTimeout(timer);
    }
  }, [resendCooldown]);

  async function onSubmit(data: VerifyOtpInput) {
    setIsLoading(true);
    try {
      const formData = new FormData();
      formData.append("email", data.email);
      formData.append("code", data.code);

      const result = await verifyOtpAction(formData);

      if (result.success) {
        toast.success("auth.verifyOtp.success");
        router.push("/");
      } else {
        toast.error(result.message || "auth.errors.generic");
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "auth.errors.generic");
    } finally {
      setIsLoading(false);
    }
  }

  async function handleResend() {
    const email = form.getValues("email");
    if (!email) {
      toast.error("auth.verifyOtp.enterEmail");
      return;
    }

    setResendCooldown(60);
    try {
      const result = await resendOtpAction(email);
      if (result.success) {
        toast.success("auth.verifyOtp.resendSuccess");
      } else {
        toast.error(result.message || "auth.errors.generic");
        setResendCooldown(0);
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "auth.errors.generic");
      setResendCooldown(0);
    }
  }

  return (
    <AuthCard
      title="auth.verifyOtp.title"
      description="auth.verifyOtp.description"
    >
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="email">auth.verifyOtp.email</Label>
          <Input
            id="email"
            type="email"
            placeholder="email@example.com"
            autoComplete="email"
            aria-invalid={!!form.formState.errors.email}
            {...form.register("email")}
          />
          {form.formState.errors.email && (
            <p className="text-xs text-destructive">
              {form.formState.errors.email.message}
            </p>
          )}
        </div>

        <div className="space-y-2">
          <Label htmlFor="code">auth.verifyOtp.code</Label>
          <Input
            id="code"
            type="text"
            inputMode="numeric"
            pattern="[0-9]*"
            maxLength={6}
            placeholder="123456"
            autoComplete="one-time-code"
            aria-invalid={!!form.formState.errors.code}
            {...form.register("code")}
          />
          {form.formState.errors.code && (
            <p className="text-xs text-destructive">
              {form.formState.errors.code.message}
            </p>
          )}
        </div>

        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? "common.loading" : "auth.verifyOtp.submit"}
        </Button>

        <div className="text-center">
          {resendCooldown > 0 ? (
            <p className="text-sm text-muted-foreground">
              auth.verifyOtp.resendCooldown{" "}
              <span className="font-medium">{resendCooldown}s</span>
            </p>
          ) : (
            <button
              type="button"
              onClick={handleResend}
              className="text-sm text-primary hover:underline"
            >
              auth.verifyOtp.resend
            </button>
          )}
        </div>
      </form>

      <p className="mt-4 text-center text-sm text-muted-foreground">
        <Link
          href="/auth/sign-in"
          className="font-medium text-primary hover:underline"
        >
          auth.verifyOtp.backToSignIn
        </Link>
      </p>
    </AuthCard>
  );
}
