import { Link } from "@inertiajs/react";
import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { BrandRecord } from "../types";

type TableProps = {
  brands: BrandRecord[];
};

export default function Table({ brands }: TableProps) {
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
        {brands.map((brand) => {
          const showPath =
            brand.id === null
              ? routes.brands.index.path()
              : routes.brands.show.path({ id: brand.id });
          const editPath =
            brand.id === null
              ? routes.brands.new.path()
              : routes.brands.edit.path({ id: brand.id });

          return (
            <tr className="hoverable" key={brand.id} {...rowNavigationProps(showPath)}>
              <td>{brand.id}</td>
              <td>{brand.title}</td>
              <td>{brand.created_at}</td>
              <td>{brand.updated_at}</td>
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
