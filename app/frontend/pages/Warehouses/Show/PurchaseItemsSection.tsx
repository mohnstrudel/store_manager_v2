import { Link } from "@inertiajs/react";
import { type ChangeEvent, useCallback, useEffect, useState } from "react";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import TipMark from "@/components/TipMark";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import { useWarehouseMoveSelection } from "@/lib/useWarehouseMoveSelection";
import MoveToWarehouseForm from "@/pages/Purchases/components/MoveToWarehouseForm";
import PaymentProgressBar from "@/pages/Purchases/components/PaymentProgressBar";
import type {
  PaginationMeta,
  ShippingCompanyOption,
  WarehouseOption,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "../types";
import { InlineShippingCompanyEditor } from "./InlineShippingCompanyEditor";
import { InlineTrackingNumberEditor } from "./InlineTrackingNumberEditor";

type PurchaseItemsSectionProps = {
  pagination: PaginationMeta;
  purchase_items: WarehousePurchaseItemRecord[];
  search: { q: string };
  selected_id: number | null;
  shipping_companies: ShippingCompanyOption[];
  total_purchase_items: number;
  warehouse: WarehouseShowRecord;
  warehouse_move_path: string;
  warehouses: WarehouseOption[];
};

export function PurchaseItemsSection({
  pagination,
  purchase_items,
  search,
  selected_id,
  shipping_companies,
  total_purchase_items,
  warehouse,
  warehouse_move_path,
  warehouses,
}: PurchaseItemsSectionProps) {
  const section = usePurchaseItemsSection();

  if (total_purchase_items <= 0) return null;

  const warehousePath = `/warehouses/${warehouse.id}`;

  return (
    <div className="flex flex-col gap-4">
      <div className="table_card">
        <PurchaseItemsSectionHeader pagination={pagination} warehouse={warehouse} />
        <PurchaseItemsSearch
          pagination={pagination}
          search={search}
          warehousePath={warehousePath}
        />

        {purchase_items.length > 0 ? (
          <>
            <MoveToWarehouseForm
              movePath={warehouse_move_path}
              onMoved={section.clearSelectedIds}
              selectedIds={section.selectedIds}
              warehouses={warehouses}
            />
            <PurchaseItemsTable
              purchaseItems={purchase_items}
              recentlySavedItemId={section.recentlySavedItemId}
              returnTo={warehousePath}
              selectedId={selected_id}
              selectedIds={section.selectedIds}
              shippingCompanies={shipping_companies}
              onPurchaseItemSaved={section.markPurchaseItemAsSaved}
              onToggleSelectedId={section.togglePurchaseItemSelection}
            />
            <div className="pagination_bottom">
              <Pagination pagination={pagination} path={warehousePath} query={search.q} />
            </div>
          </>
        ) : (
          <PurchaseItemsEmptyState search={search} />
        )}
      </div>
    </div>
  );
}

function PurchaseItemsSectionHeader({
  pagination,
  warehouse,
}: {
  pagination: PaginationMeta;
  warehouse: WarehouseShowRecord;
}) {
  return (
    <div className="flex justify-between align-center">
      <h3>Number of Items: {pagination.total_count}</h3>
      <div className="w-full max-w-45 px-3 mt-4 text-center lg:w-45">
        <PaymentProgressBar onlyDebt progress={warehouse.payment_progress} />
      </div>
    </div>
  );
}

function PurchaseItemsSearch({
  pagination,
  search,
  warehousePath,
}: {
  pagination: PaginationMeta;
  search: { q: string };
  warehousePath: string;
}) {
  return (
    <div className="page_search -mt-2">
      <SearchBar initialQuery={search.q} path={warehousePath} resourceName="purchase_items" />
      <div className="pagination_top">
        <Pagination pagination={pagination} path={warehousePath} query={search.q} />
      </div>
    </div>
  );
}

function PurchaseItemsEmptyState({ search }: { search: { q: string } }) {
  if (!search.q) return null;

  return <SearchResultsEmpty seed={search.q} />;
}

function PurchaseItemsTable({
  purchaseItems,
  recentlySavedItemId,
  returnTo,
  selectedId,
  selectedIds,
  shippingCompanies,
  onPurchaseItemSaved,
  onToggleSelectedId,
}: {
  purchaseItems: WarehousePurchaseItemRecord[];
  recentlySavedItemId: number | null;
  returnTo: string;
  selectedId: number | null;
  selectedIds: number[];
  shippingCompanies: ShippingCompanyOption[];
  onPurchaseItemSaved: (itemId: number) => void;
  onToggleSelectedId: (event: ChangeEvent<HTMLInputElement>) => void;
}) {
  return (
    <table>
      <thead>
        <tr>
          <th />
          <th>Title</th>
          <th>Customer</th>
          <th className="text-center">Tracking</th>
          <th className="text-center">Shipping</th>
          <th>
            Payment Progress
            <PaymentProgressLegend />
          </th>
        </tr>
      </thead>
      <tbody>
        {purchaseItems.map((item) => (
          <PurchaseItemRow
            item={item}
            key={item.id}
            returnTo={returnTo}
            shippingCompanies={shippingCompanies}
            isSaved={recentlySavedItemId === item.id}
            isSelected={selectedId === item.id}
            isSelectionChecked={selectedIds.includes(item.id)}
            onPurchaseItemSaved={onPurchaseItemSaved}
            onToggleSelectedId={onToggleSelectedId}
          />
        ))}
      </tbody>
    </table>
  );
}

function PaymentProgressLegend() {
  return (
    <div className="flex justify-between text-xs font-medium opacity-80">
      <span className="text-lime-700/90 dark:text-lime-500/85">paid</span>
      <span className="text-slate-400">item</span>
      <span className="text-orange-800/70 dark:text-orange-400/80">debt</span>
    </div>
  );
}

function PurchaseItemRow({
  item,
  isSaved,
  isSelected,
  isSelectionChecked,
  returnTo,
  shippingCompanies,
  onPurchaseItemSaved,
  onToggleSelectedId,
}: {
  item: WarehousePurchaseItemRecord;
  isSaved: boolean;
  isSelected: boolean;
  isSelectionChecked: boolean;
  returnTo: string;
  shippingCompanies: ShippingCompanyOption[];
  onPurchaseItemSaved: (itemId: number) => void;
  onToggleSelectedId: (event: ChangeEvent<HTMLInputElement>) => void;
}) {
  const [isTrackingOpen, setTrackingOpen] = useState(false);
  const [isShippingOpen, setShippingOpen] = useState(false);
  const closeTrackingEditor = useCallback(() => {
    setTrackingOpen(false);
  }, []);
  const openTrackingEditor = useCallback(() => {
    setTrackingOpen(true);
    if (!item.shipping_company_id) setShippingOpen(true);
  }, [item.shipping_company_id]);
  const closeShippingEditor = useCallback(() => {
    setShippingOpen(false);
  }, []);
  const openShippingEditor = useCallback(() => {
    setShippingOpen(true);
  }, []);

  return (
    <tr
      className={purchaseItemRowClassName({ isSaved, isSelected })}
      id={String(item.id)}
      {...rowNavigationProps(item.path)}
    >
      <td className="no_events text-center">
        <input
          checked={isSelectionChecked}
          data-purchase-item-id={item.id}
          onChange={onToggleSelectedId}
          onClick={stopRowNavigation}
          type="checkbox"
        />
      </td>
      <td className="max-w-md">
        <PurchaseItemTitle item={item} />
      </td>
      <td className="max-w-xs">
        <PurchaseItemCustomer item={item} />
      </td>
      <td className="max-w-3xs">
        <InlineTrackingNumberEditor
          item={item}
          isOpen={isTrackingOpen}
          onClose={closeTrackingEditor}
          onOpen={openTrackingEditor}
          onSaved={onPurchaseItemSaved}
          returnTo={returnTo}
        />
      </td>
      <td>
        <InlineShippingCompanyEditor
          item={item}
          isOpen={isShippingOpen}
          onClose={closeShippingEditor}
          onOpen={openShippingEditor}
          onSaved={onPurchaseItemSaved}
          returnTo={returnTo}
          shippingCompanies={shippingCompanies}
        />
      </td>
      <td className="w-full max-w-45 lg:w-45">
        <PaymentProgressBar progress={item.payment_progress} />
      </td>
    </tr>
  );
}

function PurchaseItemTitle({ item }: { item: WarehousePurchaseItemRecord }) {
  return (
    <>
      {item.title}
      {item.variant_title && <> → {item.variant_title}</>}
      <div className="cursor-text no_events font-mono text-sm text-gray-500 dark:text-gray-400">
        {item.sku}
      </div>
      {item.sale_path && (
        <Link
          className="no_events text-sm mt-3"
          href={item.sale_path}
          onClick={stopRowNavigation}
          title="Open sales page"
          prefetch
        >
          <SaleStoreIcon storeType={item.sale_store_type} />
          {item.sale_title}
        </Link>
      )}
    </>
  );
}

function SaleStoreIcon({
  storeType,
}: {
  storeType: WarehousePurchaseItemRecord["sale_store_type"];
}) {
  if (storeType === "shopify") {
    return <span className="inline-block icon_shopify w-4 h-4" />;
  }

  if (storeType === "woo") {
    return <span className="inline-block icon_woo w-5 h-5" />;
  }

  return null;
}

function PurchaseItemCustomer({ item }: { item: WarehousePurchaseItemRecord }) {
  if (!item.sale_path) return null;

  return (
    <ul className="text-sm">
      <li>
        <div className="inline-flex gap-2">
          <CopyToClipboardButton
            className="text-xs btn_xs mb-3 self-start"
            text={item.sale_summary}
          />
          {item.sale_summary}
          {item.sale_note && <TipMark starClassName="text-xl leading-0">{item.sale_note}</TipMark>}
        </div>
      </li>
      <li className="mt-2">
        <div className="inline-flex items-center gap-2">
          <CopyToClipboardButton className="text-xs btn_xs" text={item.customer_email} />
          {item.customer_email}
        </div>
      </li>
    </ul>
  );
}

function usePurchaseItemsSection() {
  const { clearSelectedIds, selectedIds, toggleSelectedIdFromDataAttribute } =
    useWarehouseMoveSelection();
  const { markPurchaseItemAsSaved, recentlySavedItemId } = useRecentlySavedPurchaseItem();

  return {
    clearSelectedIds,
    markPurchaseItemAsSaved,
    recentlySavedItemId,
    selectedIds,
    togglePurchaseItemSelection: toggleSelectedIdFromDataAttribute("purchaseItemId"),
  };
}

function useRecentlySavedPurchaseItem() {
  const [saved, setSaved] = useState<{ id: number } | null>(null);

  const markPurchaseItemAsSaved = useCallback((itemId: number) => {
    setSaved({ id: itemId });
  }, []);

  useEffect(() => {
    if (!saved) return undefined;

    const timeout = window.setTimeout(() => setSaved(null), 2400);

    return () => window.clearTimeout(timeout);
  }, [saved]);

  return { markPurchaseItemAsSaved, recentlySavedItemId: saved?.id ?? null };
}

function purchaseItemRowClassName({
  isSaved,
  isSelected,
}: {
  isSaved: boolean;
  isSelected: boolean;
}) {
  return ["hoverable", isSelected ? "selected" : "", isSaved ? "bg-lime-100/80 dark:bg-lime-900/30" : ""]
    .filter(Boolean)
    .join(" ");
}
