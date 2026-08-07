import { useForm } from "@inertiajs/react";
import { PlusCircleIcon } from "@heroicons/react/20/solid";
import { useCallback, type ChangeEvent, type FormEvent } from "react";
import { useConfirmAction } from "@/utils/useConfirmAction";
import type { NewPaymentRecord, PaymentRecord, PurchaseShowRecord } from "../types";

type PaymentsProps = {
  newPayment: NewPaymentRecord;
  payments: PaymentRecord[];
  purchase: PurchaseShowRecord;
};

export default function Payments({ newPayment, payments, purchase }: PaymentsProps) {
  return (
    <div className="table_card">
      <h3>Payments</h3>
      <table className="thead_static">
        <thead>
          <tr>
            <th>Date</th>
            <th>Amount</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {payments.length > 0 ? (
            payments.map((payment) => (
              <PaymentRow key={payment.id} payment={payment} purchasePath={purchase.path} />
            ))
          ) : (
            <tr>
              <td colSpan={3}>
                <p className="py-4 text-sm text-gray-500">No payments yet.</p>
              </td>
            </tr>
          )}
          <NewPaymentRow newPayment={newPayment} purchasePath={purchase.path} />
        </tbody>
      </table>
    </div>
  );
}

function PaymentRow({ payment, purchasePath }: { payment: PaymentRecord; purchasePath: string }) {
  const form = useForm({
    payment_date: payment.payment_date,
    value: payment.value,
    return_to: purchasePath,
  });
  const destroyPayment = useConfirmAction("delete", payment.destroy_path, {
    message: "Remove this payment?",
  });

  const savePayment = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      form.transform((data) => ({
        payment: { payment_date: data.payment_date, value: data.value },
        return_to: data.return_to,
      }));
      form.patch(payment.update_path, { preserveScroll: true });
    },
    [form, payment.update_path],
  );

  const updateDate = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("payment_date");
      form.setData((data) => ({ ...data, payment_date: event.target.value }));
    },
    [form],
  );

  const updateValue = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("value");
      form.setData((data) => ({ ...data, value: event.target.value }));
    },
    [form],
  );

  return (
    <>
      <PaymentErrors errors={form.errors} />
      <tr data-payment-id={payment.id}>
        <td>
          <form className="hidden" id={`payment_${payment.id}_inline`} onSubmit={savePayment} />
          <label className="sr-only" htmlFor={`payment_${payment.id}_date`}>
            Date
          </label>
          <input
            form={`payment_${payment.id}_inline`}
            id={`payment_${payment.id}_date`}
            onChange={updateDate}
            suppressHydrationWarning
            type="date"
            value={form.data.payment_date}
          />
        </td>
        <td>
          <label className="sr-only" htmlFor={`payment_${payment.id}_amount`}>
            Amount
          </label>
          <input
            form={`payment_${payment.id}_inline`}
            id={`payment_${payment.id}_amount`}
            onChange={updateValue}
            placeholder="Amount"
            step="any"
            suppressHydrationWarning
            type="number"
            value={form.data.value}
          />
        </td>
        <td>
          <div className="flex flex-wrap gap-2">
            <button
              className="btn_rounded btn_lightamber"
              form={`payment_${payment.id}_inline`}
              type="submit"
            >
              Update
            </button>
            <button className="btn_rounded btn_red" onClick={destroyPayment} type="button">
              Remove
            </button>
          </div>
        </td>
      </tr>
    </>
  );
}

function NewPaymentRow({
  newPayment,
  purchasePath,
}: {
  newPayment: NewPaymentRecord;
  purchasePath: string;
}) {
  const form = useForm({
    payment_date: newPayment.payment_date,
    value: newPayment.value,
    return_to: purchasePath,
  });

  const createPayment = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      form.transform((data) => ({
        payment: { payment_date: data.payment_date, value: data.value },
        return_to: data.return_to,
      }));
      form.post(newPayment.create_path, {
        preserveScroll: true,
        onSuccess: () => {
          form.reset();
          form.clearErrors();
        },
      });
    },
    [form, newPayment.create_path],
  );

  const updateDate = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("payment_date");
      form.setData((data) => ({ ...data, payment_date: event.target.value }));
    },
    [form],
  );

  const updateValue = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("value");
      form.setData((data) => ({ ...data, value: event.target.value }));
    },
    [form],
  );

  return (
    <>
      <PaymentErrors errors={form.errors} />
      <tr>
        <td className="w-60">
          <form className="hidden" id="new_payment_inline" onSubmit={createPayment} />
          <label className="sr-only" htmlFor="payment_date">
            Date
          </label>
          <input
            form="new_payment_inline"
            id="payment_date"
            onChange={updateDate}
            suppressHydrationWarning
            type="date"
            value={form.data.payment_date}
          />
        </td>
        <td className="w-60">
          <label className="sr-only" htmlFor="payment_amount">
            Amount
          </label>
          <input
            form="new_payment_inline"
            id="payment_amount"
            onChange={updateValue}
            placeholder="What did you pay in total?"
            step="any"
            suppressHydrationWarning
            type="number"
            value={form.data.value}
          />
        </td>
        <td>
          <button className="btn_rounded btn_lightblue" form="new_payment_inline" type="submit">
            <PlusCircleIcon height={20} width={20} />
            Add payment
          </button>
        </td>
      </tr>
    </>
  );
}

function PaymentErrors({ errors }: { errors: Record<string, string> }) {
  const messages = Object.values(errors);
  if (messages.length === 0) return null;

  return (
    <tr>
      <td colSpan={3}>
        <div className="px-3 pt-3 text-sm text-red-600">
          {messages.map((message) => (
            <div key={message}>{message}</div>
          ))}
        </div>
      </td>
    </tr>
  );
}
