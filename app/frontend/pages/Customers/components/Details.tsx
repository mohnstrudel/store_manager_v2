import { CustomerDetailRecord } from "../types";

type DetailsProps = {
  customer: CustomerDetailRecord;
};

export default function Details({ customer }: DetailsProps) {
  return (
    <section className="section-border-base">
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Store ID</th>
            <th>First Name</th>
            <th>Last Name</th>
            <th>Email</th>
            <th>Phone</th>
            <th>Created</th>
            <th>Updated</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{customer.id}</td>
            <td>
              {customer.shopify_id_short && (
                <span className="block">
                  <span className="inline-block icon-shopify w-5 h-5 mr-1 -mb-1" />
                  {customer.shopify_id_short}
                </span>
              )}
              {customer.woo_store_id && (
                <span className="block">
                  <span className="inline-block icon-woo w-8 h-8 mr-2 -mb-3" />
                  {customer.woo_store_id}
                </span>
              )}
              {!customer.shopify_id_short && !customer.woo_store_id && "-"}
            </td>
            <td>{customer.first_name || "-"}</td>
            <td>{customer.last_name || "-"}</td>
            <td>{customer.email || "-"}</td>
            <td>{customer.phone || "-"}</td>
            <td>{customer.created_at || "-"}</td>
            <td>{customer.updated_at || "-"}</td>
          </tr>
        </tbody>
      </table>
    </section>
  );
}
