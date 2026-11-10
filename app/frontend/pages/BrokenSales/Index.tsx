import { Link, router, useForm } from "@inertiajs/react";
import { ChevronLeftIcon, ChevronRightIcon, WrenchIcon } from "lucide-react";
import { useCallback, type ChangeEvent } from "react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import ImportFailures from "./Index/ImportFailures";
import { issuePath, type IssueLocation } from "./Index/issuePath";
import OrderIssues from "./Index/OrderIssues";
import PurchaseLinks from "./Index/PurchaseLinks";
import Purchases from "./Index/Purchases";
import ShopifyConflicts from "./Index/ShopifyConflicts";
import SkuCollisions from "./Index/SkuCollisions";
import type {
  AssignmentIssue,
  AssignmentIssueCounts,
  BrokenSalesPageProps,
  IssueFilter,
  IssueType,
} from "./types";

const tabs: Array<{ type: IssueType; label: string }> = [
  { type: "sale_items", label: "Orders" },
  { type: "import_failures", label: "Import failures" },
  { type: "purchases", label: "Purchases" },
  { type: "purchase_item_links", label: "Purchase links" },
  { type: "sku_collisions", label: "SKU collisions" },
  { type: "shopify_conflicts", label: "Shopify conflicts" },
];

const issueDescriptions: Partial<Record<IssueType, string>> = {
  purchases:
    "Choose the right Variant for Purchases with a missing or mismatched Product or Variant.",
  purchase_item_links:
    "Repair link removes a mismatched link and fills open slots with matching unlinked PurchaseItems.",
  sku_collisions: "Open each Variant that shares a SKU and give it a unique SKU.",
  shopify_conflicts:
    "In Shopify, give every Variant of the Product unique options, then pull the Product again.",
};

const FIX_OBVIOUS_CASES_CONFIRMATION =
  "Assign the Variant to every line that has only one possible Variant? Lines where several Variants fit are skipped and stay here for you to choose.";

export default function Index(props: BrokenSalesPageProps) {
  return (
    <>
      <PageHeader title="Broken Sales">{props.repairable && <FixObviousCases />}</PageHeader>
      <section className="section_wide">
        <IssueTabs counts={props.counts} selectedType={props.issue_type} />
        {props.filters.length > 1 && <IssueFilterSelect filters={props.filters} location={props} />}
        {issueDescriptions[props.issue_type] && (
          <p
            className="my-4 text-sm text-gray-600 dark:text-gray-300"
            data-testid="issue-description"
          >
            {issueDescriptions[props.issue_type]}
          </p>
        )}

        <IssueList issues={props.issues} location={props} />
        <IssuePagination location={props} pagination={props.pagination} />
      </section>
    </>
  );
}

function FixObviousCases() {
  const { post, processing } = useForm({});
  const fix = useCallback(() => {
    if (!window.confirm(FIX_OBVIOUS_CASES_CONFIRMATION)) return;

    post(routes.brokenSalesBackfills.create.path());
  }, [post]);

  return (
    <li>
      <button disabled={processing} onClick={fix} type="button">
        <WrenchIcon />
        Fix obvious cases
      </button>
    </li>
  );
}

function IssueTabs({
  counts,
  selectedType,
}: {
  counts: AssignmentIssueCounts;
  selectedType: IssueType;
}) {
  return (
    <div
      aria-label="Broken Sales issue types"
      className="tab_bar_underline flex-wrap mb-6"
      role="tablist"
    >
      {tabs
        .filter((tab) => counts[tab.type] > 0 || tab.type === selectedType)
        .map((tab) => {
          const active = tab.type === selectedType;

          return (
            <Link
              aria-label={`${tab.label} ${counts[tab.type]}`}
              aria-selected={active}
              className="tab_btn_underline w-auto"
              href={issuePath({ issue_type: tab.type })}
              key={tab.type}
              prefetch
              role="tab"
            >
              {tab.label}
              <span className="ml-1.5 text-xs text-gray-400 dark:text-gray-500">
                {counts[tab.type]}
              </span>
            </Link>
          );
        })}
    </div>
  );
}

function IssueFilterSelect({
  filters,
  location,
}: {
  filters: IssueFilter[];
  location: IssueLocation;
}) {
  const onChange = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      router.get(
        issuePath({ ...location, filter: event.target.value }),
        {},
        { preserveState: true },
      );
    },
    [location],
  );

  return (
    <label className="mb-4 flex max-w-sm flex-col gap-1">
      <span className="text-sm font-medium">Issue filter</span>
      <select aria-label="Issue filter" onChange={onChange} value={location.filter}>
        <option value="">All issues</option>
        {filters.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </label>
  );
}

function IssueList({
  issues,
  location,
}: {
  issues: AssignmentIssue[];
  location: BrokenSalesPageProps;
}) {
  switch (location.issue_type) {
    case "sale_items":
      return (
        <OrderIssues
          issues={issues}
          productId={location.product_id}
          productTitle={location.product_title}
          scope={location.scope ?? "all"}
          view={location.view ?? "orders"}
        />
      );
    case "import_failures":
      return <ImportFailures issues={issues} />;
    case "purchases":
      return <Purchases issues={issues} />;
    case "purchase_item_links":
      return <PurchaseLinks issues={issues} />;
    case "sku_collisions":
      return <SkuCollisions issues={issues} />;
    case "shopify_conflicts":
      return <ShopifyConflicts issues={issues} />;
  }
}

function IssuePagination({
  location,
  pagination,
}: Pick<BrokenSalesPageProps, "pagination"> & {
  location: IssueLocation;
}) {
  if (pagination.total_pages <= 1) return null;

  return (
    <nav aria-label="Broken Sales pagination" className="pagination mt-6">
      {pagination.current_page > 1 ? (
        <Link
          className="pagination_previous"
          href={issuePath(location, pagination.current_page - 1)}
          rel="prev"
        >
          <ChevronLeftIcon aria-hidden="true" />
          Previous
        </Link>
      ) : null}
      <span aria-current="page" className="pagination_link is_current">
        {pagination.current_page}
      </span>
      {pagination.current_page < pagination.total_pages ? (
        <Link
          className="pagination_next"
          href={issuePath(location, pagination.current_page + 1)}
          rel="next"
        >
          Next
          <ChevronRightIcon aria-hidden="true" />
        </Link>
      ) : null}
    </nav>
  );
}
