import { Link } from "@inertiajs/react";
import { BugIcon, PlusIcon, RefreshCwIcon, TagsIcon } from "lucide-react";

import PageHeader from "@/components/PageHeader";
import Pagination from "@/components/Pagination";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import SyncModal from "@/components/SyncModal";
import type { SalesIndex } from "@/types/serializers";
import routes from "@/utils/routes";
import { useModalVisibility } from "@/utils/useModalVisibility";

import { hasFilters, listingParams } from "./Index/salesListing";
import SearchForm from "./Index/SearchForm";
import Table from "./Index/Table";

type IndexProps = SalesIndex;

export default function Index({
  sales,
  pagination,
  search,
  sort,
  filters,
  tag_options,
  tag_colors,
  can_tag_sales,
  can_view_broken_sales,
  broken_problem_count,
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
        {can_view_broken_sales && (
          <li>
            <Link
              aria-label={brokenLinkLabel(broken_problem_count)}
              className="relative"
              href={routes.brokenSales.index.path()}
              prefetch
            >
              <BugIcon />
              Broken
              {broken_problem_count ? (
                <span aria-hidden="true" className="nav_menu_badge">
                  {badgeCount(broken_problem_count)}
                </span>
              ) : null}
            </Link>
          </li>
        )}
        <li>
          <Link href={routes.salesTags.index.path()} prefetch>
            <TagsIcon />
            Tags
          </Link>
        </li>
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
        <div className="page_search">
          <SearchForm
            filters={filters}
            q={search.q}
            sort={sort}
            tagColors={tag_colors}
            tagOptions={tag_options}
          >
            <div className="pagination_top lg:min-w-0">
              <Pagination pagination={pagination} params={appliedParams} path={salesPath} />
            </div>
          </SearchForm>
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

function brokenLinkLabel(count: number | null) {
  if (!count) return undefined;

  return `Broken, ${count} problem${count === 1 ? "" : "s"}`;
}

function badgeCount(count: number) {
  return count > 99 ? "99+" : String(count);
}

function EmptyResults({ hasCriteria, seed }: { hasCriteria: boolean; seed: string }) {
  if (!hasCriteria) return null;

  return <SearchResultsEmpty seed={seed} />;
}
