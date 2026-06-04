import { describe, expect, it } from "vitest";
import { msg } from "@/lib/validationMessages";
import { validateProductForm } from "./productFormSchema";
import type { PurchaseFormData, VariantFormData } from "../types";

function makeVariant(overrides: Partial<VariantFormData> = {}): VariantFormData {
  return {
    id: null,
    sku: "SKU-001",
    size_id: null,
    version_id: null,
    color_id: null,
    purchase_cost: "10",
    selling_price: "20",
    weight: "0.5",
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

const baseInput = {
  title: "Moon Statue",
  variants: [makeVariant()],
  showPurchase: false,
  initialPurchase: makePurchase(),
};

describe("validateProductForm", () => {
  it("returns null for valid input", () => {
    expect(validateProductForm(baseInput)).toBeNull();
  });

  it("requires title", () => {
    const errors = validateProductForm({ ...baseInput, title: "" });
    expect(errors).toEqual({ title: msg.blank });
  });

  it("requires SKU on active variants", () => {
    const errors = validateProductForm({
      ...baseInput,
      variants: [makeVariant({ sku: "" })],
    });
    expect(errors).toEqual({ "variants.0.sku": msg.blank });
  });

  it("skips SKU check for destroyed variants", () => {
    const errors = validateProductForm({
      ...baseInput,
      variants: [makeVariant({ sku: "", _destroy: true })],
    });
    expect(errors).toBeNull();
  });

  it("uses the correct index for the erroring variant", () => {
    const errors = validateProductForm({
      ...baseInput,
      variants: [makeVariant(), makeVariant({ sku: "" })],
    });
    expect(errors).toEqual({ "variants.1.sku": msg.blank });
  });

  it("flags negative purchase_cost on active variant", () => {
    const errors = validateProductForm({
      ...baseInput,
      variants: [makeVariant({ purchase_cost: "-1" })],
    });
    expect(errors?.["variants.0.purchase_cost"]).toBe(msg.notNegative);
  });

  it("ignores purchase section when showPurchase is false", () => {
    const errors = validateProductForm({
      ...baseInput,
      showPurchase: false,
      initialPurchase: makePurchase({ item_price: "bad", amount: "bad" }),
    });
    expect(errors).toBeNull();
  });

  it("validates purchase cross-field when showPurchase is true and partially filled", () => {
    const errors = validateProductForm({
      ...baseInput,
      showPurchase: true,
      initialPurchase: makePurchase({ item_price: "10" }),
    });
    expect(errors?.["purchase.0.supplier_id"]).toBe(msg.blank);
    expect(errors?.["purchase.0.amount"]).toBe(msg.blank);
    expect(errors?.["purchase.0.item_price"]).toBeUndefined();
  });

  it("accepts a fully filled purchase", () => {
    const errors = validateProductForm({
      ...baseInput,
      showPurchase: true,
      initialPurchase: makePurchase({
        supplier_id: 1,
        item_price: "50",
        amount: "5",
      }),
    });
    expect(errors).toBeNull();
  });

  it("skips purchase validation when all purchase fields are empty", () => {
    const errors = validateProductForm({
      ...baseInput,
      showPurchase: true,
      initialPurchase: makePurchase(),
    });
    expect(errors).toBeNull();
  });
});
