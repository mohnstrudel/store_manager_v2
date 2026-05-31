import { Link } from "@inertiajs/react";
import { type PurchaseRecord } from "../types";

type PurchasesSectionProps = {
  purchases: PurchaseRecord[];
};

export default function PurchasesSection({ purchases }: PurchasesSectionProps) {
  if (purchases.length === 0) return null;

  const total = purchases.reduce((sum, p) => sum + p.amount, 0);

  return (
    <div className="table_card">
      <h3 className="flex justify-between">
        <span>Purchases</span>
        <span>{total}</span>
      </h3>
      <table>
        <thead>
          <tr>
            <th>Supplier</th>
            <th>Ref</th>
            <th>Variant?</th>
            <th>Time ago</th>
            <th className="text-right">Item Price, $</th>
            <th>Amount</th>
            <th>Warehouse</th>
          </tr>
        </thead>
        <tbody>
          {purchases.map((purchase) => (
            <tr className="hoverable" key={purchase.id}>
              <td>
                <Link href={purchase.path} prefetch>
                  {purchase.supplier}
                </Link>
              </td>
              <td className="font-mono text-sm">{purchase.order_reference}</td>
              <td>{purchase.variant_title ?? ""}</td>
              <td>{purchase.created_at}</td>
              <td className="text-right font-mono">{purchase.item_price}</td>
              <td>{purchase.amount}</td>
              <td>{purchase.warehouses.map((w) => w.name).join(", ")}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
