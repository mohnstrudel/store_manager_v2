import { z } from "zod";
import { zodErrorsToRecord } from "@/lib/formSchema";
import { msg } from "@/lib/validationMessages";

const SaleFormSchema = z.object({
  customer_id: z
    .number()
    .nullable()
    .refine((v) => v !== null, msg.blank),
});

type ValidateInput = {
  customer_id: number | null;
};

export function validateSaleForm(input: ValidateInput): Record<string, string> | null {
  const result = SaleFormSchema.safeParse(input);
  if (result.success) return null;
  return zodErrorsToRecord(result.error);
}
