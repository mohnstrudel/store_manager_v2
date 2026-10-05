import { Link } from "@inertiajs/react";

import MoveToWarehouseForm from "@/components/MoveToWarehouseForm";
import PageHeader from "@/components/PageHeader";
import SearchableTableSection from "@/components/SearchableTableSection";
import { useWarehouseMoveSelection } from "@/utils/useWarehouseMoveSelection";

import IndexTable from "./Index/Table";
import type { PaginationMeta, PurchaseIndexRecord, WarehouseOption } from "./types";

type IndexProps = {
  move_path: string;
  pagination: PaginationMeta;
  purchases: PurchaseIndexRecord[];
  search: { q: string };
  warehouses: WarehouseOption[];
};

export default function Index({
  move_path,
  pagination,
  purchases,
  search,
  warehouses,
}: IndexProps) {
  const { clearSelectedIds, selectedIds, toggleSelectedId } = useWarehouseMoveSelection();

  return (
    <>
      <PageHeader title="Purchases">
        <li>
          <Link href="/purchases/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <SearchableTableSection
        hasResults={purchases.length > 0}
        pagination={pagination}
        path="/purchases"
        query={search.q}
        resourceName="purchases"
      >
        <IndexTable
          onTogglePurchase={toggleSelectedId}
          purchases={purchases}
          selectedIds={selectedIds}
        />
        <MoveToWarehouseForm
          movePath={move_path}
          onMoved={clearSelectedIds}
          selectedIds={selectedIds}
          warehouses={warehouses}
        />
      </SearchableTableSection>
    </>
  );
}
