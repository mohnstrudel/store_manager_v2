import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { ShippingCompanyRecord } from "../types";

type TableProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Table({ shippingCompanies }: TableProps) {
  function visitShippingCompany(shippingCompany: ShippingCompanyRecord) {
    router.visit(`/shipping_companies/${shippingCompany.id}`);
  }

  function handleKeyDown(
    shippingCompany: ShippingCompanyRecord,
    event: KeyboardEvent<HTMLTableRowElement>
  ) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitShippingCompany(shippingCompany);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  return (
    <table role="grid">
      <thead>
        <tr>
          <th>ID</th>
          <th>Name</th>
          <th>Tracking URL</th>
          <th>Created</th>
          <th>Updated</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {shippingCompanies.map((shippingCompany) => (
          <tr
            className="hoverable"
            key={shippingCompany.id}
            onClick={() => visitShippingCompany(shippingCompany)}
            onKeyDown={(event) => handleKeyDown(shippingCompany, event)}
            tabIndex={0}
          >
            <td>{shippingCompany.id}</td>
            <td>{shippingCompany.name}</td>
            <td>
              {shippingCompany.tracking_url ? (
                <a
                  className="link"
                  href={shippingCompany.tracking_url}
                  onClick={stopRowNavigation}
                  rel="noopener"
                  target="_blank"
                >
                  {shippingCompany.tracking_url}
                </a>
              ) : (
                ""
              )}
            </td>
            <td>{shippingCompany.created_at}</td>
            <td>{shippingCompany.updated_at}</td>
            <td className="actions text-right">
              <div className="flex flex-wrap justify-end gap-3">
                <Link
                  href={`/shipping_companies/${shippingCompany.id}`}
                  onClick={stopRowNavigation}
                >
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link
                  href={`/shipping_companies/${shippingCompany.id}/edit`}
                  onClick={stopRowNavigation}
                >
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
