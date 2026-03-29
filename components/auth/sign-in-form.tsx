"use client";

import { useState } from "react";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import Link from "next/link";
import { signInValidation, defaultSignInValues, type SignInInput } from "../../src/modules/auth/schema";
import { signInAction } from "../../src/modules/auth/actions";
import { AuthCard } from "./auth-card";
import { Button } from "../ui/button";
import { Input } from "../ui/input";
import { Label } from "../ui/label";
import { OAuthButtons } from "./oauth-buttons";
import { toast } from "sonner";

export function SignInForm() {
  const [isLoading, setIsLoading] = useState(false);

  const form = useForm<SignInInput>({
    resolver: zodResolver(signInValidation),
    defaultValues: defaultSignInValues,
    mode: "onBlur",
  });

  async function onSubmit(data: SignInInput) {
    setIsLoading(true);
    try {
      const formData = new FormData();
      formData.append("email", data.email);
      formData.append("password", data.password);

      const result = await signInAction(formData);

      if (result.success) {
        toast.success("auth.signIn.success");
        // Redirect to dashboard or home
        window.location.href = "/";
      } else {
        toast.error(result.message || "auth.errors.generic");
      }
    } catch (err) {
      toast.error(err instanceof Error ? err.message : "auth.errors.generic");
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <AuthCard
      title="auth.signIn.title"
      description="auth.signIn.description"
    >
      <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="email">auth.signIn.email</Label>
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
          <div className="flex items-center justify-between">
            <Label htmlFor="password">auth.signIn.password</Label>
            {/* TODO: Add forgot password link later
            <Link
              href="/auth/forgot-password"
              className="text-xs text-muted-foreground hover:text-primary"
            >
              auth.signIn.forgotPassword
            </Link>
            */}
          </div>
          <Input
            id="password"
            type="password"
            autoComplete="current-password"
            aria-invalid={!!form.formState.errors.password}
            {...form.register("password")}
          />
          {form.formState.errors.password && (
            <p className="text-xs text-destructive">
              {form.formState.errors.password.message}
            </p>
          )}
        </div>

        <Button type="submit" className="w-full" disabled={isLoading}>
          {isLoading ? "common.loading" : "auth.signIn.submit"}
        </Button>
      </form>

      <div className="relative my-4">
        <div className="absolute inset-0 flex items-center">
          <span className="w-full border-t" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-background px-2 text-muted-foreground">
            common.or
          </span>
        </div>
      </div>

      <OAuthButtons />

      <p className="mt-4 text-center text-sm text-muted-foreground">
        auth.signIn.noAccount{" "}
        <Link
          href="/auth/sign-up"
          className="font-medium text-primary hover:underline"
        >
          auth.signUp.title
        </Link>
      </p>
    </AuthCard>
  );
}
