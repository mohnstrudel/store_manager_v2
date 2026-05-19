import CrudTable from "@/components/CrudTable";
import { SizeRecord } from "../types";

type TableProps = {
  sizes: SizeRecord[];
};

export default function Table({ sizes }: TableProps) {
  const columns = [
    { header: "ID", render: (size: SizeRecord) => size.id },
    { header: "Value", render: (size: SizeRecord) => size.value },
    { header: "Created", render: (size: SizeRecord) => size.created_at },
    { header: "Updated", render: (size: SizeRecord) => size.updated_at },
  ];

  const actions = [
    {
      href: (size: SizeRecord) => `/sizes/${size.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (size: SizeRecord) => `/sizes/${size.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(size) => `/sizes/${size.id}`}
      rowKey={(size) => size.id ?? "new"}
      rows={sizes}
    />
  );
}
