import { Link } from "@inertiajs/react";

import Field from "@/components/Field";
import {
  financialMetricHints,
  metricScopeNotes,
  withScope,
} from "@/components/profitability/metricLabels";

import type { PurchaseShowRecord } from "../types";

type DetailsProps = {
  purchase: PurchaseShowRecord;
};

export default function Details({ purchase }: DetailsProps) {
  return (
    <div className="cards">
      {purchase.product_image_url && (
        <img className="product" src={purchase.product_image_url} alt={purchase.product_title} />
      )}

      <dl className="card flex grow">
        <div className="flex-1">
          <Field label="ID" value={purchase.id} />
          <Field label="Qty" value={purchase.amount} />
          <Field className="font-mono" label="Unit price" value={purchase.item_price} />
          <Field className="font-mono" label="Total price" value={purchase.cost_total} />
          <Field className="font-mono" label="Shipping" value={purchase.shipping_total} />
          <Field
            anchor="directExpenses"
            className="font-mono"
            hint={withScope(financialMetricHints.directExpenses, metricScopeNotes.purchase)}
            label="Direct expenses"
            value={purchase.expenses_total}
          />
        </div>
        <div className="flex-1">
          <Field className="font-mono" label="Paid" value={purchase.paid} />
          <Field className="font-mono" label="Supplier debt" value={purchase.debt}>
            -{purchase.debt}
          </Field>
        </div>
      </dl>

      <dl className="card">
        <Field label="Supplier" value={purchase.supplier_title}>
          <Link className="link" href={purchase.supplier_path} prefetch>
            {purchase.supplier_title}
          </Link>
        </Field>
        <Field label="Order reference" value={purchase.order_reference} />
        <Field label="Date" value={purchase.date} />
      </dl>
    </div>
  );
}
