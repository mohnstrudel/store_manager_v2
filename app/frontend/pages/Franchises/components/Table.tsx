import type { MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { rowNavigationProps } from "@/lib/rowNavigation";
import { FranchiseRecord } from "../types";

type TableProps = {
  franchises: FranchiseRecord[];
};

function stopRowNavigation(event: MouseEvent) {
  event.stopPropagation();
}

export default function Table({ franchises }: TableProps) {
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
        {franchises.map((franchise) => (
          <tr
            className="hoverable"
            key={franchise.id}
            {...rowNavigationProps(`/franchises/${franchise.id}`)}
          >
            <td>{franchise.id}</td>
            <td>{franchise.title}</td>
            <td>{franchise.created_at}</td>
            <td>{franchise.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/franchises/${franchise.id}`} onClick={stopRowNavigation} prefetch>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link
                  href={`/franchises/${franchise.id}/edit`}
                  onClick={stopRowNavigation}
                  prefetch
                >
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
