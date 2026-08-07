import ResourceIndexPage from "@/components/ResourceIndexPage";
import ComparisonSection from "./components/ComparisonSection";
import Table from "./components/Table";
import { ComparisonRow, ExpenseRateRecord } from "./types";

type IndexProps = {
  comparison: ComparisonRow[];
  expenseRates: ExpenseRateRecord[];
};

export default function Index({ comparison, expenseRates }: IndexProps) {
  return (
    <ResourceIndexPage bordered={false} newPath="/expense_rates/new" title="OpEx Rates">
      <div className="flex flex-col gap-8">
        <Table expenseRates={expenseRates} />
        <ComparisonSection comparison={comparison} />
      </div>
    </ResourceIndexPage>
  );
}
