import { describe, expect, it } from "vitest";
import { msg } from "@/utils/validationMessages";
import { validatePurchaseForm } from "./purchaseFormSchema";

describe("validatePurchaseForm", () => {
  it("returns null when all required fields are present", () => {
    expect(
      validatePurchaseForm({ product_id: 1, supplier_id: 1, item_price: "50", amount: "10" }),
    ).toBeNull();
  });

  it("requires product_id", () => {
    const errors = validatePurchaseForm({
      product_id: null,
      supplier_id: 1,
      item_price: "50",
      amount: "10",
    });
    expect(errors).toEqual({ product_id: msg.blank });
  });

  it("requires supplier_id", () => {
    const errors = validatePurchaseForm({
      product_id: 1,
      supplier_id: null,
      item_price: "50",
      amount: "10",
    });
    expect(errors).toEqual({ supplier_id: msg.blank });
  });

  it("requires item_price", () => {
    const errors = validatePurchaseForm({
      product_id: 1,
      supplier_id: 1,
      item_price: "",
      amount: "10",
    });
    expect(errors).toEqual({ item_price: msg.blank });
  });

  it("requires amount", () => {
    const errors = validatePurchaseForm({
      product_id: 1,
      supplier_id: 1,
      item_price: "50",
      amount: "",
    });
    expect(errors).toEqual({ amount: msg.blank });
  });

  it("reports all missing fields at once", () => {
    const errors = validatePurchaseForm({
      product_id: null,
      supplier_id: null,
      item_price: "",
      amount: "",
    });
    expect(errors).toEqual({
      product_id: msg.blank,
      supplier_id: msg.blank,
      item_price: msg.blank,
      amount: msg.blank,
    });
  });
});
