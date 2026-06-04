import type { ReactNode } from "react";
import { Form } from "@inertiajs/react";
import AuthLayout from "@/layouts/AuthLayout";
import FormInput from "@/components/FormInput";
import Button from "@/components/Button";
import routes from "@/lib/routes";

type ResetPasswordProps = {
  token: string;
};

export default function Edit({ token }: ResetPasswordProps) {
  return (
    <>
      <h1 className="text-3xl lg:text-5xl mb-6">Reset your password</h1>

      <Form
        action={routes.passwords.update.path({ token })}
        className="flex flex-col gap-6 my-8"
        disableWhileProcessing
        method="put"
      >
        {({ errors }) => (
          <>
            <FormInput
              autoComplete="new-password"
              autoFocus
              error={errors.password}
              label="New password"
              maxLength={72}
              name="password"
              placeholder="Enter new password"
              required
              type="password"
            />
            <FormInput
              autoComplete="new-password"
              error={errors.password_confirmation}
              label="Confirm new password"
              maxLength={72}
              name="password_confirmation"
              placeholder="Repeat new password"
              required
              type="password"
            />
            <Button className="w-full" type="submit" variant="primary">
              Save new password
            </Button>
          </>
        )}
      </Form>
    </>
  );
}

Edit.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>;
