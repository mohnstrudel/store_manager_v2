import { Link } from "@inertiajs/react";
import routes from "@/utils/routes";
import { ProductRecord } from "../types";

type ProductsProps = {
  products: ProductRecord[];
};

export default function Products({ products }: ProductsProps) {
  if (products.length === 0) return null;

  return (
    <div className="table_card">
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
                <Link href={routes.products.show.path({ id: product.id })} prefetch>
                  {product.full_title}
                </Link>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
