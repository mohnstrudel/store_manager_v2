import { useCallback, useState } from "react";
import { Link } from "@inertiajs/react";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";
import IndexTable from "./components/IndexTable";
import MoveToWarehouseForm from "./components/MoveToWarehouseForm";
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
  const [selectedIds, setSelectedIds] = useState<number[]>([]);
  const clearSelectedIds = useCallback(() => setSelectedIds([]), []);
  const togglePurchase = useCallback((purchaseId: number) => {
    setSelectedIds((current) =>
      current.includes(purchaseId)
        ? current.filter((selectedId) => selectedId !== purchaseId)
        : [...current, purchaseId],
    );
  }, []);
  const paginationBottom = (
    <div className="pagination_bottom">
      <Pagination pagination={pagination} path="/purchases" query={search.q} />
    </div>
  );

  return (
    <>
      <header className="nav_header">
        <hgroup>
          <h1>Purchases</h1>
        </hgroup>

        <menu className="nav_menu">
          <li>
            <Link href="/purchases/new" prefetch>
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        </menu>
      </header>

      <section className="section_border_base section_wide">
        <div className="search">
          <SearchBar initialQuery={search.q} path="/purchases" resourceName="purchases" />
          <div className="pagination_top">
            <Pagination pagination={pagination} path="/purchases" query={search.q} />
          </div>
        </div>

        {purchases.length > 0 ? (
          <>
            <IndexTable
              onTogglePurchase={togglePurchase}
              purchases={purchases}
              selectedIds={selectedIds}
            />
            {paginationBottom}
            <MoveToWarehouseForm
              movePath={move_path}
              onMoved={clearSelectedIds}
              selectedIds={selectedIds}
              warehouses={warehouses}
            />
          </>
        ) : search.q ? (
          <SearchResultsEmpty seed={search.q} />
        ) : null}

        {purchases.length === 0 && paginationBottom}
      </section>
    </>
  );
}
