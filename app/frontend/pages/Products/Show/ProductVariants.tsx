import Amount from "@/components/Amount";
import MetricLabel from "@/components/profitability/MetricLabel";
import { financialMetricHints } from "@/components/profitability/metricLabels";
import { emptyToNull, isEmptyValue } from "@/utils/emptyValue";
import { type VariantRecord } from "../types";

type ProductVariantsProps = {
  variants: VariantRecord[];
};

export default function ProductVariants({ variants }: ProductVariantsProps) {
  if (variants.length === 0) return null;
  const showsEconomics = variants.some(
    (variant) => variant.total_purchase_cost !== null || variant.theoretical_profit !== null,
  );

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
            <th className="text-right">List cost</th>
            <th className="text-right">Selling Price</th>
            {showsEconomics && (
              <th className="text-right">
                <MetricLabel
                  anchor="variantPurchaseCostTotal"
                  hint={financialMetricHints.variantPurchaseCostTotal}
                >
                  Total landed cost
                </MetricLabel>
              </th>
            )}
            {showsEconomics && (
              <th className="text-right">
                <MetricLabel
                  anchor="variantTheoreticalProfit"
                  hint={financialMetricHints.variantTheoreticalProfit}
                >
                  Theoretical profit
                </MetricLabel>
              </th>
            )}
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
              <td className="text-right">
                {isEmptyValue(variant.weight) ? null : `${variant.weight} kg`}
              </td>
              <td className="text-right font-mono">
                {isEmptyValue(variant.purchase_cost) ? null : variant.purchase_cost.toFixed(2)}
              </td>
              <td className="text-right font-mono">
                {isEmptyValue(variant.selling_price) ? null : variant.selling_price.toFixed(2)}
              </td>
              {showsEconomics && (
                <td className="text-right">
                  <Amount value={variant.total_purchase_cost} />
                </td>
              )}
              {showsEconomics && (
                <td className="text-right">
                  <Amount value={variant.theoretical_profit} />
                </td>
              )}
              <td className="text-right">{emptyToNull(variant.active_sales_count)}</td>
              <td>{emptyToNull(variant.purchases_count)}</td>
              <td>{emptyToNull(variant.shopify_id_short) ?? emptyToNull(variant.woo_store_id)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
