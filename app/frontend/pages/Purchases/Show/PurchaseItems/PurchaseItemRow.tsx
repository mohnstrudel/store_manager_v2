import { Link } from "@inertiajs/react";
import {
  type ChangeEvent,
  type MouseEvent,
  type SyntheticEvent,
  useCallback,
  useState,
} from "react";

import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import DetailsChevron from "@/components/DetailsChevron";
import { InlineShippingCompanyEditor } from "@/components/purchase-item-cells/InlineShippingCompanyEditor";
import { InlineTrackingNumberEditor } from "@/components/purchase-item-cells/InlineTrackingNumberEditor";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useConfirmAction } from "@/utils/useConfirmAction";

import type { PurchaseItemRecord, ShippingCompanyOption } from "../../types";
import { InlineShippingCostEditor } from "../InlineShippingCostEditor";
import PurchaseItemExpenses from "../PurchaseItemExpenses";
import { useInlineEditorCascade } from "./useInlineEditorCascade";

type ToggleSelectedIdFromDataAttribute = (
  attributeName: string,
) => (event: ChangeEvent<HTMLInputElement>) => void;

type PurchaseItemRowProps = {
  purchaseItem: PurchaseItemRecord;
  purchasePath: string;
  selectedIds: number[];
  shippingCompanies: ShippingCompanyOption[];
  toggleSelectedIdFromDataAttribute: ToggleSelectedIdFromDataAttribute;
};

const expenseTotalFormatter = new Intl.NumberFormat("en-US", {
  maximumFractionDigits: 2,
});

export default function PurchaseItemRow({
  purchaseItem,
  purchasePath,
  selectedIds,
  shippingCompanies,
  toggleSelectedIdFromDataAttribute,
}: PurchaseItemRowProps) {
  const {
    bulkErrors,
    bulkSave,
    focusTarget,
    trackingRef,
    shippingRef,
    shippingCostRef,
    trackingAutoOpen,
    shippingAutoOpen,
    costAutoOpen,
  } = useInlineEditorCascade(purchaseItem);

  const hasMovementHistory = purchaseItem.warehouse_movements.length > 0;
  const summaryCursor = hasMovementHistory ? "cursor-pointer" : "cursor-default";
  const expenseCount = purchaseItem.purchase_expenses.length;
  const expenseTotal = purchaseItem.purchase_expenses.reduce(
    (total, expense) => total + Number(expense.amount),
    0,
  );
  const expenseSummary =
    expenseCount === 0
      ? "Item direct expenses"
      : `Item direct expenses (${expenseCount} · ${expenseTotalFormatter.format(expenseTotal)} total)`;
  const [expensesOpen, setExpensesOpen] = useState(false);
  const handleExpensesToggle = useCallback((event: SyntheticEvent<HTMLDetailsElement>) => {
    setExpensesOpen(event.currentTarget.open);
  }, []);

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
    <>
      <tr
        className="hoverable"
        id={String(purchaseItem.id)}
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
        <td>{purchaseItem.id}</td>
        <td>
          <div className="flex flex-col gap-2 my-4">
            <details className="group" onClick={stopRowNavigation}>
              <summary className={`w-fit flex items-center gap-2 ${summaryCursor}`}>
                <span>
                  <span className="text-gray-500">
                    <i className="icn">📦</i>&nbsp;Status:
                  </span>
                  <Link
                    className="link no_events ml-2"
                    href={purchaseItem.warehouse_path}
                    onClick={stopRowNavigation}
                    prefetch
                  >
                    {purchaseItem.warehouse_name}
                  </Link>
                </span>
                {hasMovementHistory && <DetailsChevron />}
              </summary>
              {hasMovementHistory && (
                <div className="border max-w-9/10 border-gray-200/80 dark:border-gray-600/40 rounded-sm my-3">
                  <table className="text-sm my-0">
                    <thead>
                      <tr className="cursor-auto">
                        <th>Moved in</th>
                        <th>Warehouse</th>
                      </tr>
                    </thead>
                    <tbody>
                      {purchaseItem.warehouse_movements.map((movement) => (
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
            {purchaseItem.sale_path && (
              <span>
                <span className="text-gray-500">
                  <i className="icn">🛒</i>&nbsp;Sale:
                </span>
                <Link
                  className="link no_events ml-2"
                  href={purchaseItem.sale_path}
                  onClick={stopRowNavigation}
                  prefetch
                >
                  {purchaseItem.sale_title}
                </Link>
              </span>
            )}
            {purchaseItem.sale_path && (
              <span className="flex items-center gap-2">
                <span className="text-gray-500">
                  <i className="icn">🙂</i>&nbsp;Customer:
                </span>
                <CopyToClipboardButton
                  className="text-xs btn_xs"
                  label="Copy address"
                  text={purchaseItem.sale_address}
                />
                <CopyToClipboardButton
                  className="text-xs btn_xs"
                  label="Copy email"
                  text={purchaseItem.customer_email}
                />
              </span>
            )}
          </div>
        </td>
        <InlineTrackingNumberEditor
          ref={trackingRef}
          item={purchaseItem}
          autoFocus={focusTarget === "tracking"}
          bulkError={bulkErrors.tracking_number}
          onAutoOpen={trackingAutoOpen}
          onBulkSave={bulkSave}
        />
        <InlineShippingCompanyEditor
          ref={shippingRef}
          item={purchaseItem}
          autoFocus={focusTarget === "shipping_company"}
          bulkError={bulkErrors.shipping_company_id}
          onAutoOpen={shippingAutoOpen}
          shippingCompanies={shippingCompanies}
          onBulkSave={bulkSave}
        />
        <InlineShippingCostEditor
          ref={shippingCostRef}
          item={purchaseItem}
          autoFocus={focusTarget === "shipping_cost"}
          onAutoOpen={costAutoOpen}
          onBulkSave={bulkSave}
        />
        <td className="table_actions">
          <div className="flex justify-end gap-2">
            {purchaseItem.sale_path && (
              <button
                className="no_events btn_red btn_rounded"
                onClick={handleUnlinkClick}
                type="button"
              >
                <i className="icn">✂︎</i>
                Unlink
              </button>
            )}
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
      <tr className="bg-transparent">
        <td
          className={
            expensesOpen ? "from-gray-50 dark:from-gray-950/50 bg-linear-to-t" : "bg-transparent"
          }
          colSpan={7}
        >
          <details
            className="group"
            onClick={stopRowNavigation}
            onToggle={handleExpensesToggle}
            open={expensesOpen}
          >
            <summary className="w-fit flex items-center gap-2 cursor-pointer text-sm">
              {expenseSummary}
              <DetailsChevron />
            </summary>
            <PurchaseItemExpenses
              compact
              expenses={purchaseItem.purchase_expenses}
              newExpense={purchaseItem.new_purchase_expense}
              purchasePath={purchasePath}
            />
          </details>
        </td>
      </tr>
    </>
  );
}
