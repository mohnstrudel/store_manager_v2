import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { FranchiseRecord } from "../types";

type TableProps = {
  franchises: FranchiseRecord[];
};

export default function Table({ franchises }: TableProps) {
  function visitFranchise(franchise: FranchiseRecord) {
    router.visit(`/franchises/${franchise.id}`);
  }

  function handleKeyDown(franchise: FranchiseRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitFranchise(franchise);
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
        {franchises.map((franchise) => (
          <tr
            className="hoverable"
            key={franchise.id}
            onClick={() => visitFranchise(franchise)}
            onKeyDown={(event) => handleKeyDown(franchise, event)}
            tabIndex={0}
          >
            <td>{franchise.id}</td>
            <td>{franchise.title}</td>
            <td>{franchise.created_at}</td>
            <td>{franchise.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/franchises/${franchise.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/franchises/${franchise.id}/edit`} onClick={stopRowNavigation}>
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
