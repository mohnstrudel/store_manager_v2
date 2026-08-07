import { PlusCircleIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import { useCallback } from "react";
import Button from "@/components/Button";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useConfirmAction } from "@/utils/useConfirmAction";
import routes from "@/utils/routes";
import { ExpenseRateRecord } from "../types";

type TableProps = {
  expenseRates: ExpenseRateRecord[];
};

export default function Table({ expenseRates }: TableProps) {
  if (expenseRates.length === 0) {
    return (
      <div className="table_card">
        <h3>OpEx Rates</h3>
        <div className="table_empty">
          <p>
            OpEx rates are recurring operating costs — payroll, rent, fees — expressed as a
            percentage of revenue. They drive the estimated OpEx used in the comparison below.
          </p>
          <Link className="btn_blue" href={routes.expenseRates.new.path()} prefetch>
            <PlusCircleIcon height={20} width={20} />
            Add your first OpEx rate
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="table_card">
      <h3>OpEx Rates</h3>
      <table role="grid">
        <thead>
          <tr>
            <th>Name</th>
            <th className="text-right">Rate</th>
            <th className="text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {expenseRates.map((expenseRate) => (
            <ExpenseRateRow expenseRate={expenseRate} key={expenseRate.id} />
          ))}
        </tbody>
      </table>
    </div>
  );
}

function ExpenseRateRow({ expenseRate }: { expenseRate: ExpenseRateRecord }) {
  const deleteExpenseRate = useConfirmAction(
    "delete",
    routes.expenseRates.destroy.path({ id: expenseRate.id }),
    { message: `Delete ${expenseRate.name}?` },
  );
  const deleteRate = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      stopRowNavigation(event);
      deleteExpenseRate();
    },
    [deleteExpenseRate],
  );

  return (
    <tr
      className="hoverable"
      {...rowNavigationProps(routes.expenseRates.edit.path({ id: expenseRate.id }))}
    >
      <td>{expenseRate.name}</td>
      <td className="text-right font-mono">{expenseRate.rate_percent}%</td>
      <td className="table_actions">
        <div className="flex justify-end gap-2">
          <Button onClick={deleteRate} variant="danger">
            <i className="icn">✂︎</i>
            Delete
          </Button>
          <Link
            href={routes.expenseRates.edit.path({ id: expenseRate.id })}
            onClick={stopRowNavigation}
            prefetch
          >
            <i className="icn">✏</i>
            Edit
          </Link>
        </div>
      </td>
    </tr>
  );
}
