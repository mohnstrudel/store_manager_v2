import type { ReactNode } from "react";

import PageHeader from "@/components/PageHeader";

type GlossaryEntry = {
  id: string;
  aliasIds?: string[];
  term: string;
  // Only where the app labels this figure with a word the term does not already
  // say. A label that repeats the heading tells the reader nothing.
  shownAs?: { labels: string[]; where: string }[];
  definition: ReactNode;
  example?: ReactNode;
  watchFor?: ReactNode;
};

type GlossarySection = {
  id: string;
  title: string;
  entries: GlossaryEntry[];
};

export const sections: GlossarySection[] = [
  {
    id: "money-from-customers",
    title: "Money from customers",
    entries: [
      {
        id: "revenue",
        aliasIds: ["monthlyRevenue"],
        term: "Revenue",
        shownAs: [{ labels: ["Total"], where: "on a sale's details card" }],
        definition: "The full value of a customer's order, whether or not they have paid yet.",
        watchFor: "A cancelled order drops out of Revenue everywhere and shows no profit card.",
      },
      {
        id: "potentialSales",
        term: "Potential sales",
        definition:
          "What every purchased unit will earn at its variant's selling price, sold or unsold.",
      },
      {
        id: "outstanding",
        term: "Outstanding",
        definition: "Money billed to the customer that has not been collected yet.",
      },
      {
        id: "refunded",
        term: "Refunded",
        definition:
          "Money returned to the customer after the order was billed, shown separately without reducing Revenue.",
      },
      {
        id: "paymentPlan",
        term: "Payment plan",
        definition:
          "A set of customer orders that together bill and collect the full amount of a job over time.",
      },
      {
        id: "deposit",
        term: "Deposit",
        definition:
          "The first payment in a payment plan, billed before the rest of the job and carrying the whole job's cost.",
      },
      {
        id: "payment",
        term: "Payment",
        definition:
          "One customer order within a larger payment plan, rather than a stand-alone sale.",
        watchFor:
          "“Payments” on a purchase are payments to a supplier, and “Paid” is their total; they are not customer charges.",
      },
      {
        id: "projectedTotal",
        term: "Projected total",
        shownAs: [{ labels: ["Projected"], where: "in the Revenue row on a sale card" }],
        definition:
          "The full amount a payment plan will bill, including customer payments not billed yet.",
        example:
          "A custom order starts with a 30% deposit: the deposit order's Revenue covers that payment, while Projected total covers the whole job.",
      },
    ],
  },
  {
    id: "what-the-goods-cost",
    title: "What the goods cost",
    entries: [
      {
        id: "cogs",
        term: "COGS",
        definition: "The landed cost of the goods sold: Item price, Shipping, and direct expenses.",
        example: "Goods bought for 30 € with 5 € Shipping and a 20 € rush fee carry COGS of 55 €.",
        watchFor:
          "A sale line with no purchase item linked shows no cost, so COGS is missing and every profit figure under it is too high.",
      },
      {
        id: "directExpenses",
        term: "Direct expenses",
        definition:
          "Ad-hoc costs booked on a specific purchase item, such as extra tax or damaged packaging.",
      },
    ],
  },
  {
    id: "overheads",
    title: "Overheads",
    entries: [
      {
        id: "opEx",
        aliasIds: ["estimatedOpEx", "projectedOpEx"],
        term: "OpEx",
        shownAs: [
          { labels: ["Estimated OpEx"], where: "on the OpEx Rates page" },
          { labels: ["Projected"], where: "in the OpEx row on a sale card" },
        ],
        definition:
          "General business costs such as rent and payroll, estimated for a sale or product as a percentage of Revenue.",
      },
      {
        id: "opExRates",
        term: "OpEx rates",
        definition: "The overhead percentages used to estimate OpEx from Revenue.",
      },
      {
        id: "actualOpEx",
        term: "Actual OpEx",
        definition:
          "Operating costs recorded for a month as money actually spent, rather than estimated from Revenue.",
        watchFor:
          "The “OpEx” navigation item opens the records behind Actual OpEx; “OpEx” on a sale or product card is an estimate.",
      },
      {
        id: "comparison",
        term: "Comparison",
        definition:
          "The absolute difference between Actual OpEx and Estimated OpEx for a month, shown as under, over, or on estimate.",
        watchFor:
          "Today's OpEx rates are also applied to past months, so editing a rate recalculates Estimated OpEx and Comparison; Actual OpEx does not change.",
      },
    ],
  },
  {
    id: "profit",
    title: "Profit",
    entries: [
      {
        id: "netProfit",
        term: "Net profit",
        definition:
          "Revenue minus COGS and estimated OpEx: what one order should earn once the customer pays in full.",
        watchFor:
          "On a payment plan this reads one charge on its own, so a deposit carrying the whole job's cost can show a loss. Projected net profit reads the same job as a finished deal.",
      },
      {
        id: "expectedNetProfit",
        term: "Expected net profit",
        shownAs: [{ labels: ["Exp. Net Profit"], where: "on a product" }],
        definition:
          "Potential sales minus the expected total cost and estimated OpEx: what a product should earn once every purchased unit sells at its Selling Price.",
      },
      {
        id: "cashPositionToday",
        term: "Cash position today",
        shownAs: [{ labels: ["Cash today"], where: "on a product" }],
        definition:
          "Money actually collected from customers minus money actually paid to suppliers for a product: what we should have in hand right now.",
        watchFor:
          "Negative before a purchase has sold anything is expected — money went out to a supplier before any came back from a customer.",
      },
      {
        id: "projectedNetProfit",
        term: "Projected net profit",
        shownAs: [{ labels: ["Projected"], where: "in the Net Profit row on a sale card" }],
        definition:
          "Projected total minus COGS and Projected OpEx: what the whole payment plan should earn.",
      },
    ],
  },
  {
    id: "stock-and-suppliers",
    title: "Stock and suppliers",
    entries: [
      {
        id: "expectedTotalCost",
        term: "Expected total cost",
        shownAs: [{ labels: ["Exp. Total Cost"], where: "on a product" }],
        definition:
          "The landed cost of every unit received into a warehouse for this product, sold or unsold: Item price, shipping, and direct expenses.",
        watchFor:
          "A purchase not yet received is not counted, so Expected Total Cost can be lower than the value ordered.",
      },
      {
        id: "listCost",
        term: "List cost",
        definition:
          "A variant's hand-entered reference price, not a record of what was actually spent.",
        watchFor: "It has no connection to Total landed cost, which is what was actually spent.",
      },
      {
        id: "variantPurchaseCostTotal",
        term: "Total landed cost",
        definition:
          "The Item price, shipping, and direct expenses on this variant's own purchase items.",
        watchFor:
          "Purchases tied only to the product rather than to a variant are missing here but counted in Expected total cost, so the two rarely match.",
      },
      {
        id: "variantTheoreticalProfit",
        term: "Theoretical profit",
        definition:
          "A per-unit estimate using the selling price, Total landed cost divided by purchased units, and OpEx charged on the selling price.",
        watchFor: "It describes no actual sale, so use it as a planning estimate only.",
      },
      {
        id: "supplierDebt",
        term: "Supplier debt",
        shownAs: [{ labels: ["Debt"], where: "on the suppliers list" }],
        definition: "Money still owed to a supplier on a purchase.",
      },
      {
        id: "unitShortfall",
        term: "Unit shortfall",
        definition: "The number of units sold beyond the number bought for one product or variant.",
      },
      {
        id: "productsShort",
        term: "Products short",
        definition: "The number of product rows on the dashboard that have a Unit shortfall.",
      },
    ],
  },
];

