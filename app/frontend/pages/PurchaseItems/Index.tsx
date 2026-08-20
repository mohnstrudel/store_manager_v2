import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import type { PaginationMeta } from "@/types/pagination";

import IndexTable, { type PurchaseItemRecord } from "./components/IndexTable";

type IndexProps = {
  pagination: PaginationMeta;
  purchase_items: PurchaseItemRecord[];
  search: { q: string };
};

export default function Index({ pagination, purchase_items, search }: IndexProps) {
  const hasPurchaseItems = purchase_items.length > 0;

  return (
    <>
      <PageHeader title="Purchase Items" />

      <SearchableTableSection
        hasResults={hasPurchaseItems}
        pagination={pagination}
        path="/purchase_items"
        query={search.q}
        resourceName="purchase_items"
        showBottomPagination={hasPurchaseItems}
      >
        <IndexTable purchaseItems={purchase_items} />
      </SearchableTableSection>
    </>
  );
}
