import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/lib/rowNavigation";
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
        {colors.map((color) => (
          <tr className="hoverable" key={color.id} {...rowNavigationProps(`/colors/${color.id}`)}>
            <td>{color.id}</td>
            <td>{color.value}</td>
            <td>{color.created_at}</td>
            <td>{color.updated_at}</td>
            <td className="table_actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/colors/${color.id}`} onClick={stopRowNavigation} prefetch>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/colors/${color.id}/edit`} onClick={stopRowNavigation} prefetch>
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
