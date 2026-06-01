import type { ReactNode } from "react";
import { Form, Link, usePage } from "@inertiajs/react";
import AuthLayout from "@/layouts/AuthLayout";
import FormInput from "@/components/FormInput";
import Button from "@/components/Button";

type ForgotPasswordProps = {
  email_address?: string | null;
};

export default function New({ email_address }: ForgotPasswordProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <h1 className="text-3xl lg:text-5xl mb-6">Forgot your password?</h1>

      <Form
        action="/passwords"
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
          placeholder="Enter your email address"
          required
          type="email"
        />
        <Button className="w-full" type="submit" variant="primary">
          Email reset instructions
        </Button>
      </Form>

      <div className="space-x-4">
        <Link className="link" href="/sign_up/new">
          Create new account
        </Link>
        <Link className="link" href="/sign_in">
          Already have an account?
        </Link>
      </div>
    </>
  );
}

New.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>;
