import { Form, Link } from "@inertiajs/react";
import type { ReactNode } from "react";

import Button from "@/components/Button";
import FormInput from "@/components/FormInput";
import AuthLayout from "@/layouts/AuthLayout";
import routes from "@/utils/routes";

type SignUpProps = {
  email_address?: string | null;
};

export default function New({ email_address }: SignUpProps) {
  return (
    <>
      <h1 className="text-3xl lg:text-5xl mb-6">Create new account</h1>

      <Form
        action={routes.signups.create.path()}
        className="flex flex-col gap-6 my-8"
        disableWhileProcessing
        method="post"
      >
        {({ errors }) => (
          <>
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
          </>
        )}
      </Form>

      <div className="space-x-4">
        <Link className="link" href={routes.sessions.new.path()}>
          Already have an account?
        </Link>
        <Link className="link" href={routes.passwords.new.path()}>
          Forgot password?
        </Link>
      </div>
    </>
  );
}

New.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>;
