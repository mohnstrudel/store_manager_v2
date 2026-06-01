import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { ReactNode } from "react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Show from "./Show";
import type {
  NewPaymentRecord,
  PaymentRecord,
  PurchaseItemRecord,
  PurchaseShowRecord,
  WarehouseOption,
} from "./types";

const deletePurchase = vi.hoisted(() => vi.fn<(...args: unknown[]) => unknown>());

vi.mock("@inertiajs/react", () => ({
  Link: ({ children, href, ...props }: { children: ReactNode; href: string }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
  router: {
    delete: deletePurchase,
    post: vi.fn<(...args: unknown[]) => unknown>(),
  },
}));

vi.mock("./components/PurchaseItems", () => ({
  default: ({
    movePath,
    purchaseItems,
    warehouses,
  }: {
    movePath: string;
    purchaseItems: PurchaseItemRecord[];
    warehouses: WarehouseOption[];
  }) => (
    <section data-testid="purchase-items">
      Items: {purchaseItems.length}, warehouses: {warehouses.length}, move: {movePath}
    </section>
  ),
}));

vi.mock("./components/Details", () => ({
  default: ({ purchase }: { purchase: PurchaseShowRecord }) => (
    <section data-testid="purchase-details">Details for {purchase.product_title}</section>
  ),
}));

vi.mock("./components/Payments", () => ({
  default: ({
    newPayment,
    payments,
  }: {
    newPayment: NewPaymentRecord;
    payments: PaymentRecord[];
  }) => (
    <section data-testid="payments">
      Payments: {payments.length}, new: {newPayment.value}
    </section>
  ),
}));

describe("Purchases/Show", () => {
  beforeEach(() => {
    deletePurchase.mockClear();
  });

  it("renders the purchase header, edit action, and page sections", () => {
    renderShow();

    expect(screen.getByRole("heading", { name: /Purchase 55/ })).toBeInTheDocument();
    expect(screen.getByRole("link", { name: /Edit/ })).toHaveAttribute(
      "href",
      "/purchases/55/edit",
    );
    expect(screen.getByTestId("purchase-items")).toHaveTextContent(
      "Items: 1, warehouses: 1, move: /purchase_items/move",
    );
    expect(screen.getByTestId("purchase-details")).toHaveTextContent("Details for Pikachu Figure");
    expect(screen.getByTestId("payments")).toHaveTextContent("Payments: 1, new: 10.00");
  });

  it("destroys the purchase after confirmation", async () => {
    const user = userEvent.setup();
    vi.spyOn(window, "confirm").mockReturnValue(true);
    renderShow();

    await user.click(screen.getByRole("button", { name: "Destroy this purchase" }));

    expect(window.confirm).toHaveBeenCalledWith("Are you sure?");
    expect(deletePurchase).toHaveBeenCalledWith("/purchases/55");
  });
});

function renderShow({
  newPayment = makeNewPayment(),
  payments = [makePayment()],
  purchase = makePurchase(),
  purchaseItems = [makePurchaseItem()],
  warehouseMovePath = "/purchase_items/move",
  warehouses = [{ id: 1, name: "Berlin Hub" }],
}: {
  newPayment?: NewPaymentRecord;
  payments?: PaymentRecord[];
  purchase?: PurchaseShowRecord;
  purchaseItems?: PurchaseItemRecord[];
  warehouseMovePath?: string;
  warehouses?: WarehouseOption[];
} = {}) {
  return render(
    <Show
      new_payment={newPayment}
      payments={payments}
      purchase={purchase}
      purchase_items={purchaseItems}
      warehouse_move_path={warehouseMovePath}
      warehouses={warehouses}
    />,
  );
}

function makePurchase(): PurchaseShowRecord {
  return {
    id: 55,
    path: "/purchases/55",
    edit_path: "/purchases/55/edit",
    destroy_path: "/purchases/55",
    product_path: "/products/1",
    product_title: "Pikachu Figure",
    product_image_url: null,
    product_thumb_url: null,
    variant_title: "Default",
    amount: 2,
    item_price: "100.00",
    cost_total: "200.00",
    shipping_total: "10.00",
    paid: "50.00",
    debt: "160.00",
    supplier_title: "Acme Imports",
    supplier_path: "/suppliers/1",
    order_reference: "PO-55",
    date: "20 May 2026",
    payment_progress: { progress: 25, paid: "50.00", price: "210.00", debt: "160.00" },
  };
}

function makePurchaseItem(): PurchaseItemRecord {
  return {
    id: 1,
    path: "/purchase_items/1",
    edit_path: "/purchase_items/1/edit",
    unlink_path: "/purchase_items/1/unlink",
    warehouse_name: "Berlin Hub",
    warehouse_path: "/warehouses/1",
    sale_title: "Sale 1",
    sale_path: "/sales/1",
    sale_address: "Berlin",
    customer_email: "dale@fbi.gov",
    shipping_cost: "5.00",
  };
}

function makePayment(): PaymentRecord {
  return {
    id: 1,
    update_path: "/payments/1",
    destroy_path: "/payments/1",
    payment_date: "20 May 2026",
    value: "50.00",
    errors: [],
  };
}

function makeNewPayment(): NewPaymentRecord {
  return {
    create_path: "/payments",
    payment_date: "21 May 2026",
    value: "10.00",
    errors: [],
  };
}
