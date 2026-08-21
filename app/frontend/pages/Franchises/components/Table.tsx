import { Link } from "@inertiajs/react";

import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";

import { FranchiseRecord } from "../types";

type TableProps = {
  franchises: FranchiseRecord[];
};

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
        {franchises.map((franchise) => {
          const currentFranchisePath =
            franchise.id === null
              ? routes.franchises.index.path()
              : routes.franchises.show.path({ id: franchise.id });
          const currentEditPath =
            franchise.id === null
              ? routes.franchises.new.path()
              : routes.franchises.edit.path({ id: franchise.id });

          return (
            <tr
              className="hoverable"
              key={franchise.id}
              {...rowNavigationProps(currentFranchisePath)}
            >
              <td>{franchise.id}</td>
              <td>{franchise.title}</td>
              <td>{franchise.created_at}</td>
              <td>{franchise.updated_at}</td>
              <td className="table_actions text-right">
                <div className="flex flex-wrap justify-end gap-2">
                  <Link href={currentFranchisePath} onClick={stopRowNavigation} prefetch>
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
