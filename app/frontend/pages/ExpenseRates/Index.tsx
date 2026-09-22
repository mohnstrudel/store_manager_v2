import ResourceIndexPage from "@/components/ResourceIndexPage";

import Table from "./components/Table";
import { ExpenseRateRecord } from "./types";

type IndexProps = {
  expenseRates: ExpenseRateRecord[];
};

export default function Index({ expenseRates }: IndexProps) {
  return (
    <ResourceIndexPage bordered={false} newPath="/expense_rates/new" title="OpEx Rates">
      <Table expenseRates={expenseRates} />
    </ResourceIndexPage>
  );
}
