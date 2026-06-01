import { router } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type FormEvent, useState } from "react";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
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
            <th>Amount, $</th>
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
  const [paymentDate, setPaymentDate] = useState(payment.payment_date);
  const [value, setValue] = useState(payment.value);
  const destroyPayment = useConfirmedDestroy(payment.destroy_path, "Remove this payment?");

  const handleSubmit = useCallback((event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    router.patch(payment.update_path, {
      payment: { payment_date: paymentDate, value },
      return_to: purchasePath,
    });
  }, [payment.update_path, paymentDate, purchasePath, value]);

  const updateDate = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setPaymentDate(event.target.value);
  }, []);

  const updateValue = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setValue(event.target.value);
  }, []);

  return (
    <>
      {payment.errors.length > 0 && <PaymentErrors errors={payment.errors} />}
      <tr data-payment-id={payment.id}>
        <td>
          <form className="hidden" id={`payment_${payment.id}_inline`} onSubmit={handleSubmit} />
          <label className="sr-only" htmlFor={`payment_${payment.id}_date`}>
            Date
          </label>
          <input
            form={`payment_${payment.id}_inline`}
            id={`payment_${payment.id}_date`}
            onChange={updateDate}
            type="date"
            value={paymentDate}
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
            type="number"
            value={value}
          />
        </td>
        <td>
          <div className="flex flex-wrap gap-2">
            <button
              className="btn_rounded btn_lightblue"
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
  const [paymentDate, setPaymentDate] = useState(newPayment.payment_date);
  const [value, setValue] = useState(newPayment.value);

  const handleSubmit = useCallback((event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    router.post(newPayment.create_path, {
      payment: { payment_date: paymentDate, value },
      return_to: purchasePath,
    });
  }, [newPayment.create_path, paymentDate, purchasePath, value]);

  const updateDate = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setPaymentDate(event.target.value);
  }, []);

  const updateValue = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setValue(event.target.value);
  }, []);

  return (
    <>
      {newPayment.errors.length > 0 && <PaymentErrors errors={newPayment.errors} />}
      <tr>
        <td className="w-60">
          <form className="hidden" id="new_payment_inline" onSubmit={handleSubmit} />
          <label className="sr-only" htmlFor="payment_date">
            Date
          </label>
          <input
            form="new_payment_inline"
            id="payment_date"
            onChange={updateDate}
            type="date"
            value={paymentDate}
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
            type="number"
            value={value}
          />
        </td>
        <td>
          <button className="btn_rounded" form="new_payment_inline" type="submit">
            Add payment
          </button>
        </td>
      </tr>
    </>
  );
}

function PaymentErrors({ errors }: { errors: string[] }) {
  return (
    <tr>
      <td colSpan={3}>
        <div className="px-3 pt-3 text-sm text-red-600">
          {errors.map((message) => (
            <div key={message}>{message}</div>
          ))}
        </div>
      </td>
    </tr>
  );
}
