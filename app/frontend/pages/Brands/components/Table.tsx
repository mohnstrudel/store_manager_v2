import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { BrandRecord } from "../types";

type TableProps = {
  brands: BrandRecord[];
};

export default function Table({ brands }: TableProps) {
  function visitBrand(brand: BrandRecord) {
    router.visit(`/brands/${brand.id}`);
  }

  function handleKeyDown(brand: BrandRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitBrand(brand);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

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
          <tr
            className="hoverable"
            key={brand.id}
            onClick={() => visitBrand(brand)}
            onKeyDown={(event) => handleKeyDown(brand, event)}
            tabIndex={0}
          >
            <td>{brand.id}</td>
            <td>{brand.title}</td>
            <td>{brand.created_at}</td>
            <td>{brand.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link href={`/brands/${brand.id}`} onClick={stopRowNavigation}>
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link href={`/brands/${brand.id}/edit`} onClick={stopRowNavigation}>
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
