import { act, render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import { mockPage } from "@/test/mocks/inertia";
import PurchaseItems from "./PurchaseItems";
import type { PurchaseItemRecord, PurchaseShowRecord } from "../types";

vi.mock("@inertiajs/react", () => import("@/test/mocks/inertia"));

const defaultProps = {
  movePath: "/purchase_items/move",
  purchase: makePurchase(),
  shippingCompanies: [{ id: 3, name: "Skyline" }],
  warehouses: [{ id: 1, name: "Warehouse A" }],
};

afterEach(() => {
  vi.restoreAllMocks();
});

describe("Purchases/Show/PurchaseItems", () => {
  beforeEach(() => {
    mockPage({ url: "/purchases/1" });
  });

  it("edits tracking number inline", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            shipping_company_id: 3,
            shipping_company_name: "Skyline",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.clear(screen.getByLabelText("Tracking number"));
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-99");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/tracking_number",
      {
        purchase_item: { tracking_number: "TRACK-99" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.queryByLabelText("Tracking number")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Edit tracking number" }).closest("td")).toHaveClass(
      "bg-lime-100/80",
    );
  });

  it("edits shipping company inline", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ shipping_company_id: null })]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));
    expect(screen.getByLabelText("Shipping company")).toHaveFocus();
    await user.selectOptions(screen.getByLabelText("Shipping company"), "3");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_company",
      {
        purchase_item: { shipping_company_id: "3" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.getByRole("button", { name: "Edit shipping company" }).closest("td")).toHaveClass(
      "bg-lime-100/80",
    );
  });

  it("unlinks a purchase item after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            sale_path: "/sales/1",
            sale_title: "Sale 1",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: /Unlink/ }));

    expect(window.confirm).toHaveBeenCalledWith("Unlink this purchase item?");
    expect(router.delete).toHaveBeenCalledWith("/purchase_items/10/unlink");
  });

  it("edits shipping cost inline", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ shipping_cost: "12" })]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping cost" }));
    expect(screen.getByLabelText("Shipping cost")).toHaveFocus();
    await user.clear(screen.getByLabelText("Shipping cost"));
    await user.type(screen.getByLabelText("Shipping cost"), "20.00");
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_cost",
      {
        purchase_item: { shipping_cost: "20" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
    expect(screen.queryByLabelText("Shipping cost")).not.toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Edit shipping cost" }).closest("td")).toHaveClass(
      "bg-lime-100/80",
    );
  });

  it("auto-opens the shipping editor when editing tracking with no company (non-blank row)", async () => {
    const user = userEvent.setup();

    // Has a tracking number → not a blank row; only shipping auto-opens, not cost
    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ shipping_company_id: null })]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.getByLabelText("Tracking number")).toHaveFocus();
    await waitFor(() => {
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
    });
    expect(screen.queryByLabelText("Shipping cost")).not.toBeInTheDocument();
  });

  it("opens all three editors when clicking tracking on a blank row", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            tracking_number: "",
            shipping_company_id: null,
            shipping_cost: "0",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    await waitFor(() => {
      expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
      expect(screen.getByLabelText("Tracking number")).toHaveFocus();
    });

    expect(screen.getByLabelText("Shipping cost")).toHaveDisplayValue("");
  });

  it("opens all three editors when clicking shipping company on a blank row", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            tracking_number: "",
            shipping_company_id: null,
            shipping_cost: "0",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));

    await waitFor(() => {
      expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
      expect(screen.getByLabelText("Tracking number")).toHaveFocus();
    });

    expect(screen.getByLabelText("Shipping cost")).toHaveDisplayValue("");
  });

  it("opens all three editors when clicking shipping cost on a blank row", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            tracking_number: "",
            shipping_company_id: null,
            shipping_cost: "0",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping cost" }));

    await waitFor(() => {
      expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
      expect(screen.getByLabelText("Tracking number")).toHaveFocus();
    });

    const shippingCostInput = screen.getByLabelText("Shipping cost");
    expect(shippingCostInput).toHaveDisplayValue("");

    const shippingCostForm = shippingCostInput.closest("form");
    if (!shippingCostForm) {
      throw new Error("Expected shipping cost editor form");
    }

    await user.click(within(shippingCostForm).getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledOnce();
    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: { tracking_number: "", shipping_company_id: null, shipping_cost: "0" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
  });

  it("bulk-saves all three when saving tracking number on a blank row", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            tracking_number: "",
            shipping_company_id: null,
            shipping_cost: "0",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    await waitFor(() => {
      expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
    });

    await user.type(screen.getByLabelText("Tracking number"), "TRACK-42");
    await user.selectOptions(screen.getByLabelText("Shipping company"), "3");

    const trackingForm = screen.getByLabelText("Tracking number").closest("form");
    if (!trackingForm) throw new Error("Expected tracking number editor form");

    await user.click(within(trackingForm).getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledOnce();
    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: {
          tracking_number: "TRACK-42",
          shipping_company_id: "3",
          shipping_cost: "0",
        },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
  });

  it("bulk-saves all three when saving shipping company on a blank row", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            tracking_number: "",
            shipping_company_id: null,
            shipping_cost: "0",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit shipping company" }));

    await waitFor(() => {
      expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
      expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
    });

    await user.selectOptions(screen.getByLabelText("Shipping company"), "3");

    const shippingForm = screen.getByLabelText("Shipping company").closest("form");
    if (!shippingForm) throw new Error("Expected shipping company editor form");

    await user.click(within(shippingForm).getByRole("button", { name: "Save" }));

    expect(router.patch).toHaveBeenCalledOnce();
    expect(router.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: { tracking_number: "", shipping_company_id: "3", shipping_cost: "0" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
    );
  });

  it("reveals the move form and posts the selected purchase items", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            sale_path: "/sales/1",
            sale_title: "Sale 1",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("checkbox"));
    expect(screen.getByRole("button", { name: /Move/ })).toBeInTheDocument();

    await user.selectOptions(screen.getByRole("combobox"), "1");
    await user.click(screen.getByRole("button", { name: /Move/ }));

    expect(router.post).toHaveBeenCalledWith(
      "/purchase_items/move",
      {
        destination_id: "1",
        purchase_id: 1,
        redirect_to_sale_item: true,
        selected_items_ids: [10],
      },
      expect.objectContaining({ onSuccess: expect.any(Function) }),
    );

    const postMock = vi.mocked(router.post);
    const options = postMock.mock.calls[0][2];
    if (!hasOnSuccess(options)) {
      throw new Error("Expected move success callback");
    }
    await act(async () => {
      options.onSuccess?.();
    });
    expect(screen.queryByRole("button", { name: /Move/ })).not.toBeInTheDocument();
  });

  it("does not auto-open shipping editor when tracking already has a company", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            shipping_company_id: 3,
            shipping_company_name: "Skyline",
          }),
        ]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));

    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.queryByLabelText("Shipping company")).not.toBeInTheDocument();
  });

  it("shows shipping required error when saving tracking without a company", async () => {
    const user = userEvent.setup();

    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ shipping_company_id: null })]}
      />,
    );

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-1");
    await user.click(screen.getAllByRole("button", { name: "Save" })[0]);

    expect(screen.getByText("Shipping company is required")).toBeInTheDocument();
    expect(router.patch).not.toHaveBeenCalled();
  });

  it("renders the purchase heading without a product link when the product is missing", () => {
    render(
      <PurchaseItems
        {...defaultProps}
        purchase={{
          ...makePurchase(),
          product_path: null,
          product_title: "Unknown product",
        }}
        purchaseItems={[makePurchaseItem()]}
      />,
    );

    expect(screen.getByText("Unknown product")).toBeInTheDocument();
    expect(screen.queryByRole("link", { name: "Unknown product" })).not.toBeInTheDocument();
  });
});

