import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import SearchableIndexSection from "@/components/SearchableIndexSection";
import SyncModal from "@/components/SyncModal";
import { useModalVisibility } from "@/lib/useModalVisibility";
import Table from "./components/Table";
import type { PaginationMeta, SaleIndexRecord } from "./types";

type IndexProps = {
  sales: SaleIndexRecord[];
  pagination: PaginationMeta;
  search: { q: string };
  last_sync_at: string | null;
  last_sync_time: string | null;
};

export default function Index({ sales, pagination, search, last_sync_time }: IndexProps) {
  const { close: closeSync, isOpen: syncOpen, open: openSync } = useModalVisibility();

  return (
    <>
      <PageHeader title="Sales">
        <li>
          <button className="btn_rounded" onClick={openSync} type="button">
            <ArrowPathIcon height={20} width={20} />
            Store Sync
          </button>
        </li>
        <li>
          <Link href="/sales/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      {syncOpen && (
        <SyncModal
          fetchLimitedLabel="Fetch Last 100 Sales"
          id="sales-index-sync-modal"
          lastSyncAt={last_sync_time ? `Last sync: ${last_sync_time}` : null}
          onClose={closeSync}
          pullPath="/sales/pull"
          title="Sales Synchronization"
        />
      )}

      <SearchableIndexSection
        hasResults={sales.length > 0}
        pagination={pagination}
        path="/sales"
        query={search.q}
        resourceName="sales"
        showBottomPagination={sales.length > 0}
      >
        <Table sales={sales} />
      </SearchableIndexSection>
    </>
  );
}
