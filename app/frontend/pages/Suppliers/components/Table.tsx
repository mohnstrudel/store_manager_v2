import CrudTable from "@/components/CrudTable";
import { SupplierRecord } from "../types";

type TableProps = {
  suppliers: SupplierRecord[];
};

export default function Table({ suppliers }: TableProps) {
  const columns = [
    { header: "ID", render: (supplier: SupplierRecord) => supplier.id },
    { header: "Title", render: (supplier: SupplierRecord) => supplier.title },
    { header: "Created", render: (supplier: SupplierRecord) => supplier.created_at },
    { header: "Updated", render: (supplier: SupplierRecord) => supplier.updated_at },
  ];

  const actions = [
    {
      href: (supplier: SupplierRecord) => `/suppliers/${supplier.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (supplier: SupplierRecord) => `/suppliers/${supplier.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(supplier) => `/suppliers/${supplier.id}`}
      rowKey={(supplier) => supplier.id ?? "new"}
      rows={suppliers}
    />
  );
}
