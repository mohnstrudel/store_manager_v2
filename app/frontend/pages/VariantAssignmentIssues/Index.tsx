import { Link, router, usePage } from "@inertiajs/react";
import { useCallback, type ChangeEvent } from "react";

import { InlineCellEditor, useInlineCellForm } from "@/components/inline-cell-editing";
import PageHeader from "@/components/PageHeader";
import routes from "@/utils/routes";

import type {
  AssignmentIssue,
  AssignmentIssueCounts,
  IssueFilter,
  IssueType,
  PurchaseAssignmentIssue,
  PurchaseItemLinkIssue,
  SaleItemAssignmentIssue,
  VariantAssignmentIssuesPageProps,
} from "./types";

const reloadProps = ["issues", "counts", "pagination"];

const tabs: Array<{ type: IssueType; label: string }> = [
  { type: "purchases", label: "Purchases" },
  { type: "sale_items", label: "SaleItems" },
  { type: "purchase_item_links", label: "PurchaseItem links" },
];

export default function Index(props: VariantAssignmentIssuesPageProps) {
  const hasIssues = props.issues.length > 0;

  return (
    <>
      <PageHeader title="Variant Repairs" />
      <section className="section_wide">
        <IssueTabs counts={props.counts} selectedType={props.issue_type} />
        <IssueFilterSelect
          filter={props.filter}
          filters={props.filters}
          issueType={props.issue_type}
        />

        {hasIssues ? (
          <>
            <IssueTable issueType={props.issue_type} issues={props.issues} />
            <IssuePagination
              filter={props.filter}
              issueType={props.issue_type}
              pagination={props.pagination}
            />
          </>
        ) : (
          <p className="py-12 text-center text-gray-500 dark:text-gray-400">
            No Variant assignment issues
          </p>
        )}
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
    <nav aria-label="Variant assignment issue types" className="tabs mb-6">
      {tabs.map((tab) => (
        <Link
          aria-current={tab.type === selectedType ? "page" : undefined}
          className={tab.type === selectedType ? "active" : undefined}
          href={issuePath(tab.type)}
          key={tab.type}
          prefetch
        >
          {tab.label} {counts[tab.type]}
        </Link>
      ))}
    </nav>
  );
}

