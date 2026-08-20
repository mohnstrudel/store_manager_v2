import type { ReactNode } from "react";

import FormError from "./FormError";

type NestedFormContainerProps = {
  actions?: ReactNode;
  children: ReactNode;
  className?: string;
  error?: string;
  title?: ReactNode;
};

export default function NestedFormContainer({
  actions,
  children,
  className = "",
  error,
  title,
}: NestedFormContainerProps) {
  const sectionClassName = ["form_section", "form_section_item", className]
    .filter(Boolean)
    .join(" ");

  return (
    <section className={sectionClassName}>
      <FormError>{error}</FormError>
      {(title || actions) && (
        <header className="form_section_item_header">
          {title && <h4>{title}</h4>}
          {actions}
        </header>
      )}
      <div className="form_section_item_body">{children}</div>
    </section>
  );
}
