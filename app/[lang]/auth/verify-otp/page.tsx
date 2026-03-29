import { Suspense } from "react";
import { VerifyOtpForm } from "@/components/auth/verify-otp-form";

export default function VerifyOtpPage() {
  return (
    <div className="flex min-h-screen items-center justify-center bg-background p-4">
      <Suspense fallback={<div>Loading...</div>}>
        <VerifyOtpForm />
      </Suspense>
    </div>
  );
}
