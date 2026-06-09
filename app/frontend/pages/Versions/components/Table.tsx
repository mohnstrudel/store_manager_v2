import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { VersionRecord } from "../types";

type TableProps = {
  versions: VersionRecord[];
};

export default function Table({ versions }: TableProps) {
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
            {...rowNavigationProps(`/versions/${version.id}`)}
          >
            <td>{version.id}</td>
            <td>{version.value}</td>
            <td>{version.created_at}</td>
            <td>{version.updated_at}</td>
            <td className="table_actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/versions/${version.id}`} onClick={stopRowNavigation} prefetch>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/versions/${version.id}/edit`} onClick={stopRowNavigation} prefetch>
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
