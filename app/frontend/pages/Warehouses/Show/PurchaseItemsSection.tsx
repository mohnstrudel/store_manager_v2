import { Link } from "@inertiajs/react";
import { type ChangeEvent, useCallback, useRef } from "react";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import TipMark from "@/components/TipMark";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useWarehouseMoveSelection } from "@/utils/useWarehouseMoveSelection";
import MoveToWarehouseForm from "@/components/MoveToWarehouseForm";
import PaymentProgressBar from "@/components/PaymentProgressBar";
import type {
  PaginationMeta,
  ShippingCompanyOption,
  WarehouseOption,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "../types";
import { type InlineCellEditorHandle } from "@/components/inline-cell-editing";
import { InlineShippingCompanyEditor } from "@/components/purchase-item-cells/InlineShippingCompanyEditor";
import { InlineTrackingNumberEditor } from "@/components/purchase-item-cells/InlineTrackingNumberEditor";

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
              selectedId={selected_id}
              selectedIds={section.selectedIds}
              shippingCompanies={shipping_companies}
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
  selectedId,
  selectedIds,
  shippingCompanies,
  onToggleSelectedId,
}: {
  purchaseItems: WarehousePurchaseItemRecord[];
  selectedId: number | null;
  selectedIds: number[];
  shippingCompanies: ShippingCompanyOption[];
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
            shippingCompanies={shippingCompanies}
            isSelected={selectedId === item.id}
            isSelectionChecked={selectedIds.includes(item.id)}
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
  isSelected,
  isSelectionChecked,
  shippingCompanies,
  onToggleSelectedId,
}: {
  item: WarehousePurchaseItemRecord;
  isSelected: boolean;
  isSelectionChecked: boolean;
  shippingCompanies: ShippingCompanyOption[];
  onToggleSelectedId: (event: ChangeEvent<HTMLInputElement>) => void;
}) {
  const shippingRef = useRef<InlineCellEditorHandle>(null);
  const openShipping = useCallback(() => {
    shippingRef.current?.open();
  }, []);
  const trackingAutoOpenShipping = item.shipping_company_id ? undefined : openShipping;

  return (
    <tr
      className={purchaseItemRowClassName({ isSelected })}
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
      <InlineTrackingNumberEditor item={item} onAutoOpen={trackingAutoOpenShipping} />
      <InlineShippingCompanyEditor
        ref={shippingRef}
        item={item}
        shippingCompanies={shippingCompanies}
      />
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
          {item.sale_note && (
            <TipMark size="large" tone="orange">
              {item.sale_note}
            </TipMark>
          )}
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

  return {
    clearSelectedIds,
    selectedIds,
    togglePurchaseItemSelection: toggleSelectedIdFromDataAttribute("purchaseItemId"),
  };
}

function purchaseItemRowClassName({ isSelected }: { isSelected: boolean }) {
  return ["hoverable", isSelected ? "selected" : ""].filter(Boolean).join(" ");
}
