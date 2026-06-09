import { z } from "zod";
import { msg } from "./validationMessages";

export const nonNegativeNumber = z.coerce.number({ error: msg.notANumber }).min(0, msg.notNegative);

export function getFormString(formData: FormData, key: string): string {
  const value = formData.get(key);
  return typeof value === "string" ? value : "";
}

export function zodErrorsToRecord(error: z.ZodError): Record<string, string> {
  const result: Record<string, string> = {};
  for (const issue of error.issues) {
    const key = issue.path.join(".");
    if (key && !result[key]) result[key] = issue.message;
  }
  return result;
}
