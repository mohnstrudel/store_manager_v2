import type { ReactNode } from "react";

type PageHeaderProps = {
  className?: string;
  subtitle?: ReactNode;
  title: ReactNode;
  children?: ReactNode;
};

export default function PageHeader({ children, className = "", subtitle, title }: PageHeaderProps) {
  return (
    <header className={`nav_header ${className}`}>
      <div className="flex gap-4">
        <hgroup>
          <h1>{title}</h1>
          {subtitle ? <h4>{subtitle}</h4> : null}
        </hgroup>
      </div>

      {children ? <menu className="nav_menu">{children}</menu> : null}
    </header>
  );
}
