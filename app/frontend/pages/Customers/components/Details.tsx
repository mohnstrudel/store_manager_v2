import { emptyToNull } from "@/utils/emptyValue";

import { CustomerDetailRecord } from "../types";

type DetailsProps = {
  customer: CustomerDetailRecord;
};

export default function Details({ customer }: DetailsProps) {
  return (
    <section className="section_border_base">
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
                  <span className="inline-block icon_shopify w-5 h-5 mr-1 -mb-1" />
                  {customer.shopify_id_short}
                </span>
              )}
              {customer.woo_store_id && (
                <span className="block">
                  <span className="inline-block icon_woo w-8 h-8 mr-2 -mb-3" />
                  {customer.woo_store_id}
                </span>
              )}
            </td>
            <td>{emptyToNull(customer.first_name)}</td>
            <td>{emptyToNull(customer.last_name)}</td>
            <td>{emptyToNull(customer.email)}</td>
            <td>{emptyToNull(customer.phone)}</td>
            <td>{emptyToNull(customer.created_at)}</td>
            <td>{emptyToNull(customer.updated_at)}</td>
          </tr>
        </tbody>
      </table>
    </section>
  );
}
