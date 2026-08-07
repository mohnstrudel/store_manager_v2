import { Link } from "@inertiajs/react";
import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { ColorRecord } from "../types";

type TableProps = {
  colors: ColorRecord[];
};

export default function Table({ colors }: TableProps) {
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
        {colors.map((color) => {
          const showPath =
            color.id === null
              ? routes.colors.index.path()
              : routes.colors.show.path({ id: color.id });
          const editPath =
            color.id === null
              ? routes.colors.new.path()
              : routes.colors.edit.path({ id: color.id });

          return (
            <tr className="hoverable" key={color.id} {...rowNavigationProps(showPath)}>
              <td>{color.id}</td>
              <td>{color.value}</td>
              <td>{color.created_at}</td>
              <td>{color.updated_at}</td>
              <td className="table_actions text-right">
                <div className="flex flex-wrap justify-end gap-2">
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
