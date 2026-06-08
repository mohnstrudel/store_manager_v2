import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import PurchaseItems from "../Show/PurchaseItems";
import type { PurchaseItemRecord, PurchaseShowRecord } from "../types";

const inertia = vi.hoisted(() => ({
  nextErrors: null as Record<string, string> | null,
  patch: vi.fn<(...args: unknown[]) => void>(),
  visit: vi.fn<(...args: unknown[]) => unknown>(),
}));

vi.mock("@inertiajs/react", async () => {
  const React = await vi.importActual<typeof import("react")>("react");

  return {
    usePage: () => ({ url: "/purchases/1" }),
    Link: ({
      children,
      href,
      prefetch: _prefetch,
      ...props
    }: {
      children: ReactNode;
      href: string;
      prefetch?: boolean;
    }) => (
      <a href={href} {...props}>
        {children}
      </a>
    ),
    router: {
      prefetch: vi.fn<(...args: unknown[]) => unknown>(),
      visit: inertia.visit,
    },
    useForm: <TData extends Record<string, unknown>>(initialData: TData) => {
      const [data, setDataState] = React.useState(initialData);
      const [errors, setErrors] = React.useState<Record<string, string>>({});
      let optimisticCallback: ((props: unknown) => unknown) | null = null;
      let transformPayload: ((data: TData) => unknown) | null = null;

      const form = {
        clearErrors: (...fields: string[]) => {
          setErrors((currentErrors) => {
            if (fields.length === 0) return {};
            return Object.fromEntries(
              Object.entries(currentErrors).filter(([field]) => !fields.includes(field)),
            );
          });
        },
        data,
        errors,
        optimistic: (callback: (props: unknown) => unknown) => {
          optimisticCallback = callback;
          return form;
        },
        transform: (callback: (data: TData) => unknown) => {
          transformPayload = callback;
        },
        patch: (path: string, options: Record<string, (...args: unknown[]) => unknown>) => {
          options.onBefore?.();
          inertia.patch(
            path,
            transformPayload ? transformPayload(data) : data,
            options,
            optimisticCallback,
          );

          if (inertia.nextErrors) {
            setErrors(inertia.nextErrors);
            options.onError?.(inertia.nextErrors);
            inertia.nextErrors = null;
          } else {
            options.onSuccess?.();
          }
        },
        setData: (update: TData | ((data: TData) => TData)) => {
          setDataState((currentData) =>
            typeof update === "function" ? (update as (data: TData) => TData)(currentData) : update,
          );
        },
      };

      return form;
    },
  };
});

const defaultProps = {
  movePath: "/purchase_items/move",
  purchase: makePurchase(),
  shippingCompanies: [{ id: 3, name: "Skyline" }],
  warehouses: [{ id: 1, name: "Warehouse A" }],
};

describe("PurchaseItems inline editors", () => {
  beforeEach(() => {
    inertia.patch.mockClear();
    inertia.visit.mockClear();
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

    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/tracking_number",
      {
        purchase_item: { tracking_number: "TRACK-99" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      expect.any(Function),
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

    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_company",
      {
        purchase_item: { shipping_company_id: "3" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      expect.any(Function),
    );
    expect(screen.getByRole("button", { name: "Edit shipping company" }).closest("td")).toHaveClass(
      "bg-lime-100/80",
    );
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

    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_cost",
      {
        purchase_item: { shipping_cost: "20" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      expect.any(Function),
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

    expect(inertia.patch).toHaveBeenCalledOnce();
    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: { tracking_number: "", shipping_company_id: null, shipping_cost: "0" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      null,
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

    expect(inertia.patch).toHaveBeenCalledOnce();
    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: { tracking_number: "TRACK-42", shipping_company_id: "3", shipping_cost: "0" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      null,
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

    expect(inertia.patch).toHaveBeenCalledOnce();
    expect(inertia.patch).toHaveBeenCalledWith(
      "/purchase_items/10/shipping_details",
      {
        purchase_item: { tracking_number: "", shipping_company_id: "3", shipping_cost: "0" },
        return_to: "/purchases/1",
      },
      expect.objectContaining({ preserveScroll: true }),
      null,
    );
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
    expect(inertia.patch).not.toHaveBeenCalled();
  });

  it("keeps server-side tracking errors visible in the editor", async () => {
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

    inertia.nextErrors = { tracking_number: "Tracking number can't be blank" };

    await user.click(screen.getByRole("button", { name: "Edit tracking number" }));
    await user.clear(screen.getByLabelText("Tracking number"));
    await user.click(screen.getByRole("button", { name: "Save" }));

    expect(screen.getByText("Tracking number can't be blank")).toBeInTheDocument();
    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
  });

  it("shows shipping company error in the shipping company editor on bulk save failure", async () => {
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
    });
    await user.type(screen.getByLabelText("Tracking number"), "TRACK-1");

    inertia.nextErrors = { shipping_company_id: "can't be blank" };

    const trackingForm = screen.getByLabelText("Tracking number").closest("form");
    if (!trackingForm) throw new Error("Expected tracking form");
    await user.click(within(trackingForm).getByRole("button", { name: "Save" }));

    // Error appears under the shipping company editor — that's the blank field
    const shippingForm = screen.getByLabelText("Shipping company").closest("form");
    if (!shippingForm) throw new Error("Expected shipping company editor form");
    expect(within(shippingForm).getByText("Shipping company is required")).toBeInTheDocument();

    // Tracking editor shows no error — the user filled it in correctly
    expect(within(trackingForm).queryByRole("alert")).not.toBeInTheDocument();

    // Tracking input preserves the value the user typed before saving
    expect(screen.getByLabelText("Tracking number")).toHaveValue("TRACK-1");

    // All three editors remain open
    expect(screen.getByLabelText("Tracking number")).toBeInTheDocument();
    expect(screen.getByLabelText("Shipping company")).toBeInTheDocument();
    expect(screen.getByLabelText("Shipping cost")).toBeInTheDocument();
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
