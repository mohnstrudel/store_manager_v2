// Every money figure in this app is a total — a sum, never an average or a
// median. What differs between pages is *what* was summed: one line of a
// sale, one whole sale, or every sale of a product. The definitions below
// stay scope-neutral so one entry reads correctly everywhere, and each call
// site closes the hint with the scope note that says what was added up.
export const financialMetricHints = {
  actualOpEx: "OpEx records entered for this month.",
  cashPositionToday:
    "Money actually collected from customers minus money actually paid to suppliers — what we should have in hand right now.",
  cogs: "What the sold items cost us, including purchase price, shipping, and direct expenses.",
  comparison:
    "How actual OpEx compares with the estimate. Under means we spent less; over means we spent more.",
  directExpenses: "Ad-hoc costs booked on a purchase item, such as extra tax or damaged packaging.",
  estimatedOpEx:
    "Revenue multiplied by the OpEx rates that are active now. Current rates are also used for earlier months.",
  expectedNetProfit:
    "Potential sales minus the expected total cost and estimated OpEx: what the product should earn once every purchased unit sells at its listed price.",
  expectedTotalCost:
    "Everything spent on purchased units: item price, shipping, and direct expenses, before OpEx. Sold and unsold units alike.",
  monthlyRevenue:
    "The full value of sales created in this month, whether or not customers have paid yet.",
  netProfit: "Revenue minus the cost of goods sold and estimated OpEx.",
  opEx: "General business costs estimated from the active OpEx rates.",
  outstanding: "Money billed but not collected yet.",
  potentialSales:
    "What every purchased unit will earn at its variant's selling price, before any costs. Sold and unsold units alike.",
  projectedNetProfit:
    "Projected total minus COGS and projected OpEx — the full deal's profit once every charge is raised, not what has been collected so far.",
  projectedOpEx: "OpEx estimated on the full contract value, not on the revenue collected so far.",
  projectedTotal:
    "The full contract value once every scheduled charge has been raised, not just what has been billed to date.",
  refunded: "Money paid back after the sale was billed.",
  revenue: "The full value billed, whether or not it has been paid yet.",
  variantPurchaseCostTotal:
    "Actual spend on this variant's purchase items: item price, shipping, and direct expenses. Purchases booked against the product as a whole have no variant to charge, so they are not counted here — this total will not match Expected Total Cost at the top of the page.",
  variantTheoreticalProfit:
    "Per unit: selling price minus the average landed cost of this variant's purchased units, minus OpEx.",
} as const;

// What a figure was added up from. Without one of these a reader cannot tell
// a line total from a sale total from a product's lifetime total.
export const metricScopeNotes = {
  sale: "For this sale.",
  line: "For this line of the sale.",
  purchase: "For this purchase.",
  purchaseItem: "For this purchase item.",
  saleItem: "For this sale item.",
} as const;

export function withScope(hint: string, note: string): string {
  if (!note) return hint;

  return `${hint} ${note}`;
}

// Only a figure summed over several sales needs saying so. One sale is the
// default reading of a product's figures, so it gets no note at all.
export function salesScopeNote(countedSales: number): string {
  if (countedSales < 2) return "";

  return `Across all ${countedSales} sales of this product.`;
}
