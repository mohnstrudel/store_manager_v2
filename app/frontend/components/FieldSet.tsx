import type { ReactNode } from "react";

type FieldSetProps = {
  children: ReactNode;
  className?: string;
};

export default function FieldSet({ children, className = "" }: FieldSetProps) {
  return (
    <fieldset
      className={`flex justify-between gap-4 flex-col lg:flex-row ${className}`}
    >
      {children}
    </fieldset>
  );
}
