import type { ReactNode } from "react";
import { Form } from "@inertiajs/react";
import Button from "@/components/Button";
import Link from "@/components/Link";

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: ReactNode;
  method: "post" | "patch" | "put";
  submitLabel: string;
};

export default function ResourceForm({ action, cancelHref, children, method, submitLabel }: ResourceFormProps) {
  return (
    <Form action={action} disableWhileProcessing method={method}>
      {children}

      <div className="flex flex-col gap-4 items-start justify-start mt-14 lg:flex-row lg:items-center">
        <Button className="w-full lg:w-fit" type="submit" variant="primary">
          {submitLabel}
        </Button>
        <Link className="w-full lg:w-fit h-10" href={cancelHref}>
          Cancel
        </Link>
      </div>
    </Form>
  );
}
