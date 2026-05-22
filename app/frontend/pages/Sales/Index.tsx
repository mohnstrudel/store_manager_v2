import { useEffect, useState } from "react";
import { ArrowPathIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import SyncModal from "@/components/SyncModal";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
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
  const [syncOpen, setSyncOpen] = useState(false);

  useEffect(() => {
    function handleKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") {
        setSyncOpen(false);
      }
    }

    if (!syncOpen) return undefined;

    window.addEventListener("keydown", handleKeyDown);

    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [syncOpen]);

  return (
    <>
      <header className="nav_header">
        <h1>Sales</h1>

        <menu className="nav_menu">
          <li>
            <button className="btn-rounded" onClick={() => setSyncOpen(true)} type="button">
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
          onClose={() => setSyncOpen(false)}
          pullPath="/sales/pull"
          title="Sales Synchronization"
        />
      )}

      <div className="section-border-base section-wide">
        <div className="search">
          <SearchBar
            initialQuery={search.q}
            path="/sales"
            reloadOnly={["sales", "pagination", "search"]}
          />
          <div className="pagination-top">
            <Pagination pagination={pagination} params={{ q: search.q }} path="/sales" />
          </div>
        </div>

        {sales.length > 0 ? (
          <Table sales={sales} />
        ) : search.q ? (
          <SearchResultsEmpty seed={search.q} />
        ) : null}

        {sales.length > 0 && (
          <div className="pagination-bottom">
            <Pagination pagination={pagination} params={{ q: search.q }} path="/sales" />
          </div>
        )}
      </div>
    </>
  );
}