function IssueFilterSelect({
  filter,
  filters,
  issueType,
}: {
  filter: string;
  filters: IssueFilter[];
  issueType: IssueType;
}) {
  const onChange = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      router.get(
        routes.variantAssignmentIssues.index.path(),
        {
          issue_type: issueType,
          reason: event.target.value || undefined,
        },
        { preserveState: true },
      );
    },
    [issueType],
  );

  return (
    <label className="mb-4 flex max-w-sm flex-col gap-1">
      <span className="text-sm font-medium">Issue filter</span>
      <select aria-label="Issue filter" onChange={onChange} value={filter}>
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

function IssueTable({ issueType, issues }: { issueType: IssueType; issues: AssignmentIssue[] }) {
  if (issueType === "purchase_item_links") {
    return <LinkIssueTable issues={issues} />;
  }

  return <AssignmentIssueTable issueType={issueType} issues={issues} />;
}

function AssignmentIssueTable({
  issueType,
  issues,
}: {
  issueType: "purchases" | "sale_items";
  issues: AssignmentIssue[];
}) {
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
            isAssignmentIssue(issue) ? (
              <AssignmentIssueRow issue={issue} issueType={issueType} key={issue.id} />
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function AssignmentIssueRow({
  issue,
  issueType,
}: {
  issue: PurchaseAssignmentIssue | SaleItemAssignmentIssue;
  issueType: "purchases" | "sale_items";
}) {
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
      <td>{assignmentImpact(issue)}</td>
      <VariantRepairCell issue={issue} issueType={issueType} />
    </tr>
  );
}

function VariantRepairCell({
  issue,
  issueType,
}: {
  issue: PurchaseAssignmentIssue | SaleItemAssignmentIssue;
  issueType: "purchases" | "sale_items";
}) {
  const route =
    issueType === "purchases"
      ? routes.variantAssignmentIssuesPurchases.update
      : routes.variantAssignmentIssuesSaleItems.update;
  const form = useInlineCellForm({
    editedRecord: issue,
    attributeName: "variant_id",
    route,
    collection: "issues",
    paramKey: issueType === "purchases" ? "purchase" : "sale_item",
    idParam: "id",
    reloadProps,
    mapNewValueToState: (newValue) => {
      const selected = issue.candidates.find((candidate) => candidate.value === Number(newValue));
      return {
        variant_id: Number(newValue),
        current_variant_label: selected?.label ?? issue.current_variant_label,
      };
    },
  });
  const fieldId = `${issue.kind}-${issue.id}-variant`;

  if (issue.candidates.length === 0) {
    return <td>No repair candidates</td>;
  }

  return (
    <InlineCellEditor
      ariaLabel={`Edit Variant for ${issue.reference}`}
      displayValue={issue.current_variant_label}
      error={form.error}
      fieldId={fieldId}
      fieldLabel={`Variant for ${issue.reference}`}
      form={form}
      onSave={form.save}
    >
      <select
        aria-label={`Variant for ${issue.reference}`}
        id={fieldId}
        onChange={form.onChange}
        value={form.value}
      >
        <option disabled value="">
          Select Variant
        </option>
        {issue.candidates.map((candidate) => (
          <option key={candidate.value} value={candidate.value}>
            {candidate.label}
          </option>
        ))}
      </select>
    </InlineCellEditor>
  );
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

function LinkRepairButton({ issue }: { issue: PurchaseItemLinkIssue }) {
  const page = usePage();
  const repair = useCallback(() => {
    router.patch(
      routes.variantAssignmentIssuesPurchaseItemLinks.update.path({ id: issue.id }),
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
      className="btn_rounded btn_xs btn_green"
      onClick={repair}
      type="button"
    >
      Repair link
    </button>
  );
}

function IssuePagination({
  filter,
  issueType,
  pagination,
}: Pick<VariantAssignmentIssuesPageProps, "filter" | "pagination"> & {
  issueType: IssueType;
}) {
  if (pagination.total_pages <= 1) return null;

  return (
    <nav aria-label="Variant repair pagination" className="pagination mt-6">
      {pagination.current_page > 1 ? (
        <Link
          className="pagination_previous"
          href={issuePath(issueType, filter, pagination.current_page - 1)}
          rel="prev"
        >
          Previous
        </Link>
      ) : null}
      <span aria-current="page" className="pagination_link is_current">
        {pagination.current_page}
      </span>
      {pagination.current_page < pagination.total_pages ? (
        <Link
          className="pagination_next"
          href={issuePath(issueType, filter, pagination.current_page + 1)}
          rel="next"
        >
          Next
        </Link>
      ) : null}
    </nav>
  );
}

function issuePath(issueType: IssueType, filter?: string, page?: number) {
  return routes.variantAssignmentIssues.index.path({
    query: {
      issue_type: issueType,
      reason: filter || undefined,
      page,
    },
  });
}

function assignmentImpact(issue: PurchaseAssignmentIssue | SaleItemAssignmentIssue) {
  if (issue.kind === "purchase") {
    return `${unitCount(issue.inventory_units, "inventory unit")}; ${unitCount(
      issue.linked_units,
      "linked unit",
    )}`;
  }

  return `${unitCount(issue.ordered_units, "ordered unit")}; ${unitCount(
    issue.linked_units,
    "linked unit",
  )}`;
}

function linkImpact(issue: PurchaseItemLinkIssue) {
  return `${unitCount(
    issue.exact_replacements_available,
    "exact replacement",
  )} available; ${unitCount(issue.remaining_capacity_after_unlink, "open slot")} after unlink`;
}

function unitCount(count: number, noun: string) {
  return `${count} ${noun}${count === 1 ? "" : "s"}`;
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

function isPurchaseItemLinkIssue(issue: AssignmentIssue): issue is PurchaseItemLinkIssue {
  return issue.kind === "purchase_item_link";
}

function isAssignmentIssue(
  issue: AssignmentIssue,
): issue is PurchaseAssignmentIssue | SaleItemAssignmentIssue {
  return issue.kind === "purchase" || issue.kind === "sale_item";
}
