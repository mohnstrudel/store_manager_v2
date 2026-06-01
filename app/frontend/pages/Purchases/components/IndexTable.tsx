import { useCallback, type ChangeEvent } from "react";
import { Link } from "@inertiajs/react";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import PaymentProgressBar from "./PaymentProgressBar";
import type { PurchaseIndexRecord } from "../types";

type IndexTableProps = {
  onTogglePurchase: (purchaseId: number) => void;
  purchases: PurchaseIndexRecord[];
  selectedIds: number[];
};

export default function IndexTable({ onTogglePurchase, purchases, selectedIds }: IndexTableProps) {
  const handleTogglePurchase = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      const purchaseId = Number(event.currentTarget.dataset.purchaseId);
      if (Number.isNaN(purchaseId)) return;
      onTogglePurchase(purchaseId);
    },
    [onTogglePurchase],
  );

  return (
    <table role="grid">
      <thead>
        <tr>
          <th />
          <th className="text-center">Image</th>
          <th>Product</th>
          <th>Order Reference</th>
          <th>Supplier</th>
          <th>
            Payment Progress
            <div className="flex justify-between text-xs font-medium opacity-80">
              <span className="text-lime-700/90 dark:text-lime-500/85">paid</span>
              <span className="text-slate-400">item</span>
              <span className="text-orange-800/70 dark:text-orange-400/80">debt</span>
            </div>
          </th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {purchases.map((purchase) => (
          <tr className="hoverable" key={purchase.id} {...rowNavigationProps(purchase.path)}>
            <td className="no_events text-center">
              <input
                checked={selectedIds.includes(purchase.id)}
                data-purchase-id={purchase.id}
                onChange={handleTogglePurchase}
                onClick={stopRowNavigation}
                type="checkbox"
              />
            </td>
            <td className="text-center">
              <ZoomableThumbnail
                alt={purchase.product_title}
                key={`${purchase.id}-${purchase.product_thumb_url ?? "missing"}`}
                src={purchase.product_thumb_url}
              />
            </td>
            <td>
              {purchase.product_title}
              {purchase.variant_title && <> → {purchase.variant_title}</>}
              <ul className="ml-4 mt-2 text-sm">
                {purchase.purchase_items_count !== purchase.amount && (
                  <li>
                    <mark className="inline-block mb-2">
                      Warehouses: {purchase.purchase_items_count} / Purchased: {purchase.amount}
                    </mark>
                  </li>
                )}
                {purchase.warehouse_counts.map((warehouse) => (
                  <li key={warehouse.warehouse_name}>
                    {warehouse.warehouse_name} ← {warehouse.count}
                  </li>
                ))}
              </ul>
            </td>
            <td className="font-mono text-sm">{purchase.order_reference}</td>
            <td className="break-words">{purchase.supplier_title}</td>
            <td className="w-full max-w-45 lg:w-45">
              <PaymentProgressBar progress={purchase.payment_progress} />
            </td>
            <td className="table_actions">
              <Link
                className="no_events"
                href={purchase.edit_path}
                onClick={stopRowNavigation}
                prefetch
              >
                <i className="icn">✏</i>
                Edit
              </Link>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
