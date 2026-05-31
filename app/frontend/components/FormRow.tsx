import type { ReactNode } from "react";

type FormRowProps = {
  children: ReactNode;
  className?: string;
};

export default function FormRow({ children, className = "" }: FormRowProps) {
  return (
    <fieldset className={["form_row", className].filter(Boolean).join(" ")}>{children}</fieldset>
  );
}
