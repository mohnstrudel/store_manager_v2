import { Link, router } from "@inertiajs/react";
import { XIcon } from "lucide-react";
import { useCallback, type ChangeEvent } from "react";

import type {
  AssignmentIssue,
  IssueView,
  OrderImportFailure,
  OrderScope,
  SaleItemAssignmentIssue,
} from "../types";
import ImportFailureActions from "./ImportFailureActions";
import { issuePath } from "./issuePath";
import OrderTitle, { orderName } from "./OrderTitle";
import ProductIssues from "./ProductIssues";
import VariantRepairCell from "./VariantRepairCell";

const scopes: Array<{ scope: OrderScope; label: string; empty: string }> = [
  {
    scope: "active",
    label: "Active",
    empty: "No active orders need a Variant",
  },
  { scope: "all", label: "All", empty: "No orders need a Variant" },
  {
    scope: "closed",
    label: "Closed",
    empty: "No closed orders need a Variant",
  },
];

type OrderIssuesProps = {
  issues: AssignmentIssue[];
  productId: number | null;
  productTitle: string | null;
  scope: OrderScope;
  view: IssueView;
};

export default function OrderIssues({
  issues,
  productId,
  productTitle,
  scope,
  view,
}: OrderIssuesProps) {
  const groupedByProduct = view === "products";

  return (
    <>
      <div className="flex flex-col sm:flex-row sm:flex-wrap sm:items-center gap-2 sm:gap-6 w-full mb-4">
        {!groupedByProduct && <ScopeTabs productId={productId} scope={scope} />}
        <GroupByProductCheckbox checked={groupedByProduct} />
        {!groupedByProduct && productTitle !== null && (
          <ProductChip scope={scope} title={productTitle} />
        )}
      </div>
      {groupedByProduct ? (
        <ProductIssues issues={issues} />
      ) : (
        <OrderRows issues={issues} scope={scope} />
      )}
    </>
  );
}

function ScopeTabs({ productId, scope }: Pick<OrderIssuesProps, "productId" | "scope">) {
  return (
    <div
      aria-label="Order scope"
      className="tab_bar tab_bar_outline shrink-0 sm:w-fit mt-0 mb-0"
      role="tablist"
    >
      {scopes.map((option) => (
        <Link
          aria-selected={option.scope === scope}
          className="tab_btn whitespace-nowrap"
          href={issuePath({
            issue_type: "sale_items",
            scope: option.scope,
            product_id: productId,
          })}
          key={option.scope}
          role="tab"
        >
          {option.label}
        </Link>
      ))}
    </div>
  );
}

function GroupByProductCheckbox({ checked }: { checked: boolean }) {
  const handleChange = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    router.get(
      issuePath({
        issue_type: "sale_items",
        view: event.target.checked ? "products" : "orders",
      }),
    );
  }, []);

  return (
    <label className="flex items-center gap-2 whitespace-nowrap text-sm m-0 cursor-pointer">
      <input checked={checked} className="small" onChange={handleChange} type="checkbox" />
      Group by Product
    </label>
  );
}

function ProductChip({ scope, title }: { scope: OrderScope; title: string }) {
  return (
    <Link
      aria-label={`Remove ${title} from the Product filter`}
      className="sales_tag inline-flex w-fit items-center gap-1 hover:brightness-95"
      data-color="sky"
      href={issuePath({ issue_type: "sale_items", scope })}
    >
      Product: {title}
      <XIcon aria-hidden className="size-3" />
    </Link>
  );
}

function OrderRows({ issues, scope }: Pick<OrderIssuesProps, "issues" | "scope">) {
  if (issues.length === 0) {
    return (
      <p className="py-12 text-center text-gray-500 dark:text-gray-400">
        {scopes.find((option) => option.scope === scope)?.empty}
      </p>
    );
  }

  return <OrderTable issues={issues} />;
}

function OrderTable({ issues }: { issues: AssignmentIssue[] }) {
  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Order</th>
            <th>Status</th>
            <th>Customer</th>
            <th>Amount</th>
            <th>Product</th>
            <th>Variant</th>
            <th>Impact</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isOrderIssue(issue) ? <OrderRow issue={issue} key={issue.id} /> : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function OrderRow({ issue }: { issue: SaleItemAssignmentIssue }) {
  return (
    <tr aria-label={issue.reference}>
      <td>
        <OrderTitle
          path={issue.record_path}
          storeType={issue.store_type}
          title={issue.order_title}
        />
      </td>
      <td>{issue.status}</td>
      <td>{issue.customer_name}</td>
      <td className="font-mono">{issue.amount}</td>
      <td>{issue.product_title}</td>
      <VariantRepairCell issue={issue} />
      <td>
        <div className="flex flex-col gap-1">
          {issue.consequences.length > 0 && (
            <ul aria-label="Impact" className="flex flex-col gap-1">
              {issue.consequences.map((consequence) => (
                <li key={consequence.kind}>{consequence.text}</li>
              ))}
            </ul>
          )}
          {issue.import_failure && (
            <OrderImportError
              failure={issue.import_failure}
              name={orderName(issue.store_type, issue.order_title)}
            />
          )}
        </div>
      </td>
    </tr>
  );
}

function OrderImportError({ failure, name }: { failure: OrderImportFailure; name: string }) {
  return (
    <div className="flex flex-col gap-1">
      <small>{failure.message}</small>
      <ImportFailureActions
        orderName={name}
        pullPath={failure.pull_path}
        sentryUrl={failure.sentry_url}
      />
    </div>
  );
}

function isOrderIssue(issue: AssignmentIssue): issue is SaleItemAssignmentIssue {
  return issue.kind === "sale_item";
}
