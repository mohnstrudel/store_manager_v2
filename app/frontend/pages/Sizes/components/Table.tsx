import type { MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { rowNavigationProps } from "@/lib/rowNavigation";
import { SizeRecord } from "../types";

type TableProps = {
  sizes: SizeRecord[];
};

function stopRowNavigation(event: MouseEvent) {
  event.stopPropagation();
}

export default function Table({ sizes }: TableProps) {
  return (
    <table role="grid">
      <thead>
        <tr>
          <th>ID</th>
          <th>Value</th>
          <th>Created</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {sizes.map((size) => (
          <tr className="hoverable" key={size.id} {...rowNavigationProps(`/sizes/${size.id}`)}>
            <td>{size.id}</td>
            <td>{size.value}</td>
            <td>{size.created_at}</td>
            <td>{size.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/sizes/${size.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/sizes/${size.id}/edit`} onClick={stopRowNavigation}>
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
