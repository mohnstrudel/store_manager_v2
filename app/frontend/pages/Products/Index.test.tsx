import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
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
    post: vi.fn<(...args: unknown[]) => unknown>(),
  },
}));

const pagination = { current_page: 1, total_pages: 1, total_count: 1, limit: 50 };

const products = [
  {
    id: 1,
    title: "Pikachu",
    full_title: "Pokémon — Pikachu | Nendoroid",
    path: "/products/pikachu",
    edit_path: "/products/pikachu/edit",
    thumb_url: null,
    variants: [{ id: 10, title: "1/6 Scale" }],
    woo_store_id: "123",
    shopify_id_short: "456",
    new_purchase_path: "/purchases/new?product=1",
  },
];

const defaultProps = { products, pagination, search: { q: "" }, last_sync_at: null };

describe("Products/Index", () => {
  it("renders the products table and new product link", () => {
    render(<Index {...defaultProps} />);

    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.queryByText("Last fetched at 5 January at 10:00")).not.toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/products/new",
    );
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/products/pikachu/edit",
    );
    expect(screen.getByText("Pokémon — Pikachu | Nendoroid")).toBeInTheDocument();
  });

  it("renders the last fetched timestamp when available", async () => {
    const user = userEvent.setup();
    render(<Index {...defaultProps} last_sync_at="Last fetched at 19 May at 11:53" />);

    await user.click(screen.getByRole("button", { name: "Store Sync" }));

    expect(screen.getByText("Last fetched at 19 May at 11:53")).toBeInTheDocument();
  });

  it("renders a search form with existing query", () => {
    render(<Index {...defaultProps} search={{ q: "pikachu" }} />);

    expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
  });

  it("renders an empty state when no products", () => {
    render(
      <Index
        {...defaultProps}
        pagination={{ ...pagination, total_count: 0 }}
        products={[]}
        search={{ q: "pikachu" }}
      />,
    );

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  describe("Store Sync dialog", () => {
    it("renders the Store Sync button", () => {
      render(<Index {...defaultProps} />);
      expect(screen.getByRole("button", { name: "Store Sync" })).toBeInTheDocument();
    });

    it("opens the dialog when Store Sync is clicked", async () => {
      const user = userEvent.setup();
      render(<Index {...defaultProps} />);

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Products Synchronization")).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Everything" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Last 100 Products" })).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Track Jobs Progress" })).toBeInTheDocument();
    });

    it("shows last sync time when last_sync_at is provided", async () => {
      const user = userEvent.setup();
      render(<Index {...defaultProps} last_sync_at="Last fetched at 5 January at 10:00" />);

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Last fetched at 5 January at 10:00")).toBeInTheDocument();
    });

    it("closes the dialog when Close is clicked", async () => {
      const user = userEvent.setup();
      render(<Index {...defaultProps} />);

      await user.click(screen.getByRole("button", { name: "Store Sync" }));
      expect(screen.getByText("Products Synchronization")).toBeInTheDocument();

      await user.click(screen.getByRole("button", { name: "Close" }));
      expect(screen.queryByText("Products Synchronization")).not.toBeInTheDocument();
    });
  });
});
