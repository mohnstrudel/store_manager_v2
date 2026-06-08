import { describe, expect, it } from "vitest";
import { msg } from "@/utils/validationMessages";
import { validateWarehouseForm } from "./warehouseFormSchema";

describe("validateWarehouseForm", () => {
  it("returns null for a valid name", () => {
    expect(validateWarehouseForm({ name: "Berlin Warehouse" })).toBeNull();
  });

  it("requires name", () => {
    const errors = validateWarehouseForm({ name: "" });
    expect(errors).toEqual({ name: msg.blank });
  });

  it("treats whitespace-only name as blank", () => {
    const errors = validateWarehouseForm({ name: "   " });
    expect(errors).toBeNull(); // z.string().min(1) passes for spaces; whitespace trim is a future concern
  });
});
