import type { AssignmentIssue, ImportFailureRow } from "../types";
import ImportFailureActions from "./ImportFailureActions";
import OrderTitle, { orderName } from "./OrderTitle";

export default function ImportFailures({ issues }: { issues: AssignmentIssue[] }) {
  if (issues.length === 0) {
    return (
      <p className="py-12 text-center text-gray-500 dark:text-gray-400">
        No orders are failing to import
      </p>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table>
        <thead>
          <tr>
            <th>Order</th>
            <th>Error</th>
            <th>First failure</th>
            <th>Last failure</th>
            <th>Failures</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          {issues.map((issue) =>
            isImportFailure(issue) ? (
              <ImportFailureTableRow failure={issue} key={issue.id} />
            ) : null,
          )}
        </tbody>
      </table>
    </div>
  );
}

function ImportFailureTableRow({ failure }: { failure: ImportFailureRow }) {
  const name = orderName(failure.store_type, failure.order_title);

  return (
    <tr aria-label={name}>
      <td>
        <OrderTitle
          path={failure.record_path}
          storeType={failure.store_type}
          title={failure.order_title}
        />
      </td>
      <td>{failure.message}</td>
      <td>{failure.first_failed_at}</td>
      <td>{failure.last_failed_at}</td>
      <td>{failure.failure_count}</td>
      <td>
        <ImportFailureActions
          orderName={name}
          pullPath={failure.pull_path}
          sentryUrl={failure.sentry_url}
        />
      </td>
    </tr>
  );
}

function isImportFailure(issue: AssignmentIssue): issue is ImportFailureRow {
  return issue.kind === "import_failure";
}
