import { usePage } from "@inertiajs/react";
import type { ReactNode } from "react";

type CapturedProps = {
  action: string;
  cancelHref: string;
  method: string;
  submitLabel: string;
  validate?: (formData: FormData) => Record<string, string> | null;
};

type ResourceFormProps = CapturedProps & {
  children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
};

export const captureProps = vi.fn<(props: CapturedProps) => void>();

export function lastCapturedProps(): CapturedProps | null {
  const calls = captureProps.mock.calls;
  return calls[calls.length - 1]?.[0] ?? null;
}

export default function ResourceForm({
  action,
  cancelHref,
  children,
  method,
  submitLabel,
  validate,
}: ResourceFormProps) {
  const errors = (usePage().props.errors ?? {}) as Record<string, string>;
  captureProps({ action, cancelHref, method, submitLabel, validate });

  return (
    <form
      action={action}
      data-cancel-href={cancelHref}
      data-method={method}
      data-testid="resource-form"
    >
      {typeof children === "function" ? children({ errors }) : children}
      <button type="submit">{submitLabel}</button>
    </form>
  );
}
