import ResourceIndexPage from "@/components/ResourceIndexPage";
import Table from "./components/Table";
import type { OperationalExpenseRecord } from "./types";
export default function Index({
  operationalExpenses,
}: {
  operationalExpenses: OperationalExpenseRecord[];
}) {
  return (
    <ResourceIndexPage bordered={false} newPath="/operational_expenses/new" title="OpEx">
      <Table expenses={operationalExpenses} />
    </ResourceIndexPage>
  );
}
