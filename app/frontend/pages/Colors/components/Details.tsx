import { ColorRecord } from "../types";

type DetailsProps = {
  color: ColorRecord;
};

export default function Details({ color }: DetailsProps) {
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
            <td>{color.id}</td>
            <td>{color.value}</td>
            <td>{color.created_at}</td>
            <td>{color.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
