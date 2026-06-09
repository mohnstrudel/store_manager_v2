import { useCallback, type MouseEvent } from "react";
import { useConfirmAction } from "@/utils/useConfirmAction";
import type { SaleItemTableRow } from "../types";

type SaleItemsTableProps = {
  rows: SaleItemTableRow[];
};

export default function SaleItemsTable({ rows }: SaleItemsTableProps) {
  if (rows.length === 0) return null;

  return (
    <section className="table_card mb-8">
      <h3 className="label">Related Sale Items</h3>
      <table>
        <thead>
          <tr>
            <th>Item</th>
            <th>Linked To</th>
            <th className="text-right">Action</th>
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <SaleItemRow key={row.slot_key} row={row} />
          ))}
        </tbody>
      </table>
    </section>
  );
}

function SaleItemRow({ row }: { row: SaleItemTableRow }) {
  return (
    <tr>
      <ItemCell row={row} />
      <td>
        {row.is_current ? (
          <span className="opacity-50">Current</span>
        ) : row.linked_purchase_item ? (
          <a href={row.linked_purchase_item.path}>
            Purchase Item #{row.linked_purchase_item.id}
          </a>
        ) : (
          <span className="text-lime-600 dark:text-lime-500/85">Available</span>
        )}
      </td>
      <ActionCell row={row} />
    </tr>
  );
}

function ItemCell({ row }: { row: SaleItemTableRow }) {
  return (
    <td>
      <div className="flex flex-col gap-2 my-4">
        <span>
          <span className="text-gray-500">
            <i className="icn">🛒</i>&nbsp;Sale:
          </span>
          <a className="link ml-2" href={row.sale_path}>
            {row.sale_label}
          </a>
        </span>
        {row.warehouse && (
          <span>
            <span className="text-gray-500">
              <i className="icn">📦</i>&nbsp;Status:
            </span>
            {row.warehouse_path ? (
              <a className="link ml-2" href={row.warehouse_path}>{row.warehouse}</a>
            ) : (
              <span className="ml-2">{row.warehouse}</span>
            )}
          </span>
        )}
        {row.linked_purchase_item && (
          <span>
            <span className="text-gray-500">
              <i className="icn">💰</i>&nbsp;Purchase:
            </span>
            <a className="link ml-2" href={row.linked_purchase_item.purchase_path}>
              #{row.linked_purchase_item.purchase_id} {row.linked_purchase_item.supplier_title}, {row.linked_purchase_item.purchase_date}
              {row.linked_purchase_item.item_price && `, $${row.linked_purchase_item.item_price}`}
            </a>
          </span>
        )}
      </div>
    </td>
  );
}

function ActionCell({ row }: { row: SaleItemTableRow }) {
  const link = useConfirmAction("post", row.link_path, {
    data: { sale_item_id: row.sale_item_id },
  });
  const relink = useConfirmAction("post", row.link_path, {
    data: { sale_item_id: row.sale_item_id, purchase_item_to_unlink_id: row.linked_purchase_item?.id },
    message: `Unlink Purchase Item #${row.linked_purchase_item?.id} and link this one instead?`,
  });
  const unlink = useConfirmAction("delete", row.unlink_path, {
    message: "Unlink this sale item?",
  });

  const stop = useCallback((action: () => void) => (e: MouseEvent) => {
    e.stopPropagation();
    action();
  }, []);

  if (row.is_current) {
    return (
      <td className="text-right">
        <button className="btn_red btn_rounded" onClick={stop(unlink)} type="button">
          Unlink
        </button>
      </td>
    );
  }

  if (row.is_available) {
    return (
      <td className="text-right">
        <button className="btn_green btn_rounded" onClick={stop(link)} type="button">
          Link
        </button>
      </td>
    );
  }

  return (
    <td className="text-right">
      <button className="btn_red btn_rounded" onClick={stop(relink)} type="button">
        Relink
      </button>
    </td>
  );
}
