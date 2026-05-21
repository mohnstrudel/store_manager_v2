import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { SupplierRecord } from "../types";

type TableProps = {
  suppliers: SupplierRecord[];
};

export default function Table({ suppliers }: TableProps) {
  function visitSupplier(supplier: SupplierRecord) {
    router.visit(`/suppliers/${supplier.id}`);
  }

  function handleKeyDown(supplier: SupplierRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitSupplier(supplier);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  return (
    <table role="grid">
      <thead>
        <tr>
          <th>ID</th>
          <th>Title</th>
          <th>Created</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {suppliers.map((supplier) => (
          <tr
            className="hoverable"
            key={supplier.id}
            onClick={() => visitSupplier(supplier)}
            onKeyDown={(event) => handleKeyDown(supplier, event)}
            tabIndex={0}
          >
            <td>{supplier.id}</td>
            <td>{supplier.title}</td>
            <td>{supplier.created_at}</td>
            <td>{supplier.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/suppliers/${supplier.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/suppliers/${supplier.id}/edit`} onClick={stopRowNavigation}>
                  <i className="icn">✏</i>
                  Edit
                </Link>
              </div>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
