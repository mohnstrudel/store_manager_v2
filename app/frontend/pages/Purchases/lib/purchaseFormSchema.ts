import { z } from "zod";
import { zodErrorsToRecord } from "@/lib/formSchema";
import { msg } from "@/lib/validationMessages";

const PurchaseFormSchema = z.object({
  supplier_id: z
    .number()
    .nullable()
    .refine((v) => v !== null, msg.blank),
  item_price: z.string().min(1, msg.blank),
  amount: z.string().min(1, msg.blank),
});

type ValidateInput = {
  supplier_id: number | null;
  item_price: string;
  amount: string;
};

export function validatePurchaseForm(input: ValidateInput): Record<string, string> | null {
  const result = PurchaseFormSchema.safeParse(input);
  if (result.success) return null;
  return zodErrorsToRecord(result.error);
}
