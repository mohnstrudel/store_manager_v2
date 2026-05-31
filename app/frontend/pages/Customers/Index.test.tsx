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
  router: {
    get: vi.fn<(...args: unknown[]) => unknown>(),
    visit: vi.fn<(...args: unknown[]) => unknown>(),
  },
}));

const pagination = { current_page: 1, total_pages: 1, total_count: 1, limit: 50 };

const customers = [
  {
    id: 1,
    first_name: "Dale",
    last_name: "Cooper",
    full_name: "Dale Cooper",
    email: "dale@fbi.gov",
    phone: "+1555000",
    woo_store_id: "WOO-1",
    created_at: "19. May '26 10:00",
    updated_at: "19. May '26 10:00",
    path: "/customers/1",
  },
];

describe("Customers/Index", () => {
  it("renders the customers table and new-record link", () => {
    render(<Index customers={customers} pagination={pagination} search={{ q: "" }} />);

    expect(screen.getByRole("heading", { name: "Customers" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/customers/new",
    );
    expect(screen.getByRole("cell", { name: "Dale Cooper" })).toBeInTheDocument();
    expect(screen.getByRole("cell", { name: "dale@fbi.gov" })).toBeInTheDocument();
  });

  it("renders a search form", () => {
    render(<Index customers={customers} pagination={pagination} search={{ q: "dale" }} />);

    expect(screen.getByRole("searchbox")).toHaveValue("dale");
  });

  it("renders without pagination when only one page", () => {
    render(<Index customers={customers} pagination={pagination} search={{ q: "" }} />);

    expect(screen.queryByRole("navigation", { name: "Pagination" })).not.toBeInTheDocument();
  });
});
