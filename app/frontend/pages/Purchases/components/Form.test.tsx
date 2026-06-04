import { render, screen } from "@testing-library/react";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Form from "./Form";
import type { PurchaseFormOptions, PurchaseFormRecord, SelectOption } from "../types";

type SmartSelectMockProps = {
  error?: string;
  inputId?: string;
  label?: string;
  name?: string;
  onChange?: (option: SelectOption<number> | null) => void;
  options?: SelectOption<number>[];
  value?: SelectOption<number> | null;
};

let pageErrors: Record<string, string> = {};

vi.mock("@/components/ResourceForm", () => ({
  default: ({
    action,
    cancelHref,
    children,
    method,
    submitLabel,
    validate: _validate,
  }: {
    action: string;
    cancelHref: string;
    children: ReactNode | ((props: { errors: Record<string, string> }) => ReactNode);
    method: string;
    submitLabel: string;
    validate?: unknown;
  }) => (
    <form action={action} data-cancel-href={cancelHref} data-method={method}>
      {typeof children === "function" ? children({ errors: pageErrors }) : children}
      <button type="submit">{submitLabel}</button>
    </form>
  ),
}));

vi.mock("@/components/SmartSelect", () => ({
  default: ({ inputId, label, name, options = [], value }: SmartSelectMockProps) => (
    <select
      aria-label={label ?? inputId}
      data-testid={inputId ?? name}
      id={inputId}
      name={name}
      value={value?.value ?? ""}
      onChange={() => {}}
    >
      <option value="">Select...</option>
      {options.map((opt) => (
        <option key={opt.value} value={opt.value}>
          {opt.label}
        </option>
      ))}
    </select>
  ),
}));

vi.mock("./Form/ProductVariantSelect", () => ({
  default: () => <div data-testid="product-variant-select" />,
}));

const options: PurchaseFormOptions = {
  product_variants_path: "/products/:product_id/variants",
  products: [{ value: 1, label: "Moon Statue" }],
  suppliers: [{ value: 10, label: "Acme Supplies" }],
  warehouses: [{ value: 20, label: "Main Warehouse" }],
};

function makePurchase(overrides: Partial<PurchaseFormRecord> = {}): PurchaseFormRecord {
  return {
    id: null,
    path: "",
    product_id: null,
    variant_id: null,
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
    variant_options: [],
    ...overrides,
  };
}

describe("Purchases/Components/Form", () => {
  beforeEach(() => {
    pageErrors = {};
  });

  it("renders the form shell with correct action and method", () => {
    const { container } = render(
      <Form isNew options={options} purchase={makePurchase()} submitLabel="Create Purchase" />,
    );
    const form = container.querySelector("form");

    expect(form).toHaveAttribute("action", "/purchases");
    expect(form).toHaveAttribute("data-method", "post");
    expect(screen.getByRole("button", { name: "Create Purchase" })).toBeInTheDocument();
  });

  it("uses purchase path and patch for edit", () => {
    const { container } = render(
      <Form
        isNew={false}
        options={options}
        purchase={makePurchase({ id: 5, path: "/purchases/5" })}
        submitLabel="Update Purchase"
      />,
    );
    const form = container.querySelector("form");

    expect(form).toHaveAttribute("action", "/purchases/5");
    expect(form).toHaveAttribute("data-method", "patch");
  });

  it("shows server-side supplier error", () => {
    pageErrors = { supplier_id: "Supplier must exist" };

    render(
      <Form isNew options={options} purchase={makePurchase()} submitLabel="Create Purchase" />,
    );

    expect(screen.getByText("Supplier must exist")).toBeInTheDocument();
  });

  it("shows server-side product error", () => {
    pageErrors = { product_id: "Product must exist" };

    render(
      <Form isNew options={options} purchase={makePurchase()} submitLabel="Create Purchase" />,
    );

    expect(screen.getByText("Product must exist")).toBeInTheDocument();
  });

  it("hides the payment field on edit", () => {
    render(
      <Form
        isNew={false}
        options={options}
        purchase={makePurchase({ path: "/purchases/5" })}
        submitLabel="Update Purchase"
      />,
    );

    expect(screen.queryByLabelText("What did you pay in total?")).not.toBeInTheDocument();
  });
});
