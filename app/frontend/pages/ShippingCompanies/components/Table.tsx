import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { ShippingCompanyRecord } from "../types";

type TableProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Table({ shippingCompanies }: TableProps) {
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
            {...rowNavigationProps(`/shipping_companies/${shippingCompany.id}`)}
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
            <td className="table_actions text-right">
              <div className="flex flex-wrap justify-end gap-2">
                <Link
                  href={`/shipping_companies/${shippingCompany.id}`}
                  onClick={stopRowNavigation}
                  prefetch
                >
                  <i className="icn">📄</i>
                  Show
                </Link>
                <Link
                  href={`/shipping_companies/${shippingCompany.id}/edit`}
                  onClick={stopRowNavigation}
                  prefetch
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
