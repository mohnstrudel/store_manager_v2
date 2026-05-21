import { router } from "@inertiajs/react";
import type { KeyboardEvent, MouseEvent } from "react";
import Link from "@/components/Link";
import { CustomerRecord } from "../types";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";

type TableProps = {
  customers: CustomerRecord[];
};

export default function Table({ customers }: TableProps) {
  function visitRow(customer: CustomerRecord) {
    router.visit(`/customers/${customer.id}`);
  }

  function handleKeyDown(customer: CustomerRecord, event: KeyboardEvent<HTMLTableRowElement>) {
    if (event.key !== "Enter" && event.key !== " ") return;

    event.preventDefault();
    visitRow(customer);
  }

  function stopRowNavigation(event: MouseEvent) {
    event.stopPropagation();
  }

  if (customers.length === 0) {
    return <SearchResultsEmpty />;
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
            onClick={() => visitRow(customer)}
            onKeyDown={(event) => handleKeyDown(customer, event)}
            tabIndex={0}
          >
            <td>{customer.woo_store_id ?? ""}</td>
            <td>{customer.full_name ?? ""}</td>
            <td>{customer.email ?? ""}</td>
            <td>{customer.phone ?? ""}</td>
            <td className="actions">
              <Link
                href={`/customers/${customer.id}/edit`}
                onClick={stopRowNavigation}
              >
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
