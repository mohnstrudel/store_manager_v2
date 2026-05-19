import CrudTable from "@/components/CrudTable";
import { BrandRecord } from "../types";

type TableProps = {
  brands: BrandRecord[];
};

export default function Table({ brands }: TableProps) {
  const columns = [
    { header: "ID", render: (brand: BrandRecord) => brand.id },
    { header: "Title", render: (brand: BrandRecord) => brand.title },
    { header: "Created", render: (brand: BrandRecord) => brand.created_at },
    { header: "Updated", render: (brand: BrandRecord) => brand.updated_at },
  ];

  const actions = [
    {
      href: (brand: BrandRecord) => `/brands/${brand.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (brand: BrandRecord) => `/brands/${brand.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(brand) => `/brands/${brand.id}`}
      rowKey={(brand) => brand.id ?? "new"}
      rows={brands}
    />
  );
}
