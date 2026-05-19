import CrudTable from "@/components/CrudTable";
import { PurchaseItemRecord } from "../types";

type PurchaseItemsProps = {
  purchaseItems: PurchaseItemRecord[];
};

export default function PurchaseItems({ purchaseItems }: PurchaseItemsProps) {
  if (purchaseItems.length === 0) return null;

  const columns = [
    { header: "Product", render: (purchaseItem: PurchaseItemRecord) => purchaseItem.product_full_title },
    { header: "Tracking Number", render: (purchaseItem: PurchaseItemRecord) => purchaseItem.tracking_number },
    { header: "Purchase Date", render: (purchaseItem: PurchaseItemRecord) => purchaseItem.purchased_ago },
  ];

  return (
    <div className="flex flex-col gap-4">
      <div className="table-card">
        <h3>Purchase Items</h3>
        <CrudTable
          columns={columns}
          rowHref={(purchaseItem) => purchaseItem.path}
          rowKey={(purchaseItem) => purchaseItem.id}
          rows={purchaseItems}
        />
      </div>
    </div>
  );
}
