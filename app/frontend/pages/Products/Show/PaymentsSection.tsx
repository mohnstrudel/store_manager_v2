import { Link } from "@inertiajs/react";

import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";

import { type PaymentItemRecord } from "../types";

type PaymentsSectionProps = {
  hasVariants: boolean;
  payments: PaymentItemRecord[];
  title: string;
};

export default function PaymentsSection({ hasVariants, payments, title }: PaymentsSectionProps) {
  if (payments.length === 0) return null;

  return (
    <div className="table_card">
      <h3 className="flex justify-between">
        <span>{title}</span>
        <span>{payments.length}</span>
      </h3>
      <table>
        <thead>
          <tr>
            <th>Shop ID</th>
            <th>
              Customer <span className="font-normal text-sm pl-4">+ Email</span>
            </th>
            <th>Date</th>
            {hasVariants && <th>Variant?</th>}
            <th className="text-right">Price</th>
            <th>Amount</th>
            <th>Payment</th>
            <th>
              Status <span className="font-normal text-sm pl-4">+ Warehouse</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {payments.map((item) => (
            <tr className="hoverable" key={item.id} {...rowNavigationProps(item.sale_path)}>
              <td>
                {item.store_type === "shopify" && (
                  <span className="inline-block icon_shopify w-5 h-5 mr-1" />
                )}
                {item.store_type === "woo" && (
                  <span className="inline-block icon_woo w-8 h-8 mr-2" />
                )}
                {item.store_id ?? ""}
              </td>
              <td>
                <strong>{item.customer_name}</strong>
                <br />
                {item.customer_email}
              </td>
              <td>{item.date}</td>
              {hasVariants && <td>{item.variant_title ?? ""}</td>}
              <td className="text-right font-mono">{item.price}</td>
              <td>{item.qty}</td>
              <td>
                <PaymentContext item={item} />
              </td>
              <td>
                {item.status.charAt(0).toUpperCase() + item.status.slice(1)}
                {item.purchase_item_path && (
                  <div className="mt-1">
                    <Link
                      className="no_events text-xs"
                      href={item.purchase_item_path}
                      onClick={stopRowNavigation}
                      prefetch
                    >
                      <i className="icn">📦</i>
                      {item.warehouse || "Purchase Item"}
                    </Link>
                  </div>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

function PaymentContext({ item }: { item: PaymentItemRecord }) {
  if (item.sequence !== null && item.expected_parts !== null) {
    return (
      <>
        Payment {item.sequence} of {item.expected_parts}
      </>
    );
  }

  if (item.origin !== null) {
    return (
      <>
        Follow-up payment ·{" "}
        <Link className="no_events" href={item.origin.path} onClick={stopRowNavigation} prefetch>
          {item.origin.identifier}
        </Link>
      </>
    );
  }

  return <>Follow-up payment</>;
}
