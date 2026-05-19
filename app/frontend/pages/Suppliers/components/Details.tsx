import { SupplierRecord } from "../types";

type DetailsProps = {
  supplier: SupplierRecord;
};

export default function Details({ supplier }: DetailsProps) {
  return (
    <div className="table-card">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Title</th>
            <th>Created</th>
            <th>Updated</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{supplier.id}</td>
            <td>{supplier.title}</td>
            <td>{supplier.created_at}</td>
            <td>{supplier.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
