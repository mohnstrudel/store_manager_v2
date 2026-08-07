import { useCallback, useState, type ChangeEvent } from "react";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import ResourceForm from "@/components/ResourceForm";
import type { ExpenseRateOption, OperationalExpenseRecord } from "../types";

type OperationalExpenseFormProps = {
  expense: OperationalExpenseRecord;
  expenseRates: ExpenseRateOption[];
  method: "post" | "patch";
  submitLabel: string;
  url: string;
};

export default function Form({
  expense,
  expenseRates,
  method,
  submitLabel,
  url,
}: OperationalExpenseFormProps) {
  const [category, setCategory] = useState(expense.category);
  const [expenseRateId, setExpenseRateId] = useState(expense.expense_rate_id?.toString() || "");

  const selectRate = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      const selectedId = event.target.value;
      setExpenseRateId(selectedId);
      const rate = expenseRates.find((candidate) => candidate.id === Number(selectedId));
      if (rate) setCategory(rate.name);
    },
    [expenseRates],
  );
  const changeCategory = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setCategory(event.target.value);
  }, []);

  return (
    <ResourceForm
      action={url}
      cancelHref="/operational_expenses"
      method={method}
      submitLabel={submitLabel}
    >
      {({ errors }) => (
        <>
          <FormRow>
            <FormControl
              error={errors.incurred_on}
              htmlFor="operational_expense_incurred_on"
              label="Date"
            >
              <input
                defaultValue={expense.incurred_on}
                id="operational_expense_incurred_on"
                name="operational_expense[incurred_on]"
                type="date"
              />
            </FormControl>
            <FormControl
              error={errors.category}
              htmlFor="operational_expense_category"
              label="Category"
            >
              <input
                id="operational_expense_category"
                name="operational_expense[category]"
                onChange={changeCategory}
                value={category}
              />
            </FormControl>
            <FormInput
              defaultValue={expense.amount}
              error={errors.amount}
              label="Amount"
              name="operational_expense[amount]"
              step="0.01"
              type="number"
            />
          </FormRow>
          <FormControl
            error={errors.expense_rate_id}
            htmlFor="operational_expense_expense_rate_id"
            label="OpEx rate (optional)"
          >
            <select
              id="operational_expense_expense_rate_id"
              name="operational_expense[expense_rate_id]"
              onChange={selectRate}
              value={expenseRateId}
            >
              <option value="">Unmatched</option>
              {expenseRates.map((rate) => (
                <option key={rate.id} value={rate.id}>
                  {rate.name}
                </option>
              ))}
            </select>
          </FormControl>
          <FormInput
            defaultValue={expense.note}
            error={errors.note}
            label="Note"
            name="operational_expense[note]"
          />
        </>
      )}
    </ResourceForm>
  );
}
