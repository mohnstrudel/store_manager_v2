import type { ReactNode } from "react";
import { Form, Link, usePage } from "@inertiajs/react";
import AuthLayout from "@/layouts/AuthLayout";
import FormInput from "@/components/FormInput";
import Button from "@/components/Button";

type SignUpProps = {
  email_address?: string | null;
};

export default function New({ email_address }: SignUpProps) {
  const { errors = {} } = usePage().props as { errors?: Record<string, string> };

  return (
    <>
      <h1 className="text-3xl lg:text-5xl mb-6">Create new account</h1>

      <Form action="/sign_up" method="post" className="flex flex-col gap-6 my-8" disableWhileProcessing>
        <FormInput
          autoComplete="username"
          autoFocus
          defaultValue={email_address ?? ""}
          error={errors.email_address}
          label="Email address"
          name="user[email_address]"
          placeholder="Enter email address"
          required
          type="email"
        />
        <FormInput
          autoComplete="new-password"
          error={errors.password}
          label="Password"
          maxLength={72}
          name="user[password]"
          placeholder="Enter password"
          required
          type="password"
        />
        <Button className="w-full" type="submit" variant="primary">
          Sign up
        </Button>
      </Form>

      <div className="space-x-4">
        <Link className="link" href="/sign_in">
          Already have an account?
        </Link>
        <Link className="link" href="/passwords/new">
          Forgot password?
        </Link>
      </div>
    </>
  );
}

New.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>;
