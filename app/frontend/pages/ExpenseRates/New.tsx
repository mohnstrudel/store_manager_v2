import PageHeader from "@/components/PageHeader";

import Form from "./components/Form";
import { ExpenseRateFormRecord } from "./types";

type NewProps = {
  expenseRate: ExpenseRateFormRecord;
};

export default function New({ expenseRate }: NewProps) {
  return (
    <>
      <PageHeader className="mb-8" title="New OpEx Rate" />

      <Form
        expenseRate={expenseRate}
        method="post"
        submitLabel="Create OpEx Rate"
        url="/expense_rates"
      />
    </>
  );
}
