import { Link } from "@inertiajs/react";
import { ProductRecord } from "../types";

type ProductsProps = {
  products: ProductRecord[];
};

export default function Products({ products }: ProductsProps) {
  if (products.length === 0) return null;

  return (
    <div className="table-card">
      <h3>Products</h3>
      <table>
        <thead>
          <tr>
            <th className="text-gray-500">ID</th>
            <th>Full Title</th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => (
            <tr key={product.id}>
              <td className="text-gray-500">{product.id}</td>
              <td>
                <Link href={product.path}>{product.full_title}</Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
