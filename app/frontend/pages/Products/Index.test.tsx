import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";

import { makePagination } from "@/test/factories";
import type { PaginationMeta } from "@/types/pagination";

import Index from "./Index";
import { makeProductIndexRecord } from "./test/factories";
import type { ProductIndexRecord } from "./types";

describe("Products/Index", () => {
  it("renders the product heading and add new record link", () => {
    renderIndex();

    expect(screen.getByRole("heading", { name: "Products" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Add New Record/ })).toHaveAttribute(
      "href",
      "/products/new",
    );
  });

  it("renders the product title and edit link in the table", () => {
    renderIndex();

    expect(screen.getByText("Pokémon — Pikachu | Nendoroid")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute("href", "/products/1/edit");
  });

  it("renders a search form with an existing query", () => {
    renderIndex({ search: { q: "pikachu" } });

    expect(screen.getByRole("searchbox")).toHaveValue("pikachu");
  });

  it("renders an empty state when a search returns no products", () => {
    renderIndex({
      products: [],
      pagination: makePagination({ total_count: 0 }),
      search: { q: "pikachu" },
    });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
  });

  describe("Store Sync dialog", () => {
    it("renders the Store Sync button", () => {
      renderIndex();

      expect(screen.getByRole("button", { name: "Store Sync" })).toBeInTheDocument();
    });

    it("opens the dialog when Store Sync is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Products Synchronization")).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Everything" })).toBeInTheDocument();
      expect(screen.getByRole("button", { name: "Fetch Last 100 Products" })).toBeInTheDocument();
      expect(screen.getByRole("link", { name: "Track Jobs Progress" })).toBeInTheDocument();
    });

    it("shows the last sync time when last_sync_at is provided", async () => {
      const user = userEvent.setup();
      renderIndex({ last_sync_at: "Last fetched at 5 January at 10:00" });

      await user.click(screen.getByRole("button", { name: "Store Sync" }));

      expect(screen.getByText("Last fetched at 5 January at 10:00")).toBeInTheDocument();
    });

    it("closes the dialog when Close is clicked", async () => {
      const user = userEvent.setup();
      renderIndex();

      await user.click(screen.getByRole("button", { name: "Store Sync" }));
      await user.click(screen.getByRole("button", { name: "Close" }));

      expect(screen.queryByText("Products Synchronization")).not.toBeInTheDocument();
    });
  });
});

function renderIndex({
  products = [makeProductIndexRecord()],
  pagination = makePagination(),
  search = { q: "" },
  last_sync_at = null,
}: {
  products?: ProductIndexRecord[];
  pagination?: PaginationMeta;
  search?: { q: string };
  last_sync_at?: string | null;
} = {}) {
  return render(
    <Index
      last_sync_at={last_sync_at}
      pagination={pagination}
      products={products}
      search={search}
    />,
  );
}
