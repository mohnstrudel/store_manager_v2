import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import SyncModal from "@/components/SyncModal";
import { useModalVisibility } from "@/lib/useModalVisibility";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import Pagination from "@/components/Pagination";
import PageHeader from "@/components/PageHeader";
import { type PaginationMeta, type ProductIndexRecord } from "./types";
import ZoomableThumbnail from "@/components/ZoomableThumbnail";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";

type IndexProps = {
  products: ProductIndexRecord[];
  pagination: PaginationMeta;
  search: { q: string };
  last_sync_at: string | null;
};

export default function Index({ products, pagination, search, last_sync_at }: IndexProps) {
  const { close: closeSync, isOpen: syncOpen, open: openSync } = useModalVisibility();

  return (
    <>
      <PageHeader title="Products">
        <li>
          <button className="btn_rounded" onClick={openSync} type="button">
            <ArrowPathIcon height={20} width={20} />
            Store Sync
          </button>
        </li>
        <li>
          <Link href="/products/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      {syncOpen && (
        <SyncModal
          fetchLimitedLabel="Fetch Last 100 Products"
          id="products-index-sync-modal"
          lastSyncAt={last_sync_at}
          onClose={closeSync}
          pullPath="/products/pull"
          title="Products Synchronization"
        />
      )}

      <div className="section_border_base section_wide">
        <div className="search">
          <SearchBar initialQuery={search.q} path="/products" resourceName="products" />
          <div className="pagination_top">
            <Pagination pagination={pagination} path="/products" query={search.q} />
          </div>
        </div>

        {products.length > 0 ? (
          <table>
            <thead>
              <tr>
                <th className="text-center">Image</th>
                <th>Full name + Variants</th>
                <th>Woo ID</th>
                <th>Shopify ID</th>
                <th className="text-right">Actions</th>
              </tr>
            </thead>
            <tbody>
              {products.map((product) => (
                <tr className="hoverable" key={product.id} {...rowNavigationProps(product.path)}>
                  <td className="text-center">
                    <ZoomableThumbnail
                      alt={product.title}
                      key={`${product.id}-${product.thumb_url ?? "missing"}`}
                      src={product.thumb_url}
                    />
                  </td>
                  <td>
                    <span>{product.full_title}</span>
                    {product.variants.length > 0 && (
                      <ul className="ml-4 mt-2">
                        {product.variants.map((variant) => (
                          <li className="mt-1" key={variant.id}>
                            {variant.title}
                          </li>
                        ))}
                      </ul>
                    )}
                  </td>
                  <td>{product.woo_store_id || "—"}</td>
                  <td>{product.shopify_id_short || "—"}</td>
                  <td className="actions text-right" onClick={stopRowNavigation}>
                    <Link href={product.edit_path} prefetch>
                      <i className="icn">✏</i>
                      Edit
                    </Link>
                    <Link href={product.new_purchase_path} prefetch>
                      <i className="icn">💰</i>
                      Purchase
                    </Link>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        ) : search.q ? (
          <SearchResultsEmpty seed={search.q} />
        ) : null}

        <div className="pagination_bottom">
          <Pagination pagination={pagination} path="/products" query={search.q} />
        </div>
      </div>
    </>
  );
}
