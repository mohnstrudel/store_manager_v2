import { render, screen } from "@testing-library/react";
import { describe, expect, it } from "vitest";
import Index from "./Index";
import { makePagination, makePurchaseItemIndexRecord } from "./test/factories";

describe("PurchaseItems/Index", () => {
  it("renders the purchase items heading and current search query", () => {
    renderIndex({ search: { q: "widget" } });

    expect(screen.getByRole("heading", { name: "Purchase Items" })).toBeInTheDocument();
    expect(screen.getByRole("searchbox")).toHaveValue("widget");
  });

  it("renders purchase, product, and sale information in the table", () => {
    renderIndex();

    expect(screen.getByRole("link", { name: "Purchase 10" })).toHaveAttribute(
      "href",
      "/purchases/10",
    );
    expect(screen.getByRole("link", { name: "Product X" })).toHaveAttribute("href", "/products/5");
    expect(screen.getByRole("link", { name: "Sale 7" })).toHaveAttribute("href", "/sales/7");
  });

  it("renders the empty state without bottom pagination when there are no purchase items", () => {
    renderIndex({
      pagination: makePagination({ total_count: 0 }),
      purchase_items: [],
      search: { q: "missing" },
    });

    expect(screen.getByText("Nothing found")).toBeInTheDocument();
    expect(screen.queryByRole("grid")).not.toBeInTheDocument();
  });
});

function renderIndex({
  pagination = makePagination(),
  purchase_items = [makePurchaseItemIndexRecord()],
  search = { q: "" },
}: {
  pagination?: ReturnType<typeof makePagination>;
  purchase_items?: ReturnType<typeof makePurchaseItemIndexRecord>[];
  search?: { q: string };
} = {}) {
  return render(<Index pagination={pagination} purchase_items={purchase_items} search={search} />);
}
