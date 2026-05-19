import type { FormEventHandler, ReactNode } from "react";
import Button from "@/components/Button";
import Link from "@/components/Link";

type ResourceFormProps = {
  cancelHref: string;
  children: ReactNode;
  onSubmit: FormEventHandler<HTMLFormElement>;
  submitDisabled?: boolean;
  submitLabel: string;
};

export default function ResourceForm({
  cancelHref,
  children,
  onSubmit,
  submitDisabled = false,
  submitLabel,
}: ResourceFormProps) {
  return (
    <form onSubmit={onSubmit}>
      {children}

      <div className="flex flex-col gap-4 items-start justify-start mt-14 lg:flex-row lg:items-center">
        <Button
          className="w-full lg:w-fit"
          disabled={submitDisabled}
          type="submit"
          variant="primary"
        >
          {submitLabel}
        </Button>
        <Link className="w-full lg:w-fit h-10" href={cancelHref}>
          Cancel
        </Link>
      </div>
    </form>
  );
}
