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
  const variantClass = {
    primary: "btn-blue",
    danger: "btn-red btn-rounded",
    default: "",
  }[variant];

  return (
    <button className={`${variantClass} ${className}`} type={type} {...props}>
      {children}
    </button>
  );
}
