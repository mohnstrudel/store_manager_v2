import { ShippingCompanyRecord } from "../types";

type DetailsProps = {
  shippingCompany: ShippingCompanyRecord;
};

export default function Details({ shippingCompany }: DetailsProps) {
  return (
    <div className="table-card">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Tracking URL</th>
            <th>Created</th>
            <th>Updated</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{shippingCompany.id}</td>
            <td>{shippingCompany.name}</td>
            <td>
              {shippingCompany.tracking_url ? (
                <a
                  className="link"
                  href={shippingCompany.tracking_url}
                  rel="noopener"
                  target="_blank"
                >
                  {shippingCompany.tracking_url}
                </a>
              ) : (
                ""
              )}
            </td>
            <td>{shippingCompany.created_at}</td>
            <td>{shippingCompany.updated_at}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
}
