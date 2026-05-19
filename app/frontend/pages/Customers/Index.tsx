import Link from "@/components/Link";
import Pagination, { type PaginationLink } from "@/components/Pagination";
import PageHeader from "@/components/PageHeader";
import SearchBar from "./components/SearchBar";
import Table from "./components/Table";
import { CustomerRecord, PaginationMeta } from "./types";

type IndexProps = {
  customers: CustomerRecord[];
  pagination: PaginationMeta;
  search: { q: string };
};

function buildPaginationLinks(pagination: PaginationMeta, searchQuery: string): PaginationLink[] {
  if (pagination.total_pages <= 1) return [];

  function href(page: number): string {
    const params = new URLSearchParams();
    params.set("page", String(page));
    if (searchQuery) params.set("q", searchQuery);
    return `/customers?${params.toString()}`;
  }

  const { current_page, total_pages } = pagination;
  const links: PaginationLink[] = [];

  if (current_page > 1) {
    links.push({ href: href(current_page - 1), label: "‹", rel: "prev" });
  }

  for (let p = 1; p <= total_pages; p++) {
    if (p === 1 || p === total_pages || Math.abs(p - current_page) <= 1) {
      links.push({ active: p === current_page, href: href(p), label: String(p) });
    } else if (links[links.length - 1]?.label !== "…") {
      links.push({ href: null, label: "…" });
    }
  }

  if (current_page < total_pages) {
    links.push({ href: href(current_page + 1), label: "›", rel: "next" });
  }

  return links;
}

export default function Index({ customers, pagination, search }: IndexProps) {
  const paginationLinks = buildPaginationLinks(pagination, search.q);

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
          <SearchBar initialQuery={search.q} path="/customers" />
          <div className="pagination-top">
            <Pagination links={paginationLinks} />
          </div>
        </div>

        <Table customers={customers} />

        <div className="pagination-bottom">
          <Pagination links={paginationLinks} />
        </div>
      </div>
    </>
  );
}
