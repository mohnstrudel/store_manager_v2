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
  router: { get: vi.fn(), post: vi.fn(), visit: vi.fn() },
}));

const pagination = { current_page: 1, total_pages: 2, total_count: 50, limit: 50 };

describe("Purchases/Index", () => {
  it("keeps pagination visible even when the list is empty", () => {
    render(
      <Index
        move_path="/purchases/move"
        pagination={pagination}
        purchases={[]}
        search={{ q: "" }}
        warehouses={[]}
      />,
    );

    expect(screen.getByRole("heading", { name: "Purchases" })).toBeInTheDocument();
    expect(screen.getAllByRole("navigation", { name: "Pagination" })).toHaveLength(2);
  });
});
