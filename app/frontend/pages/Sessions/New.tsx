import type { ReactNode } from "react";
import { Form, Link, usePage } from "@inertiajs/react";
import AuthLayout from "@/layouts/AuthLayout";
import FormInput from "@/components/FormInput";
import Button from "@/components/Button";

type SignInProps = {
  email_address?: string | null;
};

export default function New({ email_address }: SignInProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <h1 className="text-3xl lg:text-5xl mb-6">Sign in with your email</h1>

      <Form
        action="/session"
        method="post"
        className="flex flex-col gap-6 my-8"
        disableWhileProcessing
      >
        <FormInput
          autoComplete="username"
          autoFocus
          defaultValue={email_address ?? ""}
          error={errors.email_address}
          label="Email address"
          name="email_address"
          placeholder="Enter email address"
          required
          type="email"
        />
        <FormInput
          autoComplete="current-password"
          error={errors.password}
          label="Password"
          maxLength={72}
          name="password"
          placeholder="Enter password"
          required
          type="password"
        />
        <Button className="w-full" type="submit" variant="primary">
          Sign in
        </Button>
      </Form>

      <div className="space-x-4">
        <Link className="link" href="/sign_up/new">
          Create new account
        </Link>
        <Link className="link" href="/passwords/new">
          Forgot password?
        </Link>
      </div>
    </>
  );
}

New.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>;
