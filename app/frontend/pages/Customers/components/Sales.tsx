import { Link } from "@inertiajs/react";
import { SaleRecord } from "../types";

type SalesProps = {
  heading: string;
  sales: SaleRecord[];
};

export default function Sales({ heading, sales }: SalesProps) {
  if (sales.length === 0) return null;

  return (
    <section className="table_card">
      <h3>{heading}</h3>
      <table>
        <thead>
          <tr>
            <th>Store ID</th>
            <th>Status</th>
            <th>Price, $</th>
            <th>Country</th>
            <th>City</th>
            <th>Note</th>
            <th>
              <span className="block">Created</span>
              <span className="font-normal text-gray-500">Updated</span>
            </th>
          </tr>
        </thead>
        <tbody>
          {sales.map((sale) => (
            <tr key={sale.id}>
              <td>
                <Link href={sale.path} prefetch>
                  {sale.store_type === "shopify" && (
                    <span className="inline-block icon_shopify w-5 h-5 mr-1 -mb-1" />
                  )}
                  {sale.store_type === "woo" && (
                    <span className="inline-block icon_woo w-8 h-8 mr-2 -mb-3" />
                  )}
                  {sale.store_id || sale.id}
                </Link>
              </td>
              <td>
                <span className={sale.active ? "text-lime-700" : "text-red-900"}>
                  {sale.status
                    .split("-")
                    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
                    .join(" ")}
                </span>
              </td>
              <td className="font-mono whitespace-nowrap">{sale.total ?? ""}</td>
              <td>{sale.country ?? ""}</td>
              <td>{sale.city ?? ""}</td>
              <td>{sale.note ?? ""}</td>
              <td>
                {sale.created_at}
                {sale.updated_at ? (
                  <>
                    <br />
                    <span className="text-gray-500">{sale.updated_at}</span>
                  </>
                ) : null}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </section>
  );
}
