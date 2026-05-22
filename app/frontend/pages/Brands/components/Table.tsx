import type { MouseEvent } from "react";
import { Link } from "@inertiajs/react";
import { rowNavigationProps } from "@/lib/rowNavigation";
import { BrandRecord } from "../types";

type TableProps = {
  brands: BrandRecord[];
};

function stopRowNavigation(event: MouseEvent) {
  event.stopPropagation();
}

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
        {brands.map((brand) => (
          <tr className="hoverable" key={brand.id} {...rowNavigationProps(`/brands/${brand.id}`)}>
            <td>{brand.id}</td>
            <td>{brand.title}</td>
            <td>{brand.created_at}</td>
            <td>{brand.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/brands/${brand.id}`} onClick={stopRowNavigation} prefetch>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/brands/${brand.id}/edit`} onClick={stopRowNavigation} prefetch>
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
