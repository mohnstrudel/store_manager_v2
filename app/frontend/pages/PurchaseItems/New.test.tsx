import { render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

import { mockPageProps } from "@/test/mocks/inertia";

import New from "./New";
import { makePurchaseItemFormOptions, makePurchaseItemFormRecord } from "./test/factories";

vi.mock("./components/Form", () => ({
  default: () => <div data-testid="purchase-item-form" />,
}));

describe("PurchaseItems/New", () => {
  it("renders the page header, back link, and form", () => {
    render(
      <New
        cancel_path="/warehouses/1"
        form_action="/purchase_items"
        options={makePurchaseItemFormOptions()}
        purchase_item={makePurchaseItemFormRecord({ id: null, path: "" })}
      />,
    );

    expect(screen.getByRole("heading", { name: "New Purchase Item" })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Back to Warehouse/ })).toHaveAttribute(
      "href",
      "/warehouses/1",
    );
    expect(screen.getByTestId("purchase-item-form")).toBeInTheDocument();
  });

  it("shows the error notice when page errors are present", () => {
    mockPageProps({ errors: { base: "Something went wrong" } });

    render(
      <New
        cancel_path="/warehouses/1"
        form_action="/purchase_items"
        options={makePurchaseItemFormOptions()}
        purchase_item={makePurchaseItemFormRecord({ id: null, path: "" })}
      />,
    );

    expect(screen.getByText("Fix errors and try again")).toBeInTheDocument();
    expect(screen.getByText("Something went wrong")).toBeInTheDocument();
  });
});
