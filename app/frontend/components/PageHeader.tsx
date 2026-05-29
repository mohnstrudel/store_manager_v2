import type { ReactNode } from "react";

type PageHeaderProps = {
  actions?: ReactNode;
  className?: string;
  subtitle?: ReactNode;
  title: ReactNode;
};

export default function PageHeader({ actions, className = "", subtitle, title }: PageHeaderProps) {
  return (
    <header className={`nav_header ${className}`}>
      <div className="flex gap-4">
        <hgroup>
          <h1>{title}</h1>
          {subtitle ? <h4>{subtitle}</h4> : null}
        </hgroup>
      </div>

      {actions ? <menu className="nav_menu">{actions}</menu> : null}
    </header>
  );
}
