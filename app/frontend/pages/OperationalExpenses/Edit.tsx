import PageHeader from "@/components/PageHeader";

import Form from "./components/Form";
import type { ExpenseRateOption, OperationalExpenseRecord } from "./types";
export default function Edit({
  operationalExpense,
  expenseRates,
}: {
  operationalExpense: OperationalExpenseRecord;
  expenseRates: ExpenseRateOption[];
}) {
  return (
    <>
      <PageHeader title="Edit OpEx Entry" />
      <Form
        expense={operationalExpense}
        expenseRates={expenseRates}
        method="patch"
        submitLabel="Update OpEx Entry"
        url={`/operational_expenses/${operationalExpense.id}`}
      />
    </>
  );
}
