import { useForm } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type FormEvent } from "react";
import { useConfirmAction } from "@/utils/useConfirmAction";
import type { NewPurchaseItemExpenseRecord, PurchaseItemExpenseRecord } from "../types";
import { PlusCircleIcon } from "@heroicons/react/20/solid";

type PurchaseItemExpensesProps = {
  compact?: boolean;
  expenses: PurchaseItemExpenseRecord[];
  newExpense: NewPurchaseItemExpenseRecord;
  purchasePath: string;
};

export default function PurchaseItemExpenses({
  compact = false,
  expenses,
  newExpense,
  purchasePath,
}: PurchaseItemExpensesProps) {
  return (
    <div className={compact ? "mt-3 -mx-3" : "table_card"}>
      <table className="thead_static">
        <thead>
          <tr>
            <th>Description</th>
            <th>Amount</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {expenses.map((expense) => (
            <ExpenseRow expense={expense} key={expense.id} returnTo={purchasePath} />
          ))}
          <NewExpenseRow expense={newExpense} returnTo={purchasePath} />
        </tbody>
      </table>
    </div>
  );
}

function ExpenseRow({
  expense,
  returnTo,
}: {
  expense: PurchaseItemExpenseRecord;
  returnTo: string;
}) {
  const form = useForm({
    description: expense.description,
    amount: expense.amount,
    return_to: returnTo,
  });
  const removeExpense = useConfirmAction("delete", expense.destroy_path, {
    message: "Remove this expense?",
  });

  const saveExpense = useCallback(
    (event: FormEvent) => {
      event.preventDefault();
      form.transform((data) => ({
        purchase_expense: { description: data.description, amount: data.amount },
        return_to: data.return_to,
      }));
      form.patch(expense.update_path, { preserveScroll: true });
    },
    [expense.update_path, form],
  );

  const changeDescription = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("description");
      form.setData((data) => ({ ...data, description: event.target.value }));
    },
    [form],
  );

  const changeAmount = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("amount");
      form.setData((data) => ({ ...data, amount: event.target.value }));
    },
    [form],
  );

  return (
    <>
      <tr>
        <td>
          <form className="hidden" id={`expense_${expense.id}`} onSubmit={saveExpense} />
          <input
            aria-label="Description"
            form={`expense_${expense.id}`}
            onChange={changeDescription}
            value={form.data.description}
          />
        </td>
        <td>
          <input
            aria-label="Amount"
            form={`expense_${expense.id}`}
            onChange={changeAmount}
            step="any"
            type="number"
            value={form.data.amount}
          />
        </td>
        <td>
          <div className="flex flex-wrap gap-2">
            <button
              className="btn_rounded btn_lightamber"
              form={`expense_${expense.id}`}
              type="submit"
            >
              Update
            </button>
            <button className="btn_rounded btn_red" onClick={removeExpense} type="button">
              Remove
            </button>
          </div>
        </td>
      </tr>
      <ExpenseErrors errors={form.errors} />
    </>
  );
}

function NewExpenseRow({
  expense,
  returnTo,
}: {
  expense: NewPurchaseItemExpenseRecord;
  returnTo: string;
}) {
  const form = useForm({
    description: expense.description,
    amount: expense.amount,
    return_to: returnTo,
  });

  const saveNewExpense = useCallback(
    (event: FormEvent) => {
      event.preventDefault();
      form.transform((data) => ({
        purchase_expense: { description: data.description, amount: data.amount },
        return_to: data.return_to,
      }));
      form.post(expense.create_path, {
        preserveScroll: true,
        onSuccess: () => {
          form.reset();
          form.clearErrors();
        },
      });
    },
    [expense.create_path, form],
  );

  const changeDescription = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("description");
      form.setData((data) => ({ ...data, description: event.target.value }));
    },
    [form],
  );

  const changeAmount = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("amount");
      form.setData((data) => ({ ...data, amount: event.target.value }));
    },
    [form],
  );

  return (
    <>
      <tr>
        <td className="w-[30rem]">
          <form
            className="hidden"
            id={`new_expense_${expense.create_path}`}
            onSubmit={saveNewExpense}
          />
          <input
            aria-label="New expense description"
            form={`new_expense_${expense.create_path}`}
            onChange={changeDescription}
            value={form.data.description}
          />
        </td>
        <td className="w-60">
          <input
            aria-label="New expense amount"
            form={`new_expense_${expense.create_path}`}
            onChange={changeAmount}
            placeholder="Amount"
            step="any"
            type="number"
            value={form.data.amount}
          />
        </td>
        <td>
          <button
            className="btn_rounded btn_lightblue"
            form={`new_expense_${expense.create_path}`}
            type="submit"
          >
            <PlusCircleIcon height={20} width={20} />
            Add expense
          </button>
        </td>
      </tr>
      <ExpenseErrors errors={form.errors} />
    </>
  );
}

function ExpenseErrors({ errors }: { errors: Record<string, string> }) {
  return Object.values(errors).map((error) => <ErrorRow error={error} key={error} />);
}

function ErrorRow({ error }: { error: string }) {
  return (
    <tr>
      <td className="text-red-600 text-sm" colSpan={3}>
        {error}
      </td>
    </tr>
  );
}
