import { z } from "zod";

export const signUpValidation = z.object({
  email: z
    .string()
    .min(1, { message: "validations.email.required" })
    .email({ message: "validations.email.invalid" }),
  password: z
    .string()
    .min(1, { message: "validations.password.required" })
    .min(8, { message: "validations.password.min" })
    .regex(/[A-Z]/, { message: "validations.password.uppercase" })
    .regex(/[a-z]/, { message: "validations.password.lowercase" })
    .regex(/[0-9]/, { message: "validations.password.number" }),
  confirmPassword: z.string().min(1, { message: "validations.confirmPassword.required" }),
}).refine((data) => data.password === data.confirmPassword, {
  message: "validations.confirmPassword.match",
  path: ["confirmPassword"],
});

export const signInValidation = z.object({
  email: z
    .string()
    .min(1, { message: "validations.email.required" })
    .email({ message: "validations.email.invalid" }),
  password: z.string().min(1, { message: "validations.password.required" }),
});

export const verifyOtpValidation = z.object({
  email: z
    .string()
    .min(1, { message: "validations.email.required" })
    .email({ message: "validations.email.invalid" }),
  code: z
    .string()
    .min(1, { message: "validations.code.required" })
    .length(6, { message: "validations.code.length" }),
});

export type SignUpInput = z.infer<typeof signUpValidation>;
export type SignInInput = z.infer<typeof signInValidation>;
export type VerifyOtpInput = z.infer<typeof verifyOtpValidation>;

export const defaultSignUpValues: SignUpInput = {
  email: "",
  password: "",
  confirmPassword: "",
};

export const defaultSignInValues: SignInInput = {
  email: "",
  password: "",
};

export const defaultVerifyOtpValues: VerifyOtpInput = {
  email: "",
  code: "",
};
