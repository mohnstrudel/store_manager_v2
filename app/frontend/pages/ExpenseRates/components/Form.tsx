import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import ResourceForm from "@/components/ResourceForm";
import { getFormString } from "@/utils/formSchema";
import { msg } from "@/utils/validationMessages";

import { ExpenseRateRecord } from "../types";

type ExpenseRateFormProps = {
  expenseRate: ExpenseRateRecord;
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

function validate(formData: FormData) {
  const errors: Record<string, string> = {};

  if (!getFormString(formData, "expense_rate[name]").trim()) {
    errors.name = msg.blank;
  }

  const ratePercent = getFormString(formData, "expense_rate[rate_percent]").trim();
  if (!ratePercent) {
    errors.rate_percent = msg.blank;
  } else if (Number(ratePercent) < 0 || Number(ratePercent) > 100) {
    errors.rate_percent = "must be between 0 and 100";
  }

  return Object.keys(errors).length > 0 ? errors : null;
}

export default function Form({ expenseRate, method, submitLabel, url }: ExpenseRateFormProps) {
  return (
    <ResourceForm
      action={url}
      cancelHref="/expense_rates"
      method={method}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <>
          <FormRow>
            <FormInput
              defaultValue={expenseRate.name}
              error={errors.name}
              label="Name"
              name="expense_rate[name]"
            />
            <FormInput
              defaultValue={expenseRate.rate_percent || ""}
              error={errors.rate_percent}
              label="OpEx rate (% of revenue)"
              min={0}
              name="expense_rate[rate_percent]"
              step="0.01"
              type="number"
            />
          </FormRow>
        </>
      )}
    </ResourceForm>
  );
}
