import { router } from "@inertiajs/react";
import type { KeyboardEvent } from "react";
import { PurchaseRecord } from "../types";

type PurchasesProps = {
  purchases: PurchaseRecord[];
};

export default function Purchases({ purchases }: PurchasesProps) {
  if (purchases.length === 0) return null;

  const columns = ["Title", "Variant", "Purchased ago", "Item Price, $", "Qty", "Debt"];

  function visitPurchase(purchase: PurchaseRecord) {
    router.visit(purchase.path);
  }

  function handleKeyDown(purchase: PurchaseRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitPurchase(purchase);
  }

  return (
    <div className="flex flex-col gap-4">
      <div className="table-card">
        <h3>Purchases</h3>
        <table role="grid">
          <thead>
            <tr>
              {columns.map((column) => (
                <th key={column}>{column}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {purchases.map((purchase) => (
              <tr
                className={purchase.has_debt ? "has-debt" : "paid"}
                key={purchase.id}
                onClick={() => visitPurchase(purchase)}
                onKeyDown={(event) => handleKeyDown(purchase, event)}
                tabIndex={0}
              >
                <td>{purchase.title}</td>
                <td>{purchase.variant}</td>
                <td>{purchase.purchased_ago}</td>
                <td className="text-right">{purchase.item_price}</td>
                <td>{purchase.amount}</td>
                <td>{purchase.debt}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
