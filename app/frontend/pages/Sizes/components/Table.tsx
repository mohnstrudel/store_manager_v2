import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { SizeRecord } from "../types";

type TableProps = {
  sizes: SizeRecord[];
};

export default function Table({ sizes }: TableProps) {
  function visitSize(size: SizeRecord) {
    router.visit(`/sizes/${size.id}`);
  }

  function handleKeyDown(size: SizeRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitSize(size);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

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
          <tr
            className="hoverable"
            key={size.id}
            onClick={() => visitSize(size)}
            onKeyDown={(event) => handleKeyDown(size, event)}
            tabIndex={0}
          >
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
