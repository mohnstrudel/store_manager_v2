import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import SyncModal from "@/components/SyncModal";
import { useModalVisibility } from "@/utils/useModalVisibility";
import Table from "./Index/Table";
import type { PaginationMeta, SaleIndexRecord } from "./types";

type IndexProps = {
  sales: SaleIndexRecord[];
  pagination: PaginationMeta;
  search: { q: string };
  last_sync_time: string | null;
};

export default function Index({ sales, pagination, search, last_sync_time }: IndexProps) {
  const { close: closeSync, isOpen: syncOpen, open: openSync } = useModalVisibility();
  const hasSales = sales.length > 0;
  const lastSyncLabel = last_sync_time ? `Last sync: ${last_sync_time}` : null;

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
          lastSyncAt={lastSyncLabel}
          onClose={closeSync}
          pullPath="/sales/pull"
          title="Sales Synchronization"
        />
      )}

      <SearchableTableSection
        hasResults={hasSales}
        pagination={pagination}
        path="/sales"
        query={search.q}
        resourceName="sales"
        showBottomPagination={hasSales}
      >
        <Table sales={sales} />
      </SearchableTableSection>
    </>
  );
}
