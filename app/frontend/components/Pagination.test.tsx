import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Pagination from "./Pagination";

vi.mock("@/components/Link", () => ({
  default: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}));

describe("Pagination", () => {
  it("renders pagination links and ellipsis entries", () => {
    render(
      <Pagination
        links={[
          { href: "/items?page=1", label: "1" },
          { active: true, href: "/items?page=2", label: "2" },
          { href: null, label: "..." },
        ]}
      />,
    );

    expect(screen.getByRole("link", { name: "1" })).toHaveAttribute("href", "/items?page=1");
    expect(screen.getByRole("link", { name: "2" })).toHaveAttribute("aria-current", "page");
    expect(screen.getByText("...")).toBeInTheDocument();
  });
});
