import type { ReactNode } from "react";

import FormError from "./FormError";

type FormControlProps = {
  children: ReactNode;
  className?: string;
  error?: string;
  htmlFor?: string;
  label?: string;
};

export default function FormControl({
  children,
  className = "",
  error,
  htmlFor,
  label,
}: FormControlProps) {
  const wrapperClassName = [className, "relative", error && "field_with_errors"]
    .filter(Boolean)
    .join(" ");

  return (
    <div className={wrapperClassName}>
      {label && <label htmlFor={htmlFor}>{label}</label>}
      {children}
      <FormError id={htmlFor ? `${htmlFor}_error` : undefined} inline>
        {error}
      </FormError>
    </div>
  );
}
