import { z } from "zod";

import { zodErrorsToRecord } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";

const WarehouseFormSchema = z.object({
  name: z.string().min(1, msg.blank),
});

type ValidateInput = {
  name: string;
};

export function validateWarehouseForm(input: ValidateInput): Record<string, string> | null {
  const result = WarehouseFormSchema.safeParse(input);
  if (result.success) return null;
  return zodErrorsToRecord(result.error);
}
