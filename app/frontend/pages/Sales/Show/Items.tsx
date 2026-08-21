import { Link } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type MouseEvent } from "react";

import DetailsChevron from "@/components/DetailsChevron";
import MoveToWarehouseForm from "@/components/MoveToWarehouseForm";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";
import type { WarehouseOption } from "@/types/warehouse";
import { useConfirmAction } from "@/utils/useConfirmAction";
import { useWarehouseMoveSelection } from "@/utils/useWarehouseMoveSelection";

import type { SaleShowPurchaseItemRecord, SaleShowSaleItemRecord } from "../types";

type ItemsProps = {
  saleId: number;
  saleItems: SaleShowSaleItemRecord[];
  warehouseMovePath: string;
  warehouses: WarehouseOption[];
};

type SelectionProps = {
  selectedIds: number[];
  showPurchaseColumn: boolean;
  toggleSelectedIdFromDataAttribute: (
    attributeName: string,
  ) => (event: ChangeEvent<HTMLInputElement>) => void;
};

export default function Items({ saleId, saleItems, warehouseMovePath, warehouses }: ItemsProps) {
  const { clearSelectedIds, selectedIds, toggleSelectedIdFromDataAttribute } =
    useWarehouseMoveSelection();

  if (saleItems.length === 0) return null;

  const showPurchaseColumn = saleItems.some((si) => si.purchase_items.length > 0);

  return (
    <div className="table_card full_width">
      <MoveToWarehouseForm
        movePath={warehouseMovePath}
        onMoved={clearSelectedIds}
        saleId={saleId}
        selectedIds={selectedIds}
        warehouses={warehouses}
      />

      <table>
        <thead>
          <tr>
            {showPurchaseColumn && <th />}
            <th className="text-center w-[106px] lg:w-[114px]">Image</th>
            <th>Product</th>
            <th className="text-right">Price</th>
          </tr>
        </thead>
        <tbody>
          {saleItems.map((saleItem) => (
            <SaleItemRow
              key={saleItem.id}
              saleItem={saleItem}
              selectedIds={selectedIds}
              showPurchaseColumn={showPurchaseColumn}
              toggleSelectedIdFromDataAttribute={toggleSelectedIdFromDataAttribute}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}

function SaleItemRow({
  saleItem,
  selectedIds,
  showPurchaseColumn,
  toggleSelectedIdFromDataAttribute,
}: { saleItem: SaleShowSaleItemRecord } & SelectionProps) {
  const hasPurchaseItems = saleItem.purchase_items.length > 0;
  const missingPurchasesCount = Math.max(0, saleItem.qty - saleItem.purchase_items.length);

  return (
    <tr className="cursor-default">
      {showPurchaseColumn && (
        <td className="text-center align-center pt-4">
          {saleItem.purchase_items.map((purchaseItem) => (
            <div key={purchaseItem.id} className="mt-4 first:mt-0">
              <input
                checked={selectedIds.includes(purchaseItem.id)}
                data-purchase-item-id={purchaseItem.id}
                onChange={toggleSelectedIdFromDataAttribute("purchaseItemId")}
                type="checkbox"
              />
            </div>
          ))}
        </td>
      )}
      <td>
        <ZoomableThumbnail
          alt={saleItem.title}
          key={`${saleItem.id}-${saleItem.product_thumb_url ?? "missing"}`}
          src={saleItem.product_thumb_url}
        />
      </td>
      <td>
        <Link className="link no-underline font-semibold" href={saleItem.product_path} prefetch>
          {saleItem.title}
        </Link>
        {hasPurchaseItems && (
          <menu>
            {saleItem.purchase_items.map((purchaseItem) => (
              <PurchaseItemRow key={purchaseItem.id} purchaseItem={purchaseItem} />
            ))}
          </menu>
        )}
        {missingPurchasesCount > 0 && (
          <mark className="block uppercase tracking-wide text-xs w-fit mt-2 -ml-1">
            <span className="font-semibold">
              MISSING {missingPurchasesCount} PURCHASE{missingPurchasesCount === 1 ? "" : "S"}
            </span>
          </mark>
        )}
      </td>
      <td className="text-right">{saleItem.payment.price}</td>
    </tr>
  );
}

function PurchaseItemRow({ purchaseItem }: { purchaseItem: SaleShowPurchaseItemRecord }) {
  const hasMovementHistory = purchaseItem.warehouse_movements.length > 1;
  const previousMovements = purchaseItem.warehouse_movements.slice(1);
  const summaryCursor = hasMovementHistory ? "cursor-pointer" : "cursor-default";

  const unlinkPurchaseItem = useConfirmAction("delete", purchaseItem.unlink_path, {
    message: "Unlink this purchase item?",
  });
  const handleUnlinkClick = useCallback(
    (event: MouseEvent) => {
      event.stopPropagation();
      unlinkPurchaseItem();
    },
    [unlinkPurchaseItem],
  );

  return (
    <li className="mt-4">
      <div className="w-fit flex items-center gap-2">
        <div>
          <span className="text-gray-500">
            <i className="icn">💰</i>&nbsp;Purchase:
          </span>
          <Link className="link ml-2" href={purchaseItem.path} prefetch>
            {purchaseItem.supplier_title}, {purchaseItem.purchase_date}
            {purchaseItem.item_price && (
              <>
                {", "}
                {purchaseItem.item_price}
              </>
            )}
          </Link>
        </div>

        <button className="btn_xs btn_red btn_rounded" onClick={handleUnlinkClick} type="button">
          <i className="icn">✂︎</i>
          Unlink
        </button>
      </div>

      {purchaseItem.warehouse_movements.length > 0 && (
        <details className="my-2 group">
          <summary className={`w-fit flex items-center gap-2 ${summaryCursor}`}>
            <span>
              <span className="text-gray-500">
                <i className="icn">📦</i>&nbsp;Status:
              </span>
              <Link className="link ml-2" href={purchaseItem.current_warehouse_path} prefetch>
                {purchaseItem.current_warehouse_name}
              </Link>
            </span>

            {hasMovementHistory && <DetailsChevron />}
          </summary>

          {hasMovementHistory && (
            <div className="border max-w-2/3 border-gray-200/80 dark:border-gray-600/40 rounded-sm my-3">
              <table className="text-sm my-0">
                <thead>
                  <tr className="cursor-auto">
                    <th>Moved in</th>
                    <th>Warehouse</th>
                  </tr>
                </thead>
                <tbody>
                  {previousMovements.map((movement) => (
                    <tr className="cursor-auto" key={`${purchaseItem.id}-${movement.moved_in}`}>
                      <td className="pr-2 text_muted whitespace-nowrap">{movement.moved_in}</td>
                      <td>{movement.warehouse_name}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </details>
      )}
    </li>
  );
}
