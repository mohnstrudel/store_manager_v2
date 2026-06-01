import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import SearchableIndexSection from "@/components/SearchableIndexSection";
import SyncModal from "@/components/SyncModal";
import { useModalVisibility } from "@/lib/useModalVisibility";
import { type PaginationMeta, type ProductIndexRecord } from "./types";
import IndexTable from "./components/IndexTable";

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

      <SearchableIndexSection
        hasResults={products.length > 0}
        pagination={pagination}
        path="/products"
        query={search.q}
        resourceName="products"
      >
        <IndexTable products={products} />
      </SearchableIndexSection>
    </>
  );
}
