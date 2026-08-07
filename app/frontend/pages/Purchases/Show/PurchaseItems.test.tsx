import { act, render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { router } from "@inertiajs/react";
import { mockPage } from "@/test/mocks/inertia";
import PurchaseItems from "./PurchaseItems";
import {
  makePurchaseItem,
  makePurchaseItemExpense,
  makePurchaseShow,
  makeShippingCompanyOption,
  makeWarehouseOption,
} from "../test/factories";

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

const defaultProps = {
  movePath: "/purchase_items/move",
  purchase: makePurchaseShow({
    amount: 1,
    cost_total: "10.00",
    date: "01 Jan 2026",
    debt: "10.00",
    id: 1,
    item_price: "10.00",
    order_reference: "REF-1",
    paid: "0.00",
    path: "/purchases/1",
    payment_progress: {
      debt: "10.00",
      paid: "0.00",
      price: "10.00",
      progress: 0,
    },
    product_image_url: null,
    product_title: "Blue Widget",
    shipping_total: "0.00",
    supplier_title: "Supplier A",
    variant_title: "",
  }),
  shippingCompanies: [makeShippingCompanyOption()],
  warehouses: [makeWarehouseOption({ name: "Warehouse A" })],
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

  it("shows nothing for a zero shipping cost, but shows a real cost", () => {
    const { rerender } = render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ id: 10, shipping_cost: "0" })]}
      />,
    );

    expect(screen.getByRole("button", { name: "Edit shipping cost" })).toHaveTextContent("");

    rerender(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[makePurchaseItem({ id: 10, shipping_cost: "12" })]}
      />,
    );

    expect(screen.getByRole("button", { name: "Edit shipping cost" })).toHaveTextContent("12");
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

  it("starts an empty item expense section closed without a gradient", () => {
    render(<PurchaseItems {...defaultProps} purchaseItems={[makePurchaseItem()]} />);

    const details = screen.getByText("Item direct expenses").closest("details");
    expect(details).not.toHaveAttribute("open");
    expect(details?.closest("td")).toHaveClass("bg-transparent");
    expect(details?.closest("td")).not.toHaveClass("bg-linear-to-t");
  });

  it("starts an item expense section closed and summarizes existing expenses", () => {
    render(
      <PurchaseItems
        {...defaultProps}
        purchaseItems={[
          makePurchaseItem({
            purchase_expenses: [
              makePurchaseItemExpense({ id: 1, amount: "10" }),
              makePurchaseItemExpense({ id: 2, amount: "12.5" }),
            ],
          }),
        ]}
      />,
    );

    const details = screen.getByText("Item direct expenses (2 · 22.5 total)").closest("details");
    expect(details).not.toHaveAttribute("open");
    expect(details?.closest("td")).toHaveClass("bg-transparent");
    expect(details?.closest("td")).not.toHaveClass("bg-linear-to-t");
  });

  it("adds and removes the item expense gradient as the section toggles", async () => {
    const user = userEvent.setup();
    render(<PurchaseItems {...defaultProps} purchaseItems={[makePurchaseItem()]} />);

    const summary = screen.getByText("Item direct expenses");
    const details = summary.closest("details");
    await user.click(summary);
    expect(details).toHaveAttribute("open");
    expect(details?.closest("td")).toHaveClass("bg-linear-to-t");

    await user.click(summary);
    expect(details).not.toHaveAttribute("open");
    expect(details?.closest("td")).not.toHaveClass("bg-linear-to-t");
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
          ...makePurchaseShow({
            amount: 1,
            cost_total: "10.00",
            date: "01 Jan 2026",
            debt: "10.00",
            id: 1,
            item_price: "10.00",
            order_reference: "REF-1",
            paid: "0.00",
            path: "/purchases/1",
            payment_progress: {
              debt: "10.00",
              paid: "0.00",
              price: "10.00",
              progress: 0,
            },
            product_image_url: null,
            product_title: "Blue Widget",
            shipping_total: "0.00",
            supplier_title: "Supplier A",
            variant_title: "",
          }),
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

function hasOnSuccess(value: unknown): value is { onSuccess?: () => void } {
  return typeof value === "object" && value !== null;
}
