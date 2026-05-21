import { useEffect, useState } from "react";
import { router } from "@inertiajs/react";
import { ArrowPathIcon } from "@heroicons/react/20/solid";
import Link from "@/components/Link";
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

export default function Index({
  sales,
  pagination,
  search,
  last_sync_at,
  last_sync_time,
}: IndexProps) {
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
        <hgroup>
          <h1>Sales</h1>
          {last_sync_at && (
            <p className="text-sm font-medium text-gray-500 dark:text-gray-400">{last_sync_at}</p>
          )}
        </hgroup>

        <menu className="nav_menu">
          <li>
            <button className="btn-rounded" onClick={() => setSyncOpen(true)} type="button">
              <ArrowPathIcon height={20} width={20} />
              Store Sync
            </button>
          </li>
          <li>
            <Link href="/sales/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      {syncOpen && (
        <dialog
          id="sales-index-sync-modal"
          onClick={(event) => {
            if (event.target === event.currentTarget) {
              setSyncOpen(false);
            }
          }}
          open
        >
          <div className="dialog-content rounded-lg shadow-lg w-xl p-4 pb-6 -translate-y-10">
            <header className="nav_header mb-6 pb-4">
              <hgroup>
                <h2>Sales Synchronization</h2>
                {last_sync_time && <h4 className="font-medium">Last sync: {last_sync_time}</h4>}
              </hgroup>
              <button
                aria-label="Close"
                className="btn is-muted is-inverted small"
                onClick={() => setSyncOpen(false)}
                type="button"
              >
                ❌
              </button>
            </header>

            <menu className="flex flex-col gap-4">
              <li>
                <button
                  className="w-full h-15 btn-blue btn-rounded"
                  onClick={() => {
                    router.post("/sales/pull");
                    setSyncOpen(false);
                  }}
                  type="button"
                >
                  Fetch Everything
                </button>
              </li>
              <li>
                <button
                  className="w-full h-15 btn-rounded"
                  onClick={() => {
                    router.post("/sales/pull", { limit: 100 });
                    setSyncOpen(false);
                  }}
                  type="button"
                >
                  Fetch Last 100 Sales
                </button>
              </li>
              <li>
                <Link className="w-full h-15" href="/jobs/statuses">
                  Track Jobs Progress
                </Link>
              </li>
            </menu>
          </div>
        </dialog>
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

        {sales.length > 0 ? <Table sales={sales} /> : <SearchResultsEmpty seed={search.q} />}

        {sales.length > 0 && (
          <div className="pagination-bottom">
            <Pagination pagination={pagination} params={{ q: search.q }} path="/sales" />
          </div>
        )}
      </div>
    </>
  );
}
