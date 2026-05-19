import CrudTable from "@/components/CrudTable";
import { FranchiseRecord } from "../types";

type TableProps = {
  franchises: FranchiseRecord[];
};

export default function Table({ franchises }: TableProps) {
  const columns = [
    { header: "ID", render: (franchise: FranchiseRecord) => franchise.id },
    { header: "Title", render: (franchise: FranchiseRecord) => franchise.title },
    { header: "Created", render: (franchise: FranchiseRecord) => franchise.created_at },
    { header: "Updated", render: (franchise: FranchiseRecord) => franchise.updated_at },
  ];

  const actions = [
    {
      href: (franchise: FranchiseRecord) => `/franchises/${franchise.id}`,
      icon: <i className="icn">📄</i>,
      label: "Show",
    },
    {
      href: (franchise: FranchiseRecord) => `/franchises/${franchise.id}/edit`,
      icon: <i className="icn">✏</i>,
      label: "Edit",
    },
  ];

  return (
    <CrudTable
      actions={actions}
      columns={columns}
      rowHref={(franchise) => `/franchises/${franchise.id}`}
      rowKey={(franchise) => franchise.id ?? "new"}
      rows={franchises}
    />
  );
}
