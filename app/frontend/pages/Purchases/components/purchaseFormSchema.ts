import { z } from "zod";
import { zodErrorsToRecord } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";

const requiredNumber = z
  .number()
  .nullable()
  .refine((v) => v !== null, msg.blank);

const PurchaseFormSchema = z.object({
  product_id: requiredNumber,
  supplier_id: requiredNumber,
  item_price: z.string().min(1, msg.blank),
  amount: z.string().min(1, msg.blank),
});

type ValidateInput = {
  product_id: number | null;
  supplier_id: number | null;
  item_price: string;
  amount: string;
};

export function validatePurchaseForm(input: ValidateInput): Record<string, string> | null {
  const result = PurchaseFormSchema.safeParse(input);
  if (result.success) return null;
  return zodErrorsToRecord(result.error);
}
