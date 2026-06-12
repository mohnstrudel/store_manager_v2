import { Link } from "@inertiajs/react";
import MoveToWarehouseForm from "@/components/MoveToWarehouseForm";
import PaymentProgressBar from "@/components/PaymentProgressBar";
import { useWarehouseMoveSelection } from "@/utils/useWarehouseMoveSelection";
import type {
  PurchaseItemRecord,
  PurchaseShowRecord,
  ShippingCompanyOption,
  WarehouseOption,
} from "../types";
import PurchaseItemRow from "./PurchaseItems/PurchaseItemRow";

type PurchaseItemsProps = {
  movePath: string;
  purchase: PurchaseShowRecord;
  purchaseItems: PurchaseItemRecord[];
  shippingCompanies: ShippingCompanyOption[];
  warehouses: WarehouseOption[];
};

export default function PurchaseItems({
  movePath,
  purchase,
  purchaseItems,
  shippingCompanies,
  warehouses,
}: PurchaseItemsProps) {
  const { clearSelectedIds, selectedIds, toggleSelectedIdFromDataAttribute } =
    useWarehouseMoveSelection();

  if (purchaseItems.length === 0) return null;

  const productSummary = (
    <>
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
    </>
  );

  return (
    <div className="flex flex-col gap-4">
      <div className="table_card">
        <div className="flex justify-between align-center flex-wrap">
          <h3>
            {purchase.product_path ? (
              <Link
                className="inline-flex items-center gap-3 font-semibold"
                href={purchase.product_path}
                prefetch
              >
                {productSummary}
              </Link>
            ) : (
              <span className="inline-flex items-center gap-3 font-semibold">{productSummary}</span>
            )}
          </h3>
          <div className="w-full max-w-45 px-3 mt-4 text-center lg:w-45">
            <PaymentProgressBar progress={purchase.payment_progress} />
          </div>
        </div>

        <MoveToWarehouseForm
          movePath={movePath}
          onMoved={clearSelectedIds}
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
              <th>Purchased Item</th>
              <th className="text-center">Tracking</th>
              <th className="text-center">Shipping Co.</th>
              <th className="text-center">Cost</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {purchaseItems.map((purchaseItem) => (
              <PurchaseItemRow
                key={purchaseItem.id}
                purchaseItem={purchaseItem}
                selectedIds={selectedIds}
                shippingCompanies={shippingCompanies}
                toggleSelectedIdFromDataAttribute={toggleSelectedIdFromDataAttribute}
              />
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
