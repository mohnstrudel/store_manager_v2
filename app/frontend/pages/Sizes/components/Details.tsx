import { SizeRecord } from "../types";

type DetailsProps = {
  size: SizeRecord;
};

export default function Details({ size }: DetailsProps) {
  return (
    <div className="table_card">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Value</th>
            <th>Created</th>
            <th>Updated</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{size.id}</td>
            <td>{size.value}</td>
            <td>{size.created_at}</td>
            <td>{size.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
