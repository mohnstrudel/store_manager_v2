import { BrandRecord } from "../types";

type DetailsProps = {
  brand: BrandRecord;
};

export default function Details({ brand }: DetailsProps) {
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
            <td>{brand.id}</td>
            <td>{brand.title}</td>
            <td>{brand.created_at}</td>
            <td>{brand.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
