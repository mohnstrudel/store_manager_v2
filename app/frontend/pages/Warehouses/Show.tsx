import { router, Link } from "@inertiajs/react";
import Button from "@/components/Button";
import CopyToClipboardButton from "@/components/CopyToClipboardButton";
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
  WarehouseOption,
  WarehousePurchaseItemRecord,
  WarehouseShowRecord,
} from "./types";

type ShowProps = {
  pagination: PaginationMeta;
  purchase_items: WarehousePurchaseItemRecord[];
  search: { q: string };
  selected_id: number | null;
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
  total_purchase_items,
  warehouse,
  warehouse_move_path,
  warehouses,
}: ShowProps) {
  const {
    clearSelectedIds,
    selectedIds,
    toggleSelectedIdFromDataAttribute,
  } = useWarehouseMoveSelection();

  function destroyWarehouse() {
    if (window.confirm("Are you sure?")) {
      router.delete(warehouse.destroy_path);
    }
  }

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

              <div className="search -mt-2">
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
                                      <span className="text-yellow-600 ml-2">
                                        * {item.sale_note}
                                      </span>
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
                            <div className="flex flex-col items-center gap-2 text-center">
                              {item.tracking_number ? (
                                <span className="text-sm font-mono cursor-text">
                                  {item.tracking_number}
                                </span>
                              ) : null}
                              <Link
                                className="btn_xs btn_rounded"
                                href={item.tracking_edit_path}
                                onClick={stopRowNavigation}
                                prefetch
                              >
                                {item.tracking_number ? "Edit" : "Add"}
                              </Link>
                            </div>
                          </td>
                          <td>
                            <div className="flex flex-col items-center gap-2 text-center">
                              {item.shipping_company_name && (
                                <div>{item.shipping_company_name}</div>
                              )}
                              <Link
                                className="btn_xs btn_rounded no_events"
                                href={item.shipping_company_edit_path}
                                onClick={stopRowNavigation}
                                prefetch
                              >
                                {item.shipping_company_name ? "Edit" : "Add"}
                              </Link>
                            </div>
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
