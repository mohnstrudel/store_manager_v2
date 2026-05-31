import { type VariantRecord } from "../types";

type ProductVariantsProps = {
  variants: VariantRecord[];
};

export default function ProductVariants({ variants }: ProductVariantsProps) {
  if (variants.length === 0) return null;

  return (
    <div className="table_card">
      <h3>Variants</h3>
      <table>
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Type</th>
            <th className="text-right">Weight</th>
            <th className="text-right">Purchase Cost</th>
            <th className="text-right">Selling Price</th>
            <th className="text-right">Active Sales</th>
            <th>Purchases</th>
            <th>Store ID</th>
          </tr>
        </thead>
        <tbody>
          {variants.map((variant) => (
            <tr className={variant.deactivated ? "opacity-50" : ""} key={variant.id}>
              <td>{variant.id}</td>
              <td>
                {variant.title}
                {variant.deactivated && (
                  <span className="text-sm text-gray-500 dark:text-gray-400 ml-2">
                    (Deactivated)
                  </span>
                )}
              </td>
              <td>{variant.types_name}</td>
              <td className="text-right">{variant.weight === 0 ? "-" : `${variant.weight} kg`}</td>
              <td className="text-right">
                {variant.purchase_cost === 0 ? "-" : `$${variant.purchase_cost.toFixed(2)}`}
              </td>
              <td className="text-right">
                {variant.selling_price === 0 ? "-" : `$${variant.selling_price.toFixed(2)}`}
              </td>
              <td className="text-right">{variant.active_sales_count ?? ""}</td>
              <td>{variant.purchases_count ?? ""}</td>
              <td>{variant.shopify_id_short || variant.woo_store_id || ""}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