function makePurchase(): PurchaseShowRecord {
  return {
    id: 1,
    path: "/purchases/1",
    edit_path: "/purchases/1/edit",
    destroy_path: "/purchases/1",
    product_path: "/products/1",
    product_title: "Blue Widget",
    product_image_url: null,
    product_thumb_url: null,
    variant_title: "",
    amount: 1,
    item_price: "$10.00",
    cost_total: "$10.00",
    shipping_total: "$0.00",
    paid: "$0.00",
    debt: "$10.00",
    supplier_title: "Supplier A",
    supplier_path: "/suppliers/1",
    order_reference: "REF-1",
    date: "01 Jan 2026",
    payment_progress: {
      debt: "$10.00",
      paid: "$0.00",
      price: "$10.00",
      progress: 0,
    },
  };
}

function makePurchaseItem(overrides: Partial<PurchaseItemRecord> = {}): PurchaseItemRecord {
  return {
    id: 10,
    path: "/purchase_items/10",
    edit_path: "/purchase_items/10/edit",
    unlink_path: "/purchase_items/10/unlink",
    warehouse_name: "Warehouse A",
    warehouse_path: "/warehouses/1",
    warehouse_movements: [],
    sale_title: "",
    sale_path: null,
    sale_address: "",
    customer_email: "",
    tracking_number: "TRACK-1",
    shipping_company_id: null,
    shipping_company_name: "",
    shipping_cost: "0",
    ...overrides,
  };
}

function hasOnSuccess(value: unknown): value is { onSuccess?: () => void } {
  return typeof value === "object" && value !== null;
}
