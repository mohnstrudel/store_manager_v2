import CrudTable from "@/components/CrudTable";
import { ShippingCompanyRecord } from "../types";

type TableProps = {
  shippingCompanies: ShippingCompanyRecord[];
};

export default function Table({ shippingCompanies }: TableProps) {
  const columns = [
    { header: "ID", render: (shippingCompany: ShippingCompanyRecord) => shippingCompany.id },
    { header: "Name", render: (shippingCompany: ShippingCompanyRecord) => shippingCompany.name },
    {
      header: "Tracking URL",
      render: (shippingCompany: ShippingCompanyRecord) =>
        shippingCompany.tracking_url ? (
          <a
            className="link"
            href={shippingCompany.tracking_url}
            onClick={(event) => event.stopPropagation()}
            rel="noopener"
            target="_blank"
          >
            {shippingCompany.tracking_url}
          </a>
        ) : (
          ""
        ),
    },
    { header: "Created", render: (shippingCompany: ShippingCompanyRecord) => shippingCompany.created_at },
    { header: "Updated", render: (shippingCompany: ShippingCompanyRecord) => shippingCompany.updated_at },
  ];

  const actions = [
    {
      href: (shippingCompany: ShippingCompanyRecord) => `/shipping_companies/${shippingCompany.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (shippingCompany: ShippingCompanyRecord) => `/shipping_companies/${shippingCompany.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(shippingCompany) => `/shipping_companies/${shippingCompany.id}`}
      rowKey={(shippingCompany) => shippingCompany.id ?? "new"}
      rows={shippingCompanies}
    />
  );
}
