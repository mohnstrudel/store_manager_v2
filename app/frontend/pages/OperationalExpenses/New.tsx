import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import type { ExpenseRateOption, OperationalExpenseRecord } from "./types";
export default function New({
  operationalExpense,
  expenseRates,
}: {
  operationalExpense: OperationalExpenseRecord;
  expenseRates: ExpenseRateOption[];
}) {
  return (
    <>
      <PageHeader title="New OpEx Entry" />
      <Form
        expense={operationalExpense}
        expenseRates={expenseRates}
        method="post"
        submitLabel="Create OpEx Entry"
        url="/operational_expenses"
      />
    </>
  );
}
