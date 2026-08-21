import { z } from "zod";

import { zodErrorsToRecord } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";

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
