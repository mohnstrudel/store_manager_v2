import { rowNavigationProps } from "@/utils/rowNavigation";
import { PurchaseItemRecord } from "../types";

type PurchaseItemsProps = {
  purchaseItems: PurchaseItemRecord[];
};

export default function PurchaseItems({ purchaseItems }: PurchaseItemsProps) {
  if (purchaseItems.length === 0) return null;

  return (
    <div className="flex flex-col gap-4">
      <div className="table_card">
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
                {...rowNavigationProps(purchaseItem.path)}
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
