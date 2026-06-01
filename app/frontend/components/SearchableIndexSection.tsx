import type { ReactNode } from "react";
import Pagination from "@/components/Pagination";
import SearchBar from "@/components/SearchBar";
import SearchResultsEmpty from "@/components/SearchResultsEmpty";

type PaginationMeta = {
  current_page: number;
  total_pages: number;
};

type SearchableIndexSectionProps = {
  children: ReactNode;
  className?: string;
  hasResults: boolean;
  pagination: PaginationMeta;
  path: string;
  query: string;
  resourceName: string;
  showBottomPagination?: boolean;
};

export default function SearchableIndexSection({
  children,
  className = "section_border_base section_wide",
  hasResults,
  pagination,
  path,
  query,
  resourceName,
  showBottomPagination = true,
}: SearchableIndexSectionProps) {
  return (
    <section className={className}>
      <SearchAndPagination
        pagination={pagination}
        path={path}
        query={query}
        resourceName={resourceName}
      />

      {hasResults ? children : <EmptySearchResults query={query} />}

      {showBottomPagination ? (
        <div className="pagination_bottom">
          <Pagination pagination={pagination} path={path} query={query} />
        </div>
      ) : null}
    </section>
  );
}

type SearchAndPaginationProps = {
  pagination: PaginationMeta;
  path: string;
  query: string;
  resourceName: string;
};

function SearchAndPagination({ pagination, path, query, resourceName }: SearchAndPaginationProps) {
  return (
    <div className="page_search">
      <SearchBar initialQuery={query} path={path} resourceName={resourceName} />
      <div className="pagination_top">
        <Pagination pagination={pagination} path={path} query={query} />
      </div>
    </div>
  );
}

function EmptySearchResults({ query }: { query: string }) {
  if (!query) return null;

  return <SearchResultsEmpty seed={query} />;
}
