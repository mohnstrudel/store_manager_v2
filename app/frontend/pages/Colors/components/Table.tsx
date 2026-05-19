import CrudTable from "@/components/CrudTable";
import { ColorRecord } from "../types";

type TableProps = {
  colors: ColorRecord[];
};

export default function Table({ colors }: TableProps) {
  const columns = [
    { header: "ID", render: (color: ColorRecord) => color.id },
    { header: "Value", render: (color: ColorRecord) => color.value },
    { header: "Created", render: (color: ColorRecord) => color.created_at },
    { header: "Updated", render: (color: ColorRecord) => color.updated_at },
  ];

  const actions = [
    {
      href: (color: ColorRecord) => `/colors/${color.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (color: ColorRecord) => `/colors/${color.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(color) => `/colors/${color.id}`}
      rowKey={(color) => color.id ?? "new"}
      rows={colors}
    />
  );
}
