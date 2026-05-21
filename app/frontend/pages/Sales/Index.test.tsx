import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { describe, expect, it, vi } from "vitest";
import Index from "./Index";

vi.mock("@/components/Link", () => ({
  default: ({ children, href }: { children: ReactNode; href: string }) => (
    <a href={href}>{children}</a>
  ),
}));

vi.mock("@inertiajs/react", () => ({
  router: { get: vi.fn(), post: vi.fn(), visit: vi.fn() },
}));

const pagination = { current_page: 1, total_pages: 1, total_count: 1, limit: 50 };

const sales = [
  {
    id: 1,
    path: "/sales/1",
    customer_name: "Dale Cooper",
    customer_email: "dale@fbi.gov",
    sale_items: [
      {
        id: 11,
        title: "Pikachu Figure",
        qty: 2,
        purchased_count: 1,
        product_thumb_url: null,
        purchase_items: [
          { id: 101, path: "/purchase_items/101", warehouse_name: "Berlin Hub", expenses: "9.99" },
        ],
      },
    ],
    total: "1060",
    created_at: "20. May '26 10:00",
    updated_at: "20. May '26 11:00",
    active: true,
    completed: false,
    shopify_name: "HSCM#1746",
    shopify_id: "gid://shopify/Order/7383283466569",
    shopify_id_short: "7383283466569",
    woo_store_id: "WOO-1",
  },
];

const defaultProps = {
  sales,
  pagination,
  search: { q: "" },
  last_sync_at: "Last fetched at 20 May at 10:00",
  last_sync_time: "20.05 at 10:00",
};

describe("Sales/Index", () => {
  it("renders the sales table and sync button", () => {
    render(<Index {...defaultProps} />);

    expect(screen.getByRole("heading", { name: "Sales" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Store Sync" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/sales/new",
    );
    expect(screen.getByText("Dale Cooper")).toBeInTheDocument();
    expect(screen.getByText("Pikachu Figure")).toBeInTheDocument();
  });

  it("renders a search form with the current query", () => {
    render(<Index {...defaultProps} search={{ q: "dale" }} />);

    expect(screen.getByRole("searchbox")).toHaveValue("dale");
  });

  it("renders an empty state when there are no sales", () => {
    render(<Index {...defaultProps} sales={[]} pagination={{ ...pagination, total_count: 0 }} />);

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  describe("Store Sync dialog", () => {
    it("opens and closes the dialog", async () => {
      const user = userEvent.setup();
      render(<Index {...defaultProps} />);

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Sales Synchronization")).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Everything" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Last 100 Sales" })).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Track Jobs Progress" })).toBeInTheDocument();

      await user.click(screen.getByRole("button", { name: "Close" }));

      expect(screen.queryByText("Sales Synchronization")).not.toBeInTheDocument();
    });
  });
});
