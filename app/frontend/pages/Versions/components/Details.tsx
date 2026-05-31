import { VersionRecord } from "../types";

type DetailsProps = {
  version: VersionRecord;
};

export default function Details({ version }: DetailsProps) {
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
            <td>{version.id}</td>
            <td>{version.value}</td>
            <td>{version.created_at}</td>
            <td>{version.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
