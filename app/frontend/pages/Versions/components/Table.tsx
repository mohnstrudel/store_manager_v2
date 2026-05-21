import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { VersionRecord } from "../types";

type TableProps = {
  versions: VersionRecord[];
};

export default function Table({ versions }: TableProps) {
  function visitVersion(version: VersionRecord) {
    router.visit(`/versions/${version.id}`);
  }

  function handleKeyDown(version: VersionRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitVersion(version);
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
        {versions.map((version) => (
          <tr
            className="hoverable"
            key={version.id}
            onClick={() => visitVersion(version)}
            onKeyDown={(event) => handleKeyDown(version, event)}
            tabIndex={0}
          >
            <td>{version.id}</td>
            <td>{version.value}</td>
            <td>{version.created_at}</td>
            <td>{version.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/versions/${version.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/versions/${version.id}/edit`} onClick={stopRowNavigation}>
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
