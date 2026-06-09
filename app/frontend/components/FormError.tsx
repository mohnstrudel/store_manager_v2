import type { ReactNode } from "react";

type FormErrorProps = {
  children?: ReactNode;
  id?: string;
  inline?: boolean;
};

export default function FormError({ children, id, inline = false }: FormErrorProps) {
  if (!children) return null;

  const className = inline ? "text_error ml-1 absolute text-sm" : "text_error";

  return (
    <p className={className} id={id}>
      {children}
    </p>
  );
}
