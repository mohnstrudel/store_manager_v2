import { z } from "zod";

import { nonNegativeNumber, zodErrorsToRecord } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";

import type { PurchaseFormData, VariantFormData } from "../types";

const VariantSchema = z
  .object({
    _destroy: z.boolean(),
    sku: z.string(),
    purchase_cost: z.string(),
    selling_price: z.string(),
    weight: z.string(),
  })
  .superRefine((data, ctx) => {
    if (data._destroy) return;
    if (!data.sku.trim()) {
      ctx.addIssue({ code: "custom", path: ["sku"], message: msg.blank });
    }
    for (const field of ["purchase_cost", "selling_price", "weight"] as const) {
      if (!nonNegativeNumber.safeParse(data[field]).success) {
        ctx.addIssue({
          code: "custom",
          path: [field],
          message: msg.notNegative,
        });
      }
    }
  });

const ProductCoreSchema = z.object({
  title: z.string().min(1, msg.blank),
  variants: z.array(VariantSchema),
});

const PurchaseSchema = z
  .object({
    supplier_id: z.number().nullable(),
    item_price: z.string(),
    amount: z.string(),
  })
  .superRefine((data, ctx) => {
    const anyFilled =
      data.supplier_id !== null || data.item_price.trim() !== "" || data.amount.trim() !== "";
    if (!anyFilled) return;
    if (data.supplier_id === null) {
      ctx.addIssue({
        code: "custom",
        path: ["supplier_id"],
        message: msg.blank,
      });
    }
    if (!data.item_price.trim()) {
      ctx.addIssue({
        code: "custom",
        path: ["item_price"],
        message: msg.blank,
      });
    }
    if (!data.amount.trim()) {
      ctx.addIssue({ code: "custom", path: ["amount"], message: msg.blank });
    }
  });

type ValidateInput = {
  title: string;
  variants: VariantFormData[];
  showPurchase: boolean;
  initialPurchase: PurchaseFormData;
};

export function validateProductForm({
  title,
  variants,
  showPurchase,
  initialPurchase,
}: ValidateInput): Record<string, string> | null {
  const coreResult = ProductCoreSchema.safeParse({ title, variants });
  const errors: Record<string, string> = coreResult.success
    ? {}
    : zodErrorsToRecord(coreResult.error);

  if (showPurchase) {
    const purchaseResult = PurchaseSchema.safeParse(initialPurchase);
    if (!purchaseResult.success) {
      for (const [key, value] of Object.entries(zodErrorsToRecord(purchaseResult.error))) {
        errors[`purchase.0.${key}`] = value;
      }
    }
  }

  return Object.keys(errors).length > 0 ? errors : null;
}
