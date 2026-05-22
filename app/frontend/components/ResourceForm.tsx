import type { ComponentProps } from "react";
import { Form, Link } from "@inertiajs/react";
import Button from "@/components/Button";

type InertiaFormProps = ComponentProps<typeof Form>;

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: InertiaFormProps["children"];
  method: "post" | "patch" | "put";
  submitLabel: string;
};

export default function ResourceForm({
  action,
  cancelHref,
  children,
  method,
  submitLabel,
}: ResourceFormProps) {
  const actions = (
    <div className="flex flex-col gap-4 items-start justify-start mt-14 lg:flex-row lg:items-center">
      <Button className="w-full lg:w-fit" type="submit" variant="primary">
        {submitLabel}
      </Button>
      <Link className="w-full lg:w-fit h-10" href={cancelHref}>
        Cancel
      </Link>
    </div>
  );

  return (
    <Form action={action} disableWhileProcessing method={method}>
      {typeof children === "function" ? (
        (props) => (
          <>
            {children(props)}
            {actions}
          </>
        )
      ) : (
        <>
          {children}
          {actions}
        </>
      )}
    </Form>
  );
}
