import { Link } from "@inertiajs/react";
import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { SizeRecord } from "../types";

type TableProps = {
  sizes: SizeRecord[];
};

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
        {sizes.map((size) => {
          const showPath =
            size.id === null ? routes.sizes.index.path() : routes.sizes.show.path({ id: size.id });
          const editPath =
            size.id === null ? routes.sizes.new.path() : routes.sizes.edit.path({ id: size.id });

          return (
            <tr className="hoverable" key={size.id} {...rowNavigationProps(showPath)}>
              <td>{size.id}</td>
              <td>{size.value}</td>
              <td>{size.created_at}</td>
              <td>{size.updated_at}</td>
              <td className="table_actions text-right">
                <div className="flex flex-wrap justify-end gap-3">
                  <Link href={showPath} onClick={stopRowNavigation} prefetch>
                    <i className="icn">📄</i>
                    Show
                  </Link>
                  <Link href={editPath} onClick={stopRowNavigation} prefetch>
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
