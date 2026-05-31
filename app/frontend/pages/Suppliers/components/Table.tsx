import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
import { SupplierRecord } from "../types";

type TableProps = {
  suppliers: SupplierRecord[];
};

export default function Table({ suppliers }: TableProps) {
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
            {...rowNavigationProps(`/suppliers/${supplier.id}`)}
          >
            <td>{supplier.id}</td>
            <td>{supplier.title}</td>
            <td>{supplier.created_at}</td>
            <td>{supplier.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/suppliers/${supplier.id}`} onClick={stopRowNavigation} prefetch>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/suppliers/${supplier.id}/edit`} onClick={stopRowNavigation} prefetch>
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
