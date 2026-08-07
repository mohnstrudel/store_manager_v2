import { useCallback, type MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useConfirmAction } from "@/utils/useConfirmAction";
import { useWarehouseMoveSelection } from "@/utils/useWarehouseMoveSelection";
import MoveToWarehouseForm from "@/components/MoveToWarehouseForm";
import MetricLabel from "@/components/profitability/MetricLabel";
import {
  financialMetricHints,
  metricScopeNotes,
  withScope,
} from "@/components/profitability/metricLabels";
import type { SaleItemPurchaseItemRecord, SaleItemShowRecord, WarehouseOption } from "./types";

type ShowProps = {
  purchase_items: SaleItemPurchaseItemRecord[];
  sale_item: SaleItemShowRecord;
  warehouse_move_path: string;
  warehouses: WarehouseOption[];
};

export default function Show({
  purchase_items,
  sale_item,
  warehouse_move_path,
  warehouses,
}: ShowProps) {
  const { clearSelectedIds, selectedIds, toggleSelectedIdFromDataAttribute } =
    useWarehouseMoveSelection();

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <hgroup>
            <h1>Sale Item</h1>
            <h2>{sale_item.title}</h2>
            <h4 className="text-gray-500 font-normal">
              Amount: {sale_item.qty}
              {sale_item.price && (
                <>
                  , price: <span className="font-mono inline">${sale_item.price}</span>
                </>
              )}
            </h4>
          </hgroup>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={sale_item.product_path} prefetch>
              <i className="icn">🧸</i>
              Product
            </Link>
          </li>
          <li>
            <Link href={sale_item.sale_path} prefetch>
              <i className="icn">🛒</i>
              Sale
            </Link>
          </li>
        </menu>
      </header>

      <div className="section_wide flex flex-col gap-8">
        {purchase_items.length > 0 && (
          <div className="table_card">
            <h3 className="flex justify-between px-3 pt-4">
              <span>Linked Purchased Items</span>
              <span>{purchase_items.length}</span>
            </h3>

            <MoveToWarehouseForm
              movePath={warehouse_move_path}
              onMoved={clearSelectedIds}
              redirectToSaleItem
              selectedIds={selectedIds}
              warehouses={warehouses}
            />

            <table>
              <thead>
                <tr>
                  <th />
                  <th>Warehouse</th>
                  <th>Length x Width x Height, cm</th>
                  <th className="text-right">Kg</th>
                  <th className="text-right">
                    <MetricLabel
                      anchor="directExpenses"
                      hint={withScope(
                        financialMetricHints.directExpenses,
                        metricScopeNotes.saleItem,
                      )}
                    >
                      Direct expenses
                    </MetricLabel>
                  </th>
                  <th className="text-right">Shipping</th>
                  <th className="text-right">Actions</th>
                </tr>
              </thead>
              <tbody>
                {purchase_items.map((purchaseItem) => (
                  <tr
                    className="hoverable"
                    key={purchaseItem.id}
                    {...rowNavigationProps(purchaseItem.path)}
                  >
                    <td className="no_events text-center">
                      <input
                        checked={selectedIds.includes(purchaseItem.id)}
                        data-purchase-item-id={purchaseItem.id}
                        onChange={toggleSelectedIdFromDataAttribute("purchaseItemId")}
                        onClick={stopRowNavigation}
                        type="checkbox"
                      />
                    </td>
                    <td>{purchaseItem.warehouse_name}</td>
                    <td className="font-mono">{purchaseItem.size}</td>
                    <td className="font-mono text-right">{purchaseItem.weight}</td>
                    <td className="font-mono text-right">{purchaseItem.expenses}</td>
                    <td className="font-mono text-right">{purchaseItem.shipping_cost}</td>
                    <td className="table_actions">
                      <div className="flex justify-end gap-2">
                        <PurchaseItemUnlinkButton purchaseItem={purchaseItem} />
                        <Link
                          className="no_events"
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
        )}
      </div>
    </>
  );
}

function PurchaseItemUnlinkButton({ purchaseItem }: { purchaseItem: SaleItemPurchaseItemRecord }) {
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
    <button className="no_events btn_red btn_rounded" onClick={handleUnlinkClick} type="button">
      <i className="icn">✂︎</i>
      Unlink
    </button>
  );
}
