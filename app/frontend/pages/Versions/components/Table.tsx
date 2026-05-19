import CrudTable from "@/components/CrudTable";
import { VersionRecord } from "../types";

type TableProps = {
  versions: VersionRecord[];
};

export default function Table({ versions }: TableProps) {
  const columns = [
    { header: "ID", render: (version: VersionRecord) => version.id },
    { header: "Value", render: (version: VersionRecord) => version.value },
    { header: "Created", render: (version: VersionRecord) => version.created_at },
    { header: "Updated", render: (version: VersionRecord) => version.updated_at },
  ];

  const actions = [
    {
      href: (version: VersionRecord) => `/versions/${version.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (version: VersionRecord) => `/versions/${version.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(version) => `/versions/${version.id}`}
      rowKey={(version) => version.id ?? "new"}
      rows={versions}
    />
  );
}
