import { rowNavigationProps } from "@/utils/rowNavigation";

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
            <tr className="hoverable" key={product.id} {...rowNavigationProps(product.path)}>
              <td className="text-gray-500">{product.id}</td>
              <td>{product.full_title}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
