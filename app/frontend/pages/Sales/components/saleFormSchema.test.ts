import { describe, expect, it } from "vitest";
import { msg } from "@/utils/validationMessages";
import { validateSaleForm } from "./saleFormSchema";

describe("validateSaleForm", () => {
  it("returns null when customer is selected", () => {
    expect(validateSaleForm({ customer_id: 5 })).toBeNull();
  });

  it("requires customer_id", () => {
    const errors = validateSaleForm({ customer_id: null });
    expect(errors).toEqual({ customer_id: msg.blank });
  });
});
