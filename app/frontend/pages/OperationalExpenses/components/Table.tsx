import { PlusCircleIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import { useCallback } from "react";
import Amount from "@/components/Amount";
import Button from "@/components/Button";
import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useConfirmAction } from "@/utils/useConfirmAction";
import type { OperationalExpenseRecord } from "../types";

export default function Table({ expenses }: { expenses: OperationalExpenseRecord[] }) {
  if (expenses.length === 0) {
    return (
      <div className="table_card">
        <h3>Actual OpEx</h3>
        <div className="table_empty">
          <p>
            Actual OpEx is what you actually spent on operating costs — payroll, rent, fees — logged
            entry by entry. Each one feeds the actual side of the estimated vs. actual comparison.
          </p>
          <Link className="btn_blue" href={routes.operationalExpenses.new.path()} prefetch>
            <PlusCircleIcon height={20} width={20} />
            Add your first OpEx entry
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="table_card">
      <h3>Actual OpEx</h3>
      <table>
        <thead>
          <tr>
            <th>Date</th>
            <th>Category</th>
            <th className="text-right">Amount</th>
            <th>Note</th>
            <th className="text-right">Actions</th>
          </tr>
        </thead>
        <tbody>
          {expenses.map((expense) => (
            <ExpenseRow expense={expense} key={expense.id} />
          ))}
        </tbody>
      </table>
    </div>
  );
}
function ExpenseRow({ expense }: { expense: OperationalExpenseRecord }) {
  const destroy = useConfirmAction(
    "delete",
    routes.operationalExpenses.destroy.path({ id: expense.id! }),
    { message: `Delete ${expense.category}?` },
  );
  const deleteExpense = useCallback(
    (event: React.MouseEvent<HTMLButtonElement>) => {
      stopRowNavigation(event);
      destroy();
    },
    [destroy],
  );
  return (
    <tr
      className="hoverable"
      {...rowNavigationProps(routes.operationalExpenses.edit.path({ id: expense.id! }))}
    >
      <td>{expense.incurred_on}</td>
      <td>{expense.category}</td>
      <td className="text-right">
        <Amount value={expense.amount} />
      </td>
      <td>{expense.note}</td>
      <td className="table_actions">
        <div className="flex justify-end gap-2">
          <Button onClick={deleteExpense} variant="danger">
            <i className="icn">✂︎</i>
            Delete
          </Button>
          <Link
            href={routes.operationalExpenses.edit.path({ id: expense.id! })}
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
