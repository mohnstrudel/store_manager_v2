import { Link } from "@inertiajs/react";
import Button from "@/components/Button";
import Field from "@/components/Field";
import ImageGallery from "@/components/ImageGallery";
import {
  financialMetricHints,
  metricScopeNotes,
  withScope,
} from "@/components/profitability/metricLabels";
import { useConfirmAction } from "@/utils/useConfirmAction";
import type { PurchaseItemShowRecord } from "./types";

type ShowProps = {
  purchase_item: PurchaseItemShowRecord;
};

export default function Show({ purchase_item }: ShowProps) {
  const destroyPurchaseItem = useConfirmAction("delete", purchase_item.destroy_path);

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <h1>
            <i className="icn mr-2">📦</i>
            Purchase Item {purchase_item.id}
          </h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={purchase_item.purchase_path} prefetch>
              <i className="icn">💰</i>
              Purchase
            </Link>
          </li>
          {purchase_item.sale_path && (
            <li>
              <Link href={purchase_item.sale_path} prefetch>
                <i className="icn">🛒</i>
                Sale
              </Link>
            </li>
          )}
          {purchase_item.sale_item_path && (
            <li>
              <Link href={purchase_item.sale_item_path} prefetch>
                Sale Item
              </Link>
            </li>
          )}
          <li>
            <Link href={purchase_item.edit_path} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section_wide">
        <div className="cards">
          <ImageGallery media={purchase_item.media} />
          <dl className="card grow">
            <Field label="Supplier" value={purchase_item.supplier_title}>
              <Link className="link" href={purchase_item.supplier_path} prefetch>
                {purchase_item.supplier_title}
              </Link>
            </Field>
            <Field label="Product" value={purchase_item.product_title}>
              {purchase_item.product_path ? (
                <Link className="link" href={purchase_item.product_path} prefetch>
                  {purchase_item.product_title}
                </Link>
              ) : (
                purchase_item.product_title
              )}
            </Field>
            <Field label="Current Warehouse" value={purchase_item.warehouse_name}>
              <Link className="link" href={purchase_item.warehouse_path} prefetch>
                {purchase_item.warehouse_name}
              </Link>
            </Field>
            <Field
              anchor="directExpenses"
              className="font-mono"
              hint={withScope(financialMetricHints.directExpenses, metricScopeNotes.purchaseItem)}
              label="Direct expenses"
              value={purchase_item.expenses}
            />
            <Field className="font-mono" label="Shipping" value={purchase_item.shipping_cost} />
            <Field label="Tracking Number" value={purchase_item.tracking_number} />
            <Field label="Shipping Company" value={purchase_item.shipping_company_name} />
          </dl>
          <dl className="card">
            <Field label="Length, cm" value={purchase_item.length} />
            <Field label="Width, cm" value={purchase_item.width} />
            <Field label="Height, cm" value={purchase_item.height} />
            <Field label="Weight, kg" value={purchase_item.weight} />
            <Field label="Created at" value={purchase_item.created_at} />
            <Field label="Updated at" value={purchase_item.updated_at} />
          </dl>
          {purchase_item.warehouse_movements.length > 0 && (
            <div className="card">
              <table className="vertical thead_static" role="grid">
                <thead>
                  <tr>
                    <th>Moved in</th>
                    <th>Warehouse</th>
                  </tr>
                </thead>
                <tbody>
                  {purchase_item.warehouse_movements.map((movement) => (
                    <tr key={movement.id}>
                      <td>{movement.moved_in}</td>
                      <td>
                        {movement.warehouse_path ? (
                          <Link className="link" href={movement.warehouse_path} prefetch>
                            {movement.warehouse_name}
                          </Link>
                        ) : null}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyPurchaseItem} variant="danger">
        Destroy this purchase item
      </Button>
    </>
  );
}
