import { router, Link } from "@inertiajs/react";
import { type MouseEvent, useState } from "react";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import { rowNavigationProps } from "@/lib/rowNavigation";
import MoveToWarehouseForm from "./MoveToWarehouseForm";
import PaymentProgressBar from "./PaymentProgressBar";
import type { PurchaseItemRecord, PurchaseShowRecord, WarehouseOption } from "../types";

type PurchaseItemsProps = {
  movePath: string;
  purchase: PurchaseShowRecord;
  purchaseItems: PurchaseItemRecord[];
  warehouses: WarehouseOption[];
};

export default function PurchaseItems({
  movePath,
  purchase,
  purchaseItems,
  warehouses,
}: PurchaseItemsProps) {
  const [selectedIds, setSelectedIds] = useState<number[]>([]);

  if (purchaseItems.length === 0) return null;

  function togglePurchaseItem(purchaseItemId: number) {
    setSelectedIds((current) =>
      current.includes(purchaseItemId)
        ? current.filter((selectedId) => selectedId !== purchaseItemId)
        : [...current, purchaseItemId],
    );
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  function unlinkPurchaseItem(purchaseItem: PurchaseItemRecord, event: MouseEvent) {
    event.stopPropagation();
    if (window.confirm("Are you sure?")) {
      router.delete(purchaseItem.unlink_path);
    }
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="table-card">
        <div className="flex justify-between align-center flex-wrap">
          <h3>
            <Link
              className="inline-flex items-center gap-3 font-semibold"
              href={purchase.product_path}
              prefetch
            >
              {purchase.product_thumb_url && (
                <img
                  alt={purchase.product_title}
                  className="rounded h-7 w-7 shrink-0 object-cover transition-transform duration-150 ease-out hover:scale-[7] hover:z-990 hover:shadow"
                  src={purchase.product_thumb_url}
                />
              )}
              <span>
                {purchase.product_title}
                {purchase.variant_title && <span> → {purchase.variant_title}</span>}
              </span>
            </Link>
          </h3>
          <div className="w-full max-w-45 px-3 mt-4 text-center lg:w-45">
            <PaymentProgressBar progress={purchase.payment_progress} />
          </div>
        </div>

        <MoveToWarehouseForm
          movePath={movePath}
          onMoved={() => setSelectedIds([])}
          purchaseId={purchase.id}
          redirectToSaleItem
          selectedIds={selectedIds}
          warehouses={warehouses}
        />

        <table>
          <thead>
            <tr>
              <th />
              <th>ID</th>
              <th>Warehouse</th>
              <th>Sale</th>
              <th>Customer</th>
              <th className="text-right">Shipping</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {purchaseItems.map((purchaseItem) => (
              <tr
                className="hoverable"
                key={purchaseItem.id}
                {...rowNavigationProps(purchaseItem.path)}
              >
                <td className="no-events text-center">
                  <input
                    checked={selectedIds.includes(purchaseItem.id)}
                    onChange={() => togglePurchaseItem(purchaseItem.id)}
                    onClick={stopRowNavigation}
                    type="checkbox"
                  />
                </td>
                <td>{purchaseItem.id}</td>
                <td>
                  <Link
                    className="link no-events"
                    href={purchaseItem.warehouse_path}
                    onClick={stopRowNavigation}
                    prefetch
                  >
                    {purchaseItem.warehouse_name}
                  </Link>
                </td>
                <td>
                  {purchaseItem.sale_path && (
                    <Link
                      className="link no-events"
                      href={purchaseItem.sale_path}
                      onClick={stopRowNavigation}
                      prefetch
                    >
                      {purchaseItem.sale_title}
                    </Link>
                  )}
                </td>
                <td>
                  {purchaseItem.sale_path && (
                    <div className="flex flex-col items-start gap-2 text-sm">
                      <CopyToClipboardButton
                        className="text-xs btn-xs"
                        label="Copy address"
                        text={purchaseItem.sale_address}
                      />
                      <CopyToClipboardButton
                        className="text-xs btn-xs"
                        label="Copy email"
                        text={purchaseItem.customer_email}
                      />
                    </div>
                  )}
                </td>
                <td className="font-mono text-right">{purchaseItem.shipping_cost}</td>
                <td className="actions">
                  <div className="flex justify-end">
                    {purchaseItem.sale_path && (
                      <button
                        className="no-events btn-red btn-rounded"
                        onClick={(event) => unlinkPurchaseItem(purchaseItem, event)}
                        type="button"
                      >
                        <i className="icn">✂︎</i>
                        Unlink
                      </button>
                    )}
                    <Link
                      className="no-events"
                      href={purchaseItem.edit_path}
                      onClick={stopRowNavigation}
                      prefetch
                    >
                      <i className="icn">✏</i>
                      Edit
                    </Link>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
