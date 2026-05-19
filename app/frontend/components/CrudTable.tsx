import { router } from "@inertiajs/react";
import type { KeyboardEvent, ReactNode } from "react";
import Link from "@/components/Link";

type CrudTableColumn<T> = {
  header: string;
  render: (row: T) => ReactNode;
  className?: string;
};

type CrudTableAction<T> = {
  href: (row: T) => string;
  icon: ReactNode;
  label: string;
};

type CrudTableProps<T> = {
  actions?: CrudTableAction<T>[];
  columns: CrudTableColumn<T>[];
  rowHref?: (row: T) => string;
  rowClassName?: (row: T) => string | undefined;
  rowKey: (row: T) => number | string;
  rows: T[];
};

export default function CrudTable<T>({
  actions = [],
  columns,
  rowClassName,
  rowHref,
  rowKey,
  rows,
}: CrudTableProps<T>) {
  function visitRow(row: T) {
    if (!rowHref) return;

    router.visit(rowHref(row));
  }

  function handleRowKeyDown(row: T, event: KeyboardEvent<HTMLTableRowElement>) {
    if (!rowHref) return;
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      visitRow(row);
    }
  }

  return (
    <table role="grid">
      <thead>
        <tr>
          {columns.map((column) => (
            <th className={column.className} key={column.header}>
              {column.header}
            </th>
          ))}
          {actions.length > 0 ? <th className="text-right">Actions</th> : null}
        </tr>
      </thead>
      <tbody>
        {rows.map((row) => (
          <tr
            className={rowClassName?.(row)}
            key={rowKey(row)}
            onClick={() => visitRow(row)}
            onKeyDown={(event) => handleRowKeyDown(row, event)}
            tabIndex={rowHref ? 0 : undefined}
          >
            {columns.map((column) => (
              <td className={column.className} key={column.header}>
                {column.render(row)}
              </td>
            ))}
            {actions.length > 0 ? (
              <td className="actions">
                {actions.map((action) => (
                  <Link
                    href={action.href(row)}
                    key={action.label}
                    onClick={(event) => event.stopPropagation()}
                  >
                    {action.icon}
                    {action.label}
                  </Link>
                ))}
              </td>
            ) : null}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
