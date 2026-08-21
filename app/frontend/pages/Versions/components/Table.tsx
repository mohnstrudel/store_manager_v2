import { Link } from "@inertiajs/react";

import routes from "@/utils/routes";
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
        {versions.map((version) => {
          const currentVersionPath = routes.versions.show.path({
            id: version.id!,
          });
          const currentEditPath = routes.versions.edit.path({
            id: version.id!,
          });

          return (
            <tr className="hoverable" key={version.id} {...rowNavigationProps(currentVersionPath)}>
              <td>{version.id}</td>
              <td>{version.value}</td>
              <td>{version.created_at}</td>
              <td>{version.updated_at}</td>
              <td className="table_actions text-right">
                <div className="flex flex-wrap justify-end gap-2">
                  <Link href={currentVersionPath} onClick={stopRowNavigation} prefetch>
                    <i className="icn">📄</i>
                    Show
                  </Link>
                  <Link href={currentEditPath} onClick={stopRowNavigation} prefetch>
                    <i className="icn">✏</i>
                    Edit
                  </Link>
                </div>
              </td>
            </tr>
          );
        })}
      </tbody>
    </table>
  );
}
