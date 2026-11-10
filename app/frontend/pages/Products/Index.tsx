import { Link } from "@inertiajs/react";
import { PlusIcon, RefreshCwIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import SyncModal from "@/components/SyncModal";
import { useModalVisibility } from "@/utils/useModalVisibility";

import IndexTable from "./components/IndexTable";
import { type PaginationMeta, type ProductIndexRecord } from "./types";

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
          <button onClick={openSync} type="button">
            <RefreshCwIcon />
            Store Sync
          </button>
        </li>
        <li>
          <Link href="/products/new" prefetch>
            <PlusIcon />
            Add New Record
          </Link>
        </li>
      </PageHeader>

      {syncOpen && (
        <SyncModal
          id="products-index-sync-modal"
          lastSyncAt={last_sync_at}
          onClose={closeSync}
          pullPath="/products/pull"
          title="Products Synchronization"
        />
      )}

      <SearchableTableSection
        hasResults={products.length > 0}
        pagination={pagination}
        path="/products"
        query={search.q}
        resourceName="products"
      >
        <IndexTable products={products} />
      </SearchableTableSection>
    </>
  );
}
