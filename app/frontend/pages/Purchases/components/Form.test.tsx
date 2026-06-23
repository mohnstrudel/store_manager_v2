import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { mockPageProps } from "@/test/mocks/inertia";
import { lastCapturedProps } from "@/test/mocks/resourceForm";
import Form from "./Form";
import { makePurchaseForm, makePurchaseFormOptions } from "../test/factories";

vi.mock("@/components/ResourceForm", () => import("@/test/mocks/resourceForm"));

vi.mock("@/components/SmartSelect", () => import("@/test/mocks/smartSelect"));

vi.mock("./Form/ProductVariantSelect", () => ({
  default: () => <div data-testid="product-variant-select" />,
}));

describe("Purchases/components/Form", () => {
  beforeEach(() => {
    mockPageProps({});
  });

  describe("form shell", () => {
    it("configures action, method, and labels for a new purchase", () => {
      renderForm({ isNew: true, submitLabel: "Create Purchase" });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/purchases",
          cancelHref: "/purchases",
          method: "post",
          submitLabel: "Create Purchase",
        }),
      );
      expect(screen.getByRole("button", { name: "Create Purchase" })).toBeInTheDocument();
    });

    it("configures action, method, and labels for an existing purchase", () => {
      renderForm({
        isNew: false,
        purchase: makePurchaseForm({ id: 5, path: "/purchases/5" }),
        submitLabel: "Update Purchase",
      });

      expect(lastCapturedProps()).toEqual(
        expect.objectContaining({
          action: "/purchases/5",
          cancelHref: "/purchases",
          method: "patch",
          submitLabel: "Update Purchase",
        }),
      );
    });
  });

  describe("error routing", () => {
    it("shows server-side supplier error", () => {
      mockPageProps({ errors: { supplier_id: "Supplier must exist" } });

      renderForm();

      expect(screen.getByText("Supplier must exist")).toBeInTheDocument();
    });

    it("shows server-side product error", () => {
      mockPageProps({ errors: { product_id: "Product must exist" } });

      renderForm();

      expect(screen.getByText("Product must exist")).toBeInTheDocument();
    });
  });

  describe("field sections", () => {
    it("hides the payment field on edit", () => {
      renderForm({
        isNew: false,
        purchase: makePurchaseForm({ path: "/purchases/5" }),
        submitLabel: "Update Purchase",
      });

      expect(screen.queryByLabelText("What did you pay in total?")).not.toBeInTheDocument();
    });
  });
});

function renderForm({
  isNew = true,
  options = makePurchaseFormOptions(),
  purchase = makePurchaseForm(),
  submitLabel = "Create Purchase",
}: {
  isNew?: boolean;
  options?: ReturnType<typeof makePurchaseFormOptions>;
  purchase?: ReturnType<typeof makePurchaseForm>;
  submitLabel?: string;
} = {}) {
  return render(
    <Form isNew={isNew} options={options} purchase={purchase} submitLabel={submitLabel} />,
  );
}
