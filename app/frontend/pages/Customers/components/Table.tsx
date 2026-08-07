import { Link } from "@inertiajs/react";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { emptyToNull } from "@/utils/emptyValue";
import { CustomerRecord } from "../types";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";

type TableProps = {
  customers: CustomerRecord[];
  searchQuery?: string;
};

export default function Table({ customers, searchQuery = "" }: TableProps) {
  if (customers.length === 0) {
    return searchQuery ? <SearchResultsEmpty seed={searchQuery} /> : null;
  }

  return (
    <table role="grid">
      <thead>
        <tr>
          <th>Woo ID</th>
          <th>Full name</th>
          <th>Email</th>
          <th>Phone</th>
          <th className="text-right">Actions</th>
        </tr>
      </thead>
      <tbody>
        {customers.map((customer) => (
          <tr
            className="hoverable"
            key={customer.id}
            {...rowNavigationProps(`/customers/${customer.id}`)}
          >
            <td>{emptyToNull(customer.woo_store_id)}</td>
            <td>{emptyToNull(customer.full_name)}</td>
            <td>{emptyToNull(customer.email)}</td>
            <td>{emptyToNull(customer.phone)}</td>
            <td className="table_actions">
              <Link href={`/customers/${customer.id}/edit`} onClick={stopRowNavigation} prefetch>
                <i className="icn">✏</i>
                Edit
              </Link>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
