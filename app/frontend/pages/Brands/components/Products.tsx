import CrudTable from "@/components/CrudTable";
import { ProductRecord } from "../types";

type ProductsProps = {
  products: ProductRecord[];
};

export default function Products({ products }: ProductsProps) {
  if (products.length === 0) return null;

  const columns = [
    { header: "ID", render: (product: ProductRecord) => product.id, className: "text-gray-500" },
    { header: "Full Title", render: (product: ProductRecord) => product.full_title },
  ];

  return (
    <div className="table-card">
      <h3>Products</h3>
      <CrudTable
        columns={columns}
        rowHref={(product) => product.path}
        rowKey={(product) => product.id}
        rows={products}
      />
    </div>
  );
}
