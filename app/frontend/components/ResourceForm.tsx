import { useCallback, useRef, useState, type ComponentRef, type ReactNode } from "react";
import { Form, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import ErrorNotice from "@/components/ErrorNotice";

type InertiaFormRef = ComponentRef<typeof Form>;

export type ResourceFormRenderProps = {
  errors: Record<string, string>;
  processing: boolean;
};

type ResourceFormProps = {
  action: string;
  cancelHref: string;
  children: ReactNode | ((props: ResourceFormRenderProps) => ReactNode);
  method: "post" | "patch" | "put";
  submitLabel: string;
  validate?: (formData: FormData) => Record<string, string> | null;
};

export default function ResourceForm({
  action,
  cancelHref,
  children,
  method,
  submitLabel,
  validate,
}: ResourceFormProps) {
  const [clientErrors, setClientErrors] = useState<Record<string, string>>({});
  const formRef = useRef<InertiaFormRef>(null);

  const onBefore = useCallback((): false | undefined => {
    if (!validate || !formRef.current) return undefined;
    const errors = validate(formRef.current.getFormData());
    if (errors) {
      setClientErrors(errors);
      return false;
    }
    setClientErrors({});
    return undefined;
  }, [validate]);

  const actions = (
    <div className="flex flex-col gap-4 items-start justify-start mt-14 lg:flex-row lg:items-center">
      <Button className="w-full lg:w-fit" type="submit" variant="primary">
        {submitLabel}
      </Button>
      <Link className="w-full lg:w-fit h-10" href={cancelHref} prefetch>
        Cancel
      </Link>
    </div>
  );

  return (
    <Form
      ref={formRef}
      className="flex flex-col gap-6"
      action={action}
      disableWhileProcessing
      method={method}
      onBefore={onBefore}
    >
      {(serverProps) => {
        const serverErrors = serverProps.errors as Record<string, string>;
        const errors: Record<string, string> = { ...serverErrors, ...clientErrors };
        const hasErrors =
          Object.keys(serverErrors).length > 0 || Object.keys(clientErrors).length > 0;
        return (
          <>
            {hasErrors && <ErrorNotice clientErrors={clientErrors} />}
            {typeof children === "function"
              ? children({ errors, processing: serverProps.processing })
              : children}
            {actions}
          </>
        );
      }}
    </Form>
  );
}
