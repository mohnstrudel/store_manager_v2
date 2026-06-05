import { useCallback, useRef, useState, type MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { ChevronLeftIcon } from "@heroicons/react/20/solid";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import { useWarehouseMoveSelection } from "@/lib/useWarehouseMoveSelection";
import MoveToWarehouseForm from "../components/MoveToWarehouseForm";
import PaymentProgressBar from "../components/PaymentProgressBar";
import { InlineShippingCompanyEditor } from "../components/InlineShippingCompanyEditor";
import { InlineTrackingNumberEditor } from "../components/InlineTrackingNumberEditor";
import type {
  PurchaseItemRecord,
  PurchaseShowRecord,
  ShippingCompanyOption,
  WarehouseOption,
} from "../types";
import { InlineShippingCostEditor } from "./InlineShippingCostEditor";

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

type ToggleSelectedIdFromDataAttribute = ReturnType<
  typeof useWarehouseMoveSelection
>["toggleSelectedIdFromDataAttribute"];

type PurchaseItemRowProps = {
  purchaseItem: PurchaseItemRecord;
  selectedIds: number[];
  shippingCompanies: ShippingCompanyOption[];
  toggleSelectedIdFromDataAttribute: ToggleSelectedIdFromDataAttribute;
};

function PurchaseItemRow({
  purchaseItem,
  selectedIds,
  shippingCompanies,
  toggleSelectedIdFromDataAttribute,
}: PurchaseItemRowProps) {
  const {
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

  const unlinkPurchaseItem = useConfirmedDestroy(
    purchaseItem.unlink_path,
    "Unlink this purchase item?",
  );
  const handleUnlinkClick = useCallback(
    (event: MouseEvent) => {
      event.stopPropagation();
      unlinkPurchaseItem();
    },
    [unlinkPurchaseItem],
  );

  return (
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
              {hasMovementHistory && (
                <span className="text-xs btn_rounded w-5 h-5 p-0 btn_lightblue flex items-center justify-center transition-transform origin-center group-open:-rotate-90">
                  <ChevronLeftIcon className="h-4 w-4" />
                </span>
              )}
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
        onAutoOpen={trackingAutoOpen}
      />
      <InlineShippingCompanyEditor
        ref={shippingRef}
        item={purchaseItem}
        autoFocus={focusTarget === "shipping_company"}
        onAutoOpen={shippingAutoOpen}
        shippingCompanies={shippingCompanies}
      />
      <InlineShippingCostEditor
        ref={shippingCostRef}
        item={purchaseItem}
        autoFocus={focusTarget === "shipping_cost"}
        onAutoOpen={costAutoOpen}
      />
      <td className="table_actions">
        <div className="flex justify-end">
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
  );
}

function useInlineEditorCascade(purchaseItem: PurchaseItemRecord) {
  const trackingRef = useRef<{ open(): void }>(null);
  const shippingRef = useRef<{ open(): void }>(null);
  const shippingCostRef = useRef<{ open(): void }>(null);
  const [focusTarget, setFocusTarget] = useState<
    "tracking" | "shipping_company" | "shipping_cost" | null
  >(null);
  const openTracking = useCallback(() => {
    trackingRef.current?.open();
  }, []);
  const openShipping = useCallback(() => {
    shippingRef.current?.open();
  }, []);
  const openShippingCost = useCallback(() => {
    shippingCostRef.current?.open();
  }, []);

  // When all three fields are blank, clicking any one opens all three.
  const isBlankRow =
    !purchaseItem.tracking_number &&
    !purchaseItem.shipping_company_id &&
    parseFloat(purchaseItem.shipping_cost) === 0;

  // Tracking: open shipping when no company; also open cost when the whole row is blank.
  const trackingAutoOpen = useCallback(() => {
    setFocusTarget("tracking");
    if (purchaseItem.shipping_company_id) return;
    openShipping();
    if (isBlankRow) openShippingCost();
  }, [isBlankRow, openShipping, openShippingCost, purchaseItem.shipping_company_id]);

  // Shipping: open tracking + cost when blank row.
  const shippingAutoOpen = useCallback(() => {
    if (!isBlankRow) {
      setFocusTarget("shipping_company");
      return;
    }
    setFocusTarget("tracking");
    openTracking();
    openShippingCost();
  }, [isBlankRow, openShippingCost, openTracking]);

  // Cost: open tracking + shipping when blank row.
  const costAutoOpen = useCallback(() => {
    if (!isBlankRow) {
      setFocusTarget("shipping_cost");
      return;
    }
    setFocusTarget("tracking");
    openTracking();
    openShipping();
  }, [isBlankRow, openShipping, openTracking]);

  return {
    costAutoOpen,
    isBlankRow,
    focusTarget,
    shippingAutoOpen,
    shippingCostRef,
    shippingRef,
    trackingAutoOpen,
    trackingRef,
  };
}
