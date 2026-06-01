import PageHeader from "@/components/PageHeader";
import SearchableIndexSection from "@/components/SearchableIndexSection";
import type { PaginationMeta } from "@/pages/Purchases/types";
import IndexTable, { type PurchaseItemRecord } from "./components/IndexTable";

type IndexProps = {
  pagination: PaginationMeta;
  purchase_items: PurchaseItemRecord[];
  search: { q: string };
};

export default function Index({ pagination, purchase_items, search }: IndexProps) {
  return (
    <>
      <PageHeader title="Purchase Items" />

      <SearchableIndexSection
        hasResults={purchase_items.length > 0}
        pagination={pagination}
        path="/purchase_items"
        query={search.q}
        resourceName="purchase_items"
        showBottomPagination={purchase_items.length > 0}
      >
        <IndexTable purchaseItems={purchase_items} />
      </SearchableIndexSection>
    </>
  );
}
