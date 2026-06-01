import { Link, router } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type FormEvent, useState } from "react";
import Button from "@/components/Button";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
import FormError from "@/components/FormError";
import TipMark from "@/components/TipMark";
import { useConfirmedDestroy } from "@/lib/useConfirmedDestroy";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import { useWarehouseMoveSelection } from "@/lib/useWarehouseMoveSelection";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import ImageGallery from "@/pages/Products/components/ImageGallery";
import MoveToWarehouseForm from "@/pages/Purchases/components/MoveToWarehouseForm";
import PaymentProgressBar from "@/pages/Purchases/components/PaymentProgressBar";
import type {
  PaginationMeta,
  ShippingCompanyOption,
  WarehouseOption,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "./types";

type ShowProps = {
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

export default function Show({
  pagination,
  purchase_items,
  search,
  selected_id,
  shipping_companies,
  total_purchase_items,
  warehouse,
  warehouse_move_path,
  warehouses,
}: ShowProps) {
  const { clearSelectedIds, selectedIds, toggleSelectedIdFromDataAttribute } =
    useWarehouseMoveSelection();
  const destroyWarehouse = useConfirmedDestroy(warehouse.destroy_path);

  return (
    <>
      <header className="nav_header">
        <div className="flex gap-4">
          <h1 className="text-3xl lg:text-5xl">{warehouse.name}</h1>
        </div>
        <menu className="nav_menu">
          <li>
            <Link href={warehouse.new_item_path} prefetch>
              <i className="icn">📦</i>
              Add product
            </Link>
          </li>
          <li>
            <Link href={warehouse.edit_path} prefetch>
              <i className="icn">✏</i>
              Edit
            </Link>
          </li>
        </menu>
      </header>

      <div className="section_wide flex flex-col gap-8">
        {total_purchase_items > 0 && (
          <div className="flex flex-col gap-4">
            <div className="table_card">
              <div className="flex justify-between align-center">
                <h3>Number of Items: {pagination.total_count}</h3>
                <div className="w-full max-w-45 px-3 mt-4 text-center lg:w-45">
                  <PaymentProgressBar onlyDebt progress={warehouse.payment_progress} />
                </div>
              </div>

              <div className="page_search -mt-2">
                <SearchBar
                  initialQuery={search.q}
                  path={`/warehouses/${warehouse.id}`}
                  resourceName="purchase_items"
                />
                <div className="pagination_top">
                  <Pagination
                    pagination={pagination}
                    path={`/warehouses/${warehouse.id}`}
                    query={search.q}
                  />
                </div>
              </div>

              {purchase_items.length > 0 ? (
                <>
                  <MoveToWarehouseForm
                    movePath={warehouse_move_path}
                    onMoved={clearSelectedIds}
                    selectedIds={selectedIds}
                    warehouses={warehouses}
                  />
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
                          <div className="flex justify-between text-xs font-medium opacity-80">
                            <span className="text-lime-700/90 dark:text-lime-500/85">paid</span>
                            <span className="text-slate-400">item</span>
                            <span className="text-orange-800/70 dark:text-orange-400/80">debt</span>
                          </div>
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {purchase_items.map((item) => (
                        <tr
                          className={`hoverable ${selected_id === item.id ? "selected" : ""}`}
                          id={String(item.id)}
                          key={item.id}
                          {...rowNavigationProps(item.path)}
                        >
                          <td className="no_events text-center">
                            <input
                              checked={selectedIds.includes(item.id)}
                              data-purchase-item-id={item.id}
                              onChange={toggleSelectedIdFromDataAttribute("purchaseItemId")}
                              onClick={stopRowNavigation}
                              type="checkbox"
                            />
                          </td>
                          <td className="max-w-md">
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
                                {item.sale_store_type === "shopify" && (
                                  <span className="inline-block icon_shopify w-4 h-4" />
                                )}
                                {item.sale_store_type === "woo" && (
                                  <span className="inline-block icon_woo w-5 h-5" />
                                )}
                                {item.sale_title}
                              </Link>
                            )}
                          </td>
                          <td className="max-w-xs">
                            {item.sale_path && (
                              <ul className="text-sm">
                                <li>
                                  <div className="inline-flex gap-2">
                                    <CopyToClipboardButton
                                      className="text-xs btn_xs mb-3 self-start"
                                      text={item.sale_summary}
                                    />
                                    {item.sale_summary}
                                    {item.sale_note && (
                                      <TipMark starClassName="text-xl leading-0">
                                        {item.sale_note}
                                      </TipMark>
                                    )}
                                  </div>
                                </li>
                                <li className="mt-2">
                                  <div className="inline-flex items-center gap-2">
                                    <CopyToClipboardButton
                                      className="text-xs btn_xs"
                                      text={item.customer_email}
                                    />
                                    {item.customer_email}
                                  </div>
                                </li>
                              </ul>
                            )}
                          </td>
                          <td className="max-w-3xs no_events cursor-text">
                            <InlineTrackingNumberEditor
                              item={item}
                              returnTo={`/warehouses/${warehouse.id}`}
                            />
                          </td>
                          <td>
                            <InlineShippingCompanyEditor
                              item={item}
                              returnTo={`/warehouses/${warehouse.id}`}
                              shippingCompanies={shipping_companies}
                            />
                          </td>
                          <td className="w-full max-w-45 lg:w-45">
                            <PaymentProgressBar progress={item.payment_progress} />
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                  <div className="pagination_bottom">
                    <Pagination
                      pagination={pagination}
                      path={`/warehouses/${warehouse.id}`}
                      query={search.q}
                    />
                  </div>
                </>
              ) : search.q ? (
                <SearchResultsEmpty seed={search.q} />
              ) : null}
            </div>
          </div>
        )}

        <div className="cards">
          <ImageGallery media={warehouse.media} />
          <div className="card grow">
            <h5>Name</h5>
            <p>{warehouse.name}</p>
            <h5>English External Name (for Clients)</h5>
            <p>{warehouse.external_name_en}</p>
            <h5>English Description (for Clients)</h5>
            <p>{warehouse.desc_en}</p>
            <h5>German External Name (for Clients)</h5>
            <p>{warehouse.external_name_de}</p>
            <h5>German Description (for Clients)</h5>
            <p>{warehouse.desc_de}</p>
          </div>
          <div className="card grow">
            <h5>CBM</h5>
            <p>{warehouse.cbm}</p>
            <h5>Container Tracking Number</h5>
            <p>{warehouse.container_tracking_number}</p>
            <h5>Courier Tracking URL</h5>
            <p>
              {warehouse.courier_tracking_url ? (
                <a
                  className="link"
                  href={warehouse.courier_tracking_url}
                  rel="noopener noreferrer"
                  target="_blank"
                >
                  {warehouse.courier_tracking_url}
                </a>
              ) : (
                "-"
              )}
            </p>
            <h5>Is Default?</h5>
            <p>{warehouse.is_default ? "Yes" : "No"}</p>
            <h5>Created At</h5>
            <p>{warehouse.created_at}</p>
          </div>
        </div>
      </div>

      <Button className="w-full h-12 mt-16" onClick={destroyWarehouse} variant="danger">
        Destroy this warehouse
      </Button>
    </>
  );
}

function InlineTrackingNumberEditor({
  item,
  returnTo,
}: {
  item: WarehousePurchaseItemRecord;
  returnTo: string;
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [error, setError] = useState("");
  const [trackingNumber, setTrackingNumber] = useState(item.tracking_number || "");

  const handleTrackingError = useCallback((errors: Record<string, string>) => {
    setError(trackingNumberError(errors));
  }, []);

  const handleTrackingSuccess = useCallback(() => {
    setError("");
    setIsEditing(false);
  }, []);

  const submitTrackingNumber = useCallback((event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    router.patch(
      item.tracking_update_path,
      {
        purchase_item: { tracking_number: trackingNumber },
        return_to: returnTo,
      },
      {
        preserveScroll: true,
        onError: handleTrackingError,
        onSuccess: handleTrackingSuccess,
      },
    );
  }, [handleTrackingError, handleTrackingSuccess, item.tracking_update_path, returnTo, trackingNumber]);

  const handleTrackingChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setError("");
    setTrackingNumber(event.target.value);
  }, []);

  const startEditingTracking = useCallback(() => {
    setIsEditing(true);
  }, []);

  const cancelEditingTracking = useCallback(() => {
    setIsEditing(false);
  }, []);

  if (isEditing) {
    return (
      <form
        className="flex flex-col w-full gap-2 no_events"
        onAuxClick={stopInlineEditorNavigation}
        onClick={stopInlineEditorNavigation}
        onKeyDown={stopInlineEditorNavigation}
        onSubmit={submitTrackingNumber}
      >
        <label className="sr-only" htmlFor={`purchase_item_${item.id}_tracking_number`}>
          Tracking number
        </label>
        <input
          autoComplete="off"
          autoFocus
          className="border rounded px-2 py-1 text-sm w-full"
          id={`purchase_item_${item.id}_tracking_number`}
          onChange={handleTrackingChange}
          placeholder="Enter tracking number"
          type="text"
          value={trackingNumber}
        />
        <FormError>{error}</FormError>
        <InlineEditorActions onCancel={cancelEditingTracking} />
      </form>
    );
  }

  return (
    <div
      className="flex flex-col items-center gap-2 text-center"
      onAuxClick={stopInlineEditorNavigation}
      onClick={stopInlineEditorNavigation}
      onKeyDown={stopInlineEditorNavigation}
    >
      {item.tracking_number ? (
        <span className="text-sm font-mono cursor-text">{item.tracking_number}</span>
      ) : null}
      <button className="btn_xs btn_rounded" onClick={startEditingTracking} type="button">
        {item.tracking_number ? "Edit" : "Add"}
      </button>
    </div>
  );
}

function InlineShippingCompanyEditor({
  item,
  returnTo,
  shippingCompanies,
}: {
  item: WarehousePurchaseItemRecord;
  returnTo: string;
  shippingCompanies: ShippingCompanyOption[];
}) {
  const [isEditing, setIsEditing] = useState(false);
  const [error, setError] = useState("");
  const [shippingCompanyId, setShippingCompanyId] = useState(
    item.shipping_company_id ? String(item.shipping_company_id) : "",
  );

  const handleShippingCompanyError = useCallback((errors: Record<string, string>) => {
    setError(shippingCompanyError(errors));
  }, []);

  const handleShippingCompanySuccess = useCallback(() => {
    setError("");
    setIsEditing(false);
  }, []);

  const submitShippingCompany = useCallback((event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError("");
    router.patch(
      item.shipping_company_update_path,
      {
        purchase_item: { shipping_company_id: shippingCompanyId },
        return_to: returnTo,
      },
      {
        preserveScroll: true,
        onError: handleShippingCompanyError,
        onSuccess: handleShippingCompanySuccess,
      },
    );
  }, [handleShippingCompanyError, handleShippingCompanySuccess, item.shipping_company_update_path, returnTo, shippingCompanyId]);

  const handleShippingCompanyChange = useCallback((event: ChangeEvent<HTMLSelectElement>) => {
    setError("");
    setShippingCompanyId(event.target.value);
  }, []);

  const startEditingShippingCompany = useCallback(() => {
    setIsEditing(true);
  }, []);

  const cancelEditingShippingCompany = useCallback(() => {
    setIsEditing(false);
  }, []);

  if (isEditing) {
    return (
      <form
        className="flex flex-col w-full gap-2 no_events"
        onAuxClick={stopInlineEditorNavigation}
        onClick={stopInlineEditorNavigation}
        onKeyDown={stopInlineEditorNavigation}
        onSubmit={submitShippingCompany}
      >
        <label className="sr-only" htmlFor={`purchase_item_${item.id}_shipping_company_id`}>
          Shipping company
        </label>
        <select
          autoFocus
          className="border rounded px-2 py-1 text-sm w-full min-w-35"
          id={`purchase_item_${item.id}_shipping_company_id`}
          onChange={handleShippingCompanyChange}
          value={shippingCompanyId}
        >
          <option value="">Select a shipping company</option>
          {shippingCompanies.map((shippingCompany) => (
            <option key={shippingCompany.id} value={shippingCompany.id}>
              {shippingCompany.name}
            </option>
          ))}
        </select>
        <FormError>{error}</FormError>
        <InlineEditorActions onCancel={cancelEditingShippingCompany} />
      </form>
    );
  }

  return (
    <div
      className="flex flex-col items-center gap-2 text-center"
      onAuxClick={stopInlineEditorNavigation}
      onClick={stopInlineEditorNavigation}
      onKeyDown={stopInlineEditorNavigation}
    >
      {item.shipping_company_name && <div>{item.shipping_company_name}</div>}
      <button
        className="btn_xs btn_rounded no_events"
        onClick={startEditingShippingCompany}
        type="button"
      >
        {item.shipping_company_name ? "Edit" : "Add"}
      </button>
    </div>
  );
}

function InlineEditorActions({ onCancel }: { onCancel: () => void }) {
  return (
    <div className="flex gap-1 justify-center">
      <button className="btn_rounded btn_xs btn_green" type="submit">
        Save
      </button>
      <button className="btn_red btn_xs btn_rounded" onClick={onCancel} type="button">
        Exit
      </button>
    </div>
  );
}

function stopInlineEditorNavigation(event: { stopPropagation(): void }) {
  event.stopPropagation();
}

function trackingNumberError(errors: Record<string, string>) {
  return (
    errors.tracking_number ||
    errors.shipping_company_id ||
    errors.base ||
    "Could not save tracking number"
  );
}

function shippingCompanyError(errors: Record<string, string>) {
  return errors.shipping_company_id || errors.base || "Could not save shipping company";
}
