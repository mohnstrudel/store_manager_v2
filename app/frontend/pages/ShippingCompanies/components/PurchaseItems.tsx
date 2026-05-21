import { router } from "@inertiajs/react";
import type { KeyboardEvent } from "react";
import { PurchaseItemRecord } from "../types";

type PurchaseItemsProps = {
  purchaseItems: PurchaseItemRecord[];
};

export default function PurchaseItems({ purchaseItems }: PurchaseItemsProps) {
  if (purchaseItems.length === 0) return null;

  function visitPurchaseItem(purchaseItem: PurchaseItemRecord) {
    router.visit(purchaseItem.path);
  }

  function handleKeyDown(
    purchaseItem: PurchaseItemRecord,
    event: KeyboardEvent<HTMLTableRowElement>
  ) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitPurchaseItem(purchaseItem);
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="table-card">
        <h3>Purchase Items</h3>
        <table role="grid">
          <thead>
            <tr>
              <th>Product</th>
              <th>Tracking Number</th>
              <th>Purchase Date</th>
            </tr>
          </thead>
          <tbody>
            {purchaseItems.map((purchaseItem) => (
              <tr
                className="hoverable"
                key={purchaseItem.id}
                onClick={() => visitPurchaseItem(purchaseItem)}
                onKeyDown={(event) => handleKeyDown(purchaseItem, event)}
                tabIndex={0}
              >
                <td>{purchaseItem.product_full_title}</td>
                <td>{purchaseItem.tracking_number}</td>
                <td>{purchaseItem.purchased_ago}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
