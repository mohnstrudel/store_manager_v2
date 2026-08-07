import PageHeader from "@/components/PageHeader";
import Form from "./components/Form";
import { ExpenseRateRecord } from "./types";

type EditProps = {
  expenseRate: ExpenseRateRecord;
};

export default function Edit({ expenseRate }: EditProps) {
  return (
    <>
      <PageHeader className="mb-8" title="Edit OpEx Rate" />

      <Form
        expenseRate={expenseRate}
        method="patch"
        submitLabel="Update OpEx Rate"
        url={`/expense_rates/${expenseRate.id}`}
      />
    </>
  );
}
