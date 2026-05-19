import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock("@inertiajs/react", () => ({
  router: { visit: vi.fn() },
  usePage: () => ({
    props: {
      flash: { notice: null, alert: null },
    },
  }),
}));

describe("Sizes/Index", () => {
  it("renders the sizes table and new-record link", () => {
    render(
      <Index
        sizes={[
          { id: 1, value: "1:6", created_at: "19. May '26 16:18", updated_at: "19. May '26 16:18" },
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