export default function Show() {
  return (
    <>
      <PageHeader title="Money glossary" />

      <div className="flex max-w-3xl flex-col gap-10">
        <p className="text-gray-600 dark:text-gray-300">
          This page explains what each money figure means and when it can mislead you. Where the app
          labels a figure with a different word, the entry names that word too.
        </p>

        <nav aria-label="Glossary sections">
          <ul className="flex flex-wrap gap-x-6 gap-y-2">
            {sections.map((section) => (
              <li key={section.id}>
                <a className="link" href={`#${section.id}`}>
                  {section.title}
                </a>
              </li>
            ))}
          </ul>
        </nav>

        {sections.map((section) => (
          <section aria-labelledby={section.id} className="flex flex-col gap-6" key={section.id}>
            <h2 className="scroll-mt-24 text-xl font-semibold" id={section.id}>
              {section.title}
            </h2>
            <dl className="flex flex-col gap-8">
              {section.entries.map((entry) => (
                <GlossaryEntryItem entry={entry} key={entry.id} />
              ))}
            </dl>
          </section>
        ))}
      </div>
    </>
  );
}

function GlossaryEntryItem({ entry }: { entry: GlossaryEntry }) {
  return (
    <div className="scroll-mt-24" id={entry.id}>
      <dt className="text-lg font-semibold">
        {entry.aliasIds?.map((aliasId) => (
          <span aria-hidden="true" className="scroll-mt-24" id={aliasId} key={aliasId} />
        ))}
        {entry.term}
      </dt>
      <dd className="mt-1 flex flex-col gap-2 text-base">
        {entry.shownAs && (
          <p className="text-sm text-gray-500 dark:text-gray-400">
            Shown as {shownAsText(entry.shownAs)}
          </p>
        )}
        <p>{entry.definition}</p>
        {entry.example && (
          <p className="text-gray-600 dark:text-gray-300">
            <span className="font-medium text-gray-900 dark:text-gray-100">Example: </span>
            {entry.example}
          </p>
        )}
        {entry.watchFor && (
          <p className="border-l-2 border-amber-400 pl-3 dark:border-amber-500">
            <span className="font-semibold">Watch for: </span>
            {entry.watchFor}
          </p>
        )}
      </dd>
    </div>
  );
}

function shownAsText(shownAs: NonNullable<GlossaryEntry["shownAs"]>): string {
  return shownAs
    .map(({ labels, where }) => `${labels.map((label) => `“${label}”`).join(" and ")} ${where}`)
    .join("; ");
}
