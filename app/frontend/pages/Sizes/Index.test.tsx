import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: { visit: vi.fn<(...args: unknown[]) => unknown>() },
}));

describe("Sizes/Index", () => {
  it("renders the sizes table and new-record link", () => {
    render(
      <Index
        sizes={[
          {
            id: 1,
            value: "1:6",
            created_at: "19. May '26 16:18",
            updated_at: "19. May '26 16:18",
          },
        ]}
      />,
    );

    expect(screen.getByRole("heading", { name: "Sizes" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sizes/new",
    );
    expect(screen.getByRole("cell", { name: "1:6" })).toBeInTheDocument();
  });
});
