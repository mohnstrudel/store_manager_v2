import { Link, router, usePage } from "@inertiajs/react";
import { ChevronLeftIcon, ChevronRightIcon, WrenchIcon } from "lucide-react";
import { useCallback, type ChangeEvent } from "react";

import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";
import { useConfirmAction } from "@/utils/useConfirmAction";

import ImportFailures from "./Index/ImportFailures";
import { issuePath, type IssueLocation } from "./Index/issuePath";
import OrderIssues from "./Index/OrderIssues";
import VariantRepairCell, { reloadProps } from "./Index/VariantRepairCell";
import type {
  AssignmentIssue,
  AssignmentIssueCounts,
  IssueFilter,
  IssueType,
  PurchaseAssignmentIssue,
  PurchaseItemLinkIssue,
  ShopifyConflictIssue,
  SkuCollisionIssue,
  BrokenSalesPageProps,
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

export default function Index(props: BrokenSalesPageProps) {
  const runBackfill = useConfirmAction("post", routes.brokenSalesBackfills.create.path(), {
    message:
      "Assign the Variant to every line that has only one possible Variant? Lines where several Variants fit are skipped and stay here for you to choose.",
  });

  return (
    <>
      <PageHeader title="Broken Sales">
        {props.repairable && (
          <li>
            <button onClick={runBackfill} type="button">
              <WrenchIcon />
              Fix obvious cases
            </button>
          </li>
        )}
      </PageHeader>
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

function IssueTabs({
  counts,
  selectedType,
}: {
  counts: AssignmentIssueCounts;
  selectedType: IssueType;
}) {
  return (
    <div
      aria-label="Variant assignment issue types"
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
  const issueType = location.issue_type;
  const onChange = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      router.get(
        routes.brokenSales.index.path(),
        { issue_type: issueType, reason: event.target.value || undefined },
        { preserveState: true },
      );
    },
    [issueType],
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
  if (location.issue_type === "sale_items") {
    return (
      <OrderIssues
        issues={issues}
        productId={location.product_id}
        productTitle={location.product_title}
        scope={location.scope ?? "all"}
        view={location.view ?? "orders"}
      />
    );
  }
  if (location.issue_type === "import_failures") {
    return <ImportFailures issues={issues} />;
  }

  if (issues.length === 0) {
    return (
      <p className="py-12 text-center text-gray-500 dark:text-gray-400">
        No Variant assignment issues
      </p>
    );
  }

  return <IssueTable issueType={location.issue_type} issues={issues} />;
}

function IssueTable({
  issueType,
  issues,
}: {
  issueType: Exclude<IssueType, "sale_items" | "import_failures">;
  issues: AssignmentIssue[];
}) {
  if (issueType === "purchase_item_links") {
    return <LinkIssueTable issues={issues} />;
  }
  if (issueType === "sku_collisions") {
    return <SkuCollisionTable issues={issues} />;
  }
  if (issueType === "shopify_conflicts") {
    return <ShopifyConflictTable issues={issues} />;
  }

  return <PurchaseIssueTable issues={issues} />;
}

function LinkIssueTable({ issues }: { issues: AssignmentIssue[] }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>PurchaseItem</th>
            <th>Purchase identity</th>
            <th>SaleItem identity</th>
            <th>Impact</th>
            <th>Repair</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isPurchaseItemLinkIssue(issue) ? (
              <tr aria-label={`PurchaseItem link ${issue.id}`} key={issue.id}>
                <td>#{issue.id}</td>
                <td>
                  <Link href={issue.purchase_path}>
                    {issue.purchase_product_title} / {issue.purchase_variant_label}
                  </Link>
                </td>
                <td>
                  <Link href={issue.sale_path}>
                    {issue.sale_product_title} / {issue.sale_variant_label}
                  </Link>
                </td>
                <td>{linkImpact(issue)}</td>
                <td>
                  <LinkRepairButton issue={issue} />
                </td>
              </tr>
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}
function SkuCollisionTable({ issues }: { issues: AssignmentIssue[] }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>SKU</th>
            <th>Product / Variant</th>
            <th>Colliding with</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isSkuCollisionIssue(issue) ? (
              <tr
                aria-label={`SKU collision ${issue.sku} on ${issue.product_title}`}
                key={issue.id}
              >
                <td>{issue.sku}</td>
                <td>
                  <Link href={issue.edit_path}>
                    {issue.product_title} / {issue.variant_label}
                  </Link>
                </td>
                <td>
                  {issue.colliding_with.map((other) => (
                    <Link href={other.edit_path} key={other.variant_id}>
                      {other.product_title} / {other.variant_label}
                    </Link>
                  ))}
                </td>
              </tr>
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function ShopifyConflictTable({ issues }: { issues: AssignmentIssue[] }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Shopify Variant</th>
            <th>Shopify options</th>
            <th>Already used by</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isShopifyConflictIssue(issue) ? (
              <tr
                aria-label={`Shopify conflict ${issue.store_id} on ${issue.product_title}`}
                key={issue.id}
              >
                <td>
                  <Link href={issue.edit_path}>{issue.product_title}</Link>
                </td>
                <td>
                  {issue.sku || "No SKU"}
                  <br />
                  <span className="text-xs text-gray-400 dark:text-gray-500">{issue.store_id}</span>
                </td>
                <td>
                  {issue.shopify_options
                    .map((option) => `${option.name}: ${option.value}`)
                    .join(" / ")}
                </td>
                <td>
                  {issue.conflicting_variant_label
                    ? `${issue.conflicting_variant_label} (${
                        issue.conflicting_variant_sku || "No SKU"
                      })`
                    : "Deleted Variant"}
                </td>
              </tr>
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}
function PurchaseIssueTable({ issues }: { issues: AssignmentIssue[] }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Record</th>
            <th>Evidence</th>
            <th>Impact</th>
            <th>Variant repair</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isPurchaseIssue(issue) ? <PurchaseIssueRow issue={issue} key={issue.id} /> : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function IssuePagination({
  location,
  pagination,
}: Pick<BrokenSalesPageProps, "pagination"> & {
  location: IssueLocation;
}) {
  if (pagination.total_pages <= 1) return null;

  return (
    <nav aria-label="Variant repair pagination" className="pagination mt-6">
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
function PurchaseIssueRow({ issue }: { issue: PurchaseAssignmentIssue }) {
  return (
    <tr aria-label={issue.reference}>
      <td>
        <Link href={issue.record_path}>{issue.reference}</Link>
      </td>
      <td>
        <div>{issue.product_title}</div>
        <div>{issue.current_variant_label}</div>
        <small>{reasonLabel(issue.reason)}</small>
      </td>
      <td>{purchaseImpact(issue)}</td>
      <VariantRepairCell issue={issue} />
    </tr>
  );
}

function reasonLabel(reason: string) {
  return (
    {
      missing_product: "Missing Product",
      missing_variant: "Missing Variant",
      product_mismatch: "Product / Variant mismatch",
      purchase_identity: "Purchase identity mismatch",
      sale_item_identity: "SaleItem identity mismatch",
    }[reason] ?? reason
  );
}
function purchaseImpact(issue: PurchaseAssignmentIssue) {
  return `${unitCount(issue.inventory_units, "inventory unit")}; ${unitCount(
    issue.linked_units,
    "linked unit",
  )}`;
}
function unitCount(count: number, noun: string) {
  return `${count} ${noun}${count === 1 ? "" : "s"}`;
}
function LinkRepairButton({ issue }: { issue: PurchaseItemLinkIssue }) {
  const page = usePage();
  const repair = useCallback(() => {
    router.patch(
      routes.brokenSalesPurchaseItemLinks.update.path({
        id: issue.id,
      }),
      { return_to: page.url },
      {
        only: reloadProps,
        preserveScroll: true,
      },
    );
  }, [issue.id, page.url]);

  return (
    <button
      aria-label={`Repair PurchaseItem link ${issue.id}`}
      className="btn_xs btn_green"
      onClick={repair}
      type="button"
    >
      Repair link
    </button>
  );
}

function linkImpact(issue: PurchaseItemLinkIssue) {
  return `${unitCount(
    issue.exact_replacements_available,
    "exact replacement",
  )} available; ${unitCount(issue.remaining_capacity_after_unlink, "open slot")} after unlink`;
}

function isPurchaseItemLinkIssue(issue: AssignmentIssue): issue is PurchaseItemLinkIssue {
  return issue.kind === "purchase_item_link";
}

function isPurchaseIssue(issue: AssignmentIssue): issue is PurchaseAssignmentIssue {
  return issue.kind === "purchase";
}

function isSkuCollisionIssue(issue: AssignmentIssue): issue is SkuCollisionIssue {
  return issue.kind === "sku_collision";
}

function isShopifyConflictIssue(issue: AssignmentIssue): issue is ShopifyConflictIssue {
  return issue.kind === "shopify_conflict";
}
