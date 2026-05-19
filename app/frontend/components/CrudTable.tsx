import {
  flexRender,
  getCoreRowModel,
  useReactTable,
  type ColumnDef,
  type Row,
  type RowData,
} from "@tanstack/react-table";
import type { KeyboardEvent, ReactNode } from "react";
import { router } from "@inertiajs/react";
import Link from "@/components/Link";

declare module "@tanstack/react-table" {
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  interface ColumnMeta<TData extends RowData, TValue> {
    className?: string;
    isActions?: boolean;
  }
}

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

type CrudTableProps<T extends object> = {
  actions?: CrudTableAction<T>[];
  columns: CrudTableColumn<T>[];
  rowHref?: (row: T) => string;
  rowClassName?: (row: T) => string | undefined;
  rowKey: (row: T) => number | string;
  rows: T[];
};

export default function CrudTable<T extends object>({
  actions = [],
  columns,
  rowClassName,
  rowHref,
  rowKey,
  rows,
}: CrudTableProps<T>) {
  const tanstackColumns: ColumnDef<T>[] = [
    ...columns.map<ColumnDef<T>>((col) => ({
      id: col.header,
      header: col.header,
      cell: ({ row }: { row: Row<T> }) => col.render(row.original),
      meta: { className: col.className },
    })),
    ...(actions.length > 0
      ? [
          {
            id: "__actions__",
            header: "Actions",
            cell: ({ row }: { row: Row<T> }) =>
              actions.map((action) => (
                <Link
                  href={action.href(row.original)}
                  key={action.label}
                  onClick={(event) => event.stopPropagation()}
                >
                  {action.icon}
                  {action.label}
                </Link>
              )),
            meta: { className: "text-right", isActions: true },
          } as ColumnDef<T>,
        ]
      : []),
  ];

  const table = useReactTable({
    data: rows,
    columns: tanstackColumns,
    getCoreRowModel: getCoreRowModel(),
    getRowId: (row) => String(rowKey(row)),
  });

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
        {table.getHeaderGroups().map((headerGroup) => (
          <tr key={headerGroup.id}>
            {headerGroup.headers.map((header) => (
              <th className={header.column.columnDef.meta?.className} key={header.id}>
                {flexRender(header.column.columnDef.header, header.getContext())}
              </th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.map((row) => (
          <tr
            className={rowClassName?.(row.original)}
            key={row.id}
            onClick={() => visitRow(row.original)}
            onKeyDown={(event) => handleRowKeyDown(row.original, event)}
            tabIndex={rowHref ? 0 : undefined}
          >
            {row.getVisibleCells().map((cell) => (
              <td
                className={
                  cell.column.columnDef.meta?.isActions
                    ? "actions"
                    : cell.column.columnDef.meta?.className
                }
                key={cell.id}
              >
                {flexRender(cell.column.columnDef.cell, cell.getContext())}
              </td>
            ))}
          </tr>
        ))}
      </tbody>
    </table>
  );
}
