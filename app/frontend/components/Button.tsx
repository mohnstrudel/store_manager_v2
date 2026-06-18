import { ButtonHTMLAttributes, ReactNode } from "react";

type ButtonProps = ButtonHTMLAttributes<HTMLButtonElement> & {
  children: ReactNode;
  variant?: "primary" | "danger" | "default";
};

export default function Button({
  children,
  className = "",
  variant = "default",
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button
      className={className}
      data-variant={variant === "default" ? undefined : variant}
      type={type}
      {...props}
    >
      {children}
    </button>
  );
}
