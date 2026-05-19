import {
  flexRender,
  getCoreRowModel,
  useReactTable,
  type ColumnDef,
} from "@tanstack/react-table";
import { router } from "@inertiajs/react";
import Link from "@/components/Link";
import { CustomerRecord } from "../types";

const EMPTY_ICONS = ["👻", "👽", "💩", "🪆", "🎭"] as const;

type TableProps = {
  customers: CustomerRecord[];
};

const columns: ColumnDef<CustomerRecord>[] = [
  {
    id: "woo_store_id",
    header: "Woo ID",
    cell: ({ row }) => row.original.woo_store_id || "-",
  },
  {
    id: "full_name",
    header: "Full name",
    cell: ({ row }) => row.original.full_name || "-",
  },
  {
    id: "email",
    header: "Email",
    cell: ({ row }) => row.original.email || "-",
  },
  {
    id: "phone",
    header: "Phone",
    cell: ({ row }) => row.original.phone || "-",
  },
  {
    id: "actions",
    header: "Actions",
    meta: { className: "text-right", isActions: true },
    cell: ({ row }) => (
      <Link
        href={`/customers/${row.original.id}/edit`}
        onClick={(e) => e.stopPropagation()}
      >
        <i className="icn">✏</i>
        Edit
      </Link>
    ),
  },
];

export default function Table({ customers }: TableProps) {
  const table = useReactTable({
    data: customers,
    columns,
    getCoreRowModel: getCoreRowModel(),
    getRowId: (row) => String(row.id),
  });

  function visitRow(customer: CustomerRecord) {
    router.visit(`/customers/${customer.id}`);
  }

  if (customers.length === 0) {
    const icon = EMPTY_ICONS[Math.floor(Math.random() * EMPTY_ICONS.length)];
    return (
      <div className="search-results--empty flex flex-col justify-center items-center h-100">
        <i className="icn text-[180px]">{icon}</i>
        <h2 className="text-center">Nothing found</h2>
      </div>
    );
  }

  return (
    <table data-controller="table" role="grid">
      <thead>
        {table.getHeaderGroups().map((headerGroup) => (
          <tr key={headerGroup.id}>
            {headerGroup.headers.map((header) => (
              <th
                className={
                  header.column.columnDef.meta?.isActions
                    ? "text-right"
                    : header.column.columnDef.meta?.className
                }
                key={header.id}
              >
                {flexRender(header.column.columnDef.header, header.getContext())}
              </th>
            ))}
          </tr>
        ))}
      </thead>
      <tbody>
        {table.getRowModel().rows.map((row) => (
          <tr
            className="hoverable"
            key={row.id}
            onClick={() => visitRow(row.original)}
            onKeyDown={(e) => {
              if (e.key === "Enter" || e.key === " ") {
                e.preventDefault();
                visitRow(row.original);
              }
            }}
            tabIndex={0}
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
