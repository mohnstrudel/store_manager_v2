import { FranchiseRecord } from "../types";

type DetailsProps = {
  franchise: FranchiseRecord;
};

export default function Details({ franchise }: DetailsProps) {
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
            <td>{franchise.id}</td>
            <td>{franchise.title}</td>
            <td>{franchise.created_at}</td>
            <td>{franchise.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
