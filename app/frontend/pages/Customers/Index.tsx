import { Link } from "@inertiajs/react";
import Pagination from "@/components/Pagination";
import PageHeader from "@/components/PageHeader";
import SearchBar from "@/components/SearchBar";
import Table from "./components/Table";
import { CustomerRecord, PaginationMeta } from "./types";

type IndexProps = {
  customers: CustomerRecord[];
  pagination: PaginationMeta;
  search: { q: string };
};

export default function Index({ customers, pagination, search }: IndexProps) {
  return (
    <>
      <PageHeader title="Customers">
        <li>
          <Link href="/customers/new" prefetch>
            <i className="icn">🐣</i>
            Add New Record
          </Link>
        </li>
      </PageHeader>

      <div className="section_border_base section_wide">
        <div className="search">
          <SearchBar initialQuery={search.q} path="/customers" resourceName="customers" />
          <div className="pagination_top">
            <Pagination pagination={pagination} path="/customers" query={search.q} />
          </div>
        </div>

        <Table customers={customers} searchQuery={search.q} />

        <div className="pagination_bottom">
          <Pagination pagination={pagination} path="/customers" query={search.q} />
        </div>
      </div>
    </>
  );
}
