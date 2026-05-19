import type { ReactNode } from "react";
import Link from "@/components/Link";

export type PaginationLink = {
  active?: boolean;
  href: string | null;
  label: ReactNode;
  rel?: string;
};

type PaginationProps = {
  className?: string;
  links: PaginationLink[];
  label?: string;
};

export default function Pagination({
  className = "",
  label = "Pagination",
  links,
}: PaginationProps) {
  if (links.length === 0) return null;

  return (
    <nav aria-label={label} className={["pagination", className].filter(Boolean).join(" ")}>
      <ul className="pagination-list">
        {links.map((link, index) => (
          <li key={`${index}-${typeof link.label === "string" ? link.label : "link"}`}>
            {link.href ? (
              <Link
                aria-current={link.active ? "page" : undefined}
                className={link.active ? "pagination-link is-current" : "pagination-link"}
                href={link.href}
                rel={link.rel}
              >
                {link.label}
              </Link>
            ) : (
              <span className="pagination-ellipsis">{link.label}</span>
            )}
          </li>
        ))}
      </ul>
    </nav>
  );
}
