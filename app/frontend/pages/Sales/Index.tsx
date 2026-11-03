import { Link } from "@inertiajs/react";
import { PlusIcon, RefreshCwIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import Pagination from "@/components/Pagination";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import SyncModal from "@/components/SyncModal";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";
import routes from "@/utils/routes";
import { useModalVisibility } from "@/utils/useModalVisibility";

import { hasFilters, listingParams } from "./Index/salesListing";
import SearchForm from "./Index/SearchForm";
import Table from "./Index/Table";
import type { PaginationMeta, SaleIndexRecord, SaleSort, SalesFilters } from "./types";

type IndexProps = {
  sales: SaleIndexRecord[];
  pagination: PaginationMeta;
  search: { q: string };
  sort: SaleSort;
  filters: SalesFilters;
  tag_options: SalesTagRecord[];
  tag_colors: SalesTagColor[];
  can_tag_sales: boolean;
  last_sync_time: string | null;
};

export default function Index({
  sales,
  pagination,
  search,
  sort,
  filters,
  tag_options,
  tag_colors,
  can_tag_sales,
  last_sync_time,
}: IndexProps) {
  const { close: closeSync, isOpen: syncOpen, open: openSync } = useModalVisibility();
  const hasSales = sales.length > 0;
  const hasCriteria = search.q !== "" || hasFilters(filters);
  const appliedParams = listingParams({ q: search.q, sort, ...filters });
  const salesPath = routes.sales.list.path();
  const lastSyncLabel = last_sync_time ? `Last sync: ${last_sync_time}` : null;

  return (
    <>
      <PageHeader title="Sales">
        <li>
          <button onClick={openSync} type="button">
            <RefreshCwIcon />
            Store Sync
          </button>
        </li>
        <li>
          <Link href="/sales/new" prefetch>
            <PlusIcon />
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

      <section className="section_border_base section_wide">
        <div className="page_search lg:items-start">
          <SearchForm filters={filters} q={search.q} sort={sort} />
          <div className="pagination_top lg:min-w-0 lg:shrink-0 lg:pt-0.5">
            <Pagination pagination={pagination} params={appliedParams} path={salesPath} />
          </div>
        </div>

        {hasSales ? (
          <Table
            canTagSales={can_tag_sales}
            sales={sales}
            sort={sort}
            tagColors={tag_colors}
            tagOptions={tag_options}
          />
        ) : (
          <EmptyResults hasCriteria={hasCriteria} seed={search.q} />
        )}

        {hasSales ? (
          <div className="pagination_bottom">
            <Pagination pagination={pagination} params={appliedParams} path={salesPath} />
          </div>
        ) : null}
      </section>
    </>
  );
}

function EmptyResults({ hasCriteria, seed }: { hasCriteria: boolean; seed: string }) {
  if (!hasCriteria) return null;

  return <SearchResultsEmpty seed={seed} />;
}
