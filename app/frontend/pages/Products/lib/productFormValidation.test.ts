import { describe, expect, it } from "vitest";
import { msg } from "@/lib/validationMessages";
import { validateProductFormSubmission } from "./productFormValidation";
import type { PurchaseFormData, VariantFormData } from "../types";

function makeVariant(overrides: Partial<VariantFormData> = {}): VariantFormData {
  return {
    id: null,
    sku: "",
    size_id: null,
    version_id: null,
    color_id: null,
    purchase_cost: "0",
    selling_price: "0",
    weight: "0",
    deactivated: false,
    has_sales_or_purchases: false,
    _destroy: false,
    ...overrides,
  };
}

function makePurchase(overrides: Partial<PurchaseFormData> = {}): PurchaseFormData {
  return {
    supplier_id: null,
    order_reference: "",
    item_price: "",
    amount: "",
    warehouse_id: null,
    payment_value: "",
    ...overrides,
  };
}

function makeFormData(entries: [string, string][]): FormData {
  const formData = new FormData();
  for (const [key, value] of entries) {
    formData.append(key, value);
  }
  return formData;
}

describe("validateProductFormSubmission", () => {
  it("uses the current submitted values for nested fields", () => {
    const errors = validateProductFormSubmission({
      formData: makeFormData([
        ["product[title]", "Product With Purchase"],
        ["variants[0][sku]", "product-with-initial-purchase-variant"],
        ["variants[0][purchase_cost]", "9.99"],
        ["variants[0][selling_price]", "19.99"],
        ["variants[0][weight]", "1.5"],
        ["purchase[supplier_id]", "40"],
        ["purchase[item_price]", "15"],
        ["purchase[amount]", "2"],
        ["purchase[payment_value]", "30"],
        ["purchase[warehouse_id]", "50"],
      ]),
      initialPurchase: makePurchase(),
      showPurchase: true,
      variants: [makeVariant()],
    });

    expect(errors).toBeNull();
  });

  it("adds a purchase summary error when the purchase is partially filled in", () => {
    const errors = validateProductFormSubmission({
      formData: makeFormData([
        ["product[title]", "Product With Invalid Purchase"],
        ["variants[0][sku]", "product-with-invalid-initial-purchase-variant"],
        ["variants[0][purchase_cost]", "9.99"],
        ["variants[0][selling_price]", "19.99"],
        ["variants[0][weight]", "1.5"],
        ["purchase[item_price]", "15"],
        ["purchase[amount]", "2"],
        ["purchase[payment_value]", "30"],
      ]),
      initialPurchase: makePurchase(),
      showPurchase: true,
      variants: [makeVariant()],
    });

    expect(errors?.["purchase.0.supplier_id"]).toBe(msg.blank);
    expect(errors?.initial_purchase).toBe(msg.invalid);
  });

  it("adds a variant summary error when a nested variant field is invalid", () => {
    const errors = validateProductFormSubmission({
      formData: makeFormData([
        ["product[title]", "Product With Invalid Variant"],
        ["variants[0][sku]", ""],
        ["variants[0][purchase_cost]", "9.99"],
        ["variants[0][selling_price]", "19.99"],
        ["variants[0][weight]", "1.5"],
      ]),
      initialPurchase: makePurchase(),
      showPurchase: false,
      variants: [makeVariant({ sku: "default-sku" })],
    });

    expect(errors?.["variants.0.sku"]).toBe(msg.blank);
    expect(errors?.variants).toBe(msg.invalid);
  });
});
