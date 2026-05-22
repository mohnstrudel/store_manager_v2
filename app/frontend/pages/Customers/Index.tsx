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
      <PageHeader
        actions={
          <li>
            <Link href="/customers/new">
              <i className="icn">🐣</i>
              Add New Record
            </Link>
          </li>
        }
        title="Customers"
      />

      <div className="section-border-base section-wide">
        <div className="search">
          <SearchBar
            initialQuery={search.q}
            path="/customers"
            reloadOnly={["customers", "pagination", "search"]}
          />
          <div className="pagination-top">
            <Pagination pagination={pagination} params={{ q: search.q }} path="/customers" />
          </div>
        </div>

        <Table customers={customers} searchQuery={search.q} />

        <div className="pagination-bottom">
          <Pagination pagination={pagination} params={{ q: search.q }} path="/customers" />
        </div>
      </div>
    </>
  );
}
