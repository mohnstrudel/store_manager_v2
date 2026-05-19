import CrudTable from "@/components/CrudTable";
import { PurchaseRecord } from "../types";

type PurchasesProps = {
  purchases: PurchaseRecord[];
};

export default function Purchases({ purchases }: PurchasesProps) {
  if (purchases.length === 0) return null;

  const columns = [
    { header: "Title", render: (purchase: PurchaseRecord) => purchase.title },
    { header: "Variant", render: (purchase: PurchaseRecord) => purchase.variant },
    { header: "Purchased ago", render: (purchase: PurchaseRecord) => purchase.purchased_ago },
    { header: "Item Price, $", render: (purchase: PurchaseRecord) => purchase.item_price, className: "text-right" },
    { header: "Qty", render: (purchase: PurchaseRecord) => purchase.amount },
    { header: "Debt", render: (purchase: PurchaseRecord) => purchase.debt },
  ];

  return (
    <div className="flex flex-col gap-4">
      <div className="table-card">
        <h3>Purchases</h3>
        <CrudTable
          columns={columns}
          rowClassName={(purchase) => (purchase.has_debt ? "has-debt" : "paid")}
          rowHref={(purchase) => purchase.path}
          rowKey={(purchase) => purchase.id}
          rows={purchases}
        />
      </div>
    </div>
  );
}
