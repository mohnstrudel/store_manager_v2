import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import SyncModal from "@/components/SyncModal";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
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
      <header className="nav_header">
        <h1>Sales</h1>

        <menu className="nav_menu">
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
        </menu>
      </header>

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

      <div className="section_border_base section_wide">
        <div className="search">
          <SearchBar initialQuery={search.q} path="/sales" resourceName="sales" />
          <div className="pagination_top">
            <Pagination pagination={pagination} path="/sales" query={search.q} />
          </div>
        </div>

        {sales.length > 0 ? (
          <Table sales={sales} />
        ) : search.q ? (
          <SearchResultsEmpty seed={search.q} />
        ) : null}

        {sales.length > 0 && (
          <div className="pagination_bottom">
            <Pagination pagination={pagination} path="/sales" query={search.q} />
          </div>
        )}
      </div>
    </>
  );
}
