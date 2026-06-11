import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import Edit from "./Edit";
import {
  makePurchaseItemFormOptions,
  makePurchaseItemFormRecord,
  makeSaleItemTableRow,
} from "./test/factories";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

vi.mock("./components/Form", () => ({
  default: () => <div data-testid="purchase-item-form" />,
}));

vi.mock("./components/SaleItemsTable", () => ({
  default: ({ rows }: { rows: unknown[] }) => (
    <div data-testid="sale-items-table">Rows: {rows.length}</div>
  ),
}));

describe("PurchaseItems/Edit", () => {
  it("renders the page header, view link, related sale items, and form", () => {
    renderEdit();

    expect(screen.getByRole("heading", { name: "Edit Purchase Item 42" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /View Purchase Item/ })).toHaveAttribute(
      "href",
      "/purchase_items/42",
    );
    expect(screen.getByTestId("sale-items-table")).toHaveTextContent("Rows: 1");
    expect(screen.getByTestId("purchase-item-form")).toBeInTheDocument();
  });

  it("shows the error notice when page errors are present", () => {
    mockPageProps({ errors: { base: "Something went wrong" } });

    renderEdit();

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getByText("Something went wrong")).toBeInTheDocument();
  });
});

function renderEdit() {
  return render(
    <Edit
      options={makePurchaseItemFormOptions()}
      purchase_item={makePurchaseItemFormRecord()}
      sale_items_table={[makeSaleItemTableRow()]}
    />,
  );
}
