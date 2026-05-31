import { Link } from "@inertiajs/react";

type PaginationMeta = {
  current_page: number;
  total_pages: number;
};

type PaginationProps = {
  className?: string;
  label?: string;
  pagination: PaginationMeta;
  query?: string;
  path: string;
};

type PageItem = { type: "page"; page: number };
type PageGap = { type: "gap"; key: string };
type PaginationItem = PageItem | PageGap;

export default function Pagination({
  className = "",
  label = "Pagination",
  pagination,
  query,
  path,
}: PaginationProps) {
  const { current_page, total_pages } = pagination;
  const visibleItems = buildVisiblePaginationItems(current_page, total_pages);

  if (total_pages <= 1) return null;

  return (
    <nav aria-label={label} className={`pagination ${className}`}>
      <PreviousPageLink currentPage={current_page} path={path} query={query} />
      <PageList currentPage={current_page} items={visibleItems} path={path} query={query} />
      <NextPageLink currentPage={current_page} path={path} query={query} totalPages={total_pages} />
    </nav>
  );
}

type PreviousPageLinkProps = {
  currentPage: number;
  path: string;
  query?: string;
};

function PreviousPageLink({ currentPage, path, query }: PreviousPageLinkProps) {
  if (currentPage <= 1) return null;

  return (
    <Link
      className="pagination_previous"
      href={hrefForPage(path, currentPage - 1, query)}
      rel="prev"
      prefetch
    >
      Previous
    </Link>
  );
}

type PageListProps = {
  currentPage: number;
  items: PaginationItem[];
  path: string;
  query?: string;
};

function PageList({ currentPage, items, path, query }: PageListProps) {
  return (
    <div className="pagination_pages">
      {items.map((item) => (
        <PageListItem
          currentPage={currentPage}
          item={item}
          key={itemKey(item)}
          path={path}
          query={query}
        />
      ))}
    </div>
  );
}

type PageListItemProps = {
  currentPage: number;
  item: PaginationItem;
  path: string;
  query?: string;
};

function PageListItem({ currentPage, item, path, query }: PageListItemProps) {
  if (item.type === "gap") {
    return <span className="pagination_gap">…</span>;
  }

  if (item.page === currentPage) {
    return (
      <span aria-current="page" className="pagination_link is_current">
        {item.page}
      </span>
    );
  }

  return (
    <Link className="pagination_link" href={hrefForPage(path, item.page, query)} prefetch>
      {item.page}
    </Link>
  );
}

type NextPageLinkProps = {
  currentPage: number;
  path: string;
  query?: string;
  totalPages: number;
};

function NextPageLink({ currentPage, path, query, totalPages }: NextPageLinkProps) {
  if (currentPage >= totalPages) return null;

  return (
    <Link
      className="pagination_next"
      href={hrefForPage(path, currentPage + 1, query)}
      rel="next"
      prefetch
    >
      Next
    </Link>
  );
}

function buildVisiblePaginationItems(currentPage: number, totalPages: number): PaginationItem[] {
  const pages = new Set<number>();
  const visibleLeadingPages = Math.min(3, totalPages);

  for (let page = 1; page <= visibleLeadingPages; page += 1) {
    pages.add(page);
  }

  pages.add(currentPage);
  pages.add(totalPages);

  const sortedPages: number[] = [];

  pages.forEach((page) => {
    const insertAt = sortedPages.findIndex((existingPage) => existingPage > page);

    if (insertAt === -1) {
      sortedPages.push(page);
      return;
    }

    sortedPages.splice(insertAt, 0, page);
  });

  const visiblePages: PaginationItem[] = [];

  sortedPages.forEach((page, index) => {
    if (index === 0 || page === sortedPages[index - 1] + 1) {
      visiblePages.push({ type: "page", page });
      return;
    }

    visiblePages.push({
      type: "gap",
      key: `gap-${sortedPages[index - 1]}-${page}`,
    });
    visiblePages.push({ type: "page", page });
  });

  return visiblePages;
}

function itemKey(item: PaginationItem) {
  if (item.type === "gap") return item.key;

  return item.page;
}

function hrefForPage(path: string, page: number, query?: string) {
  const searchParams = new URLSearchParams();

  searchParams.set("page", String(page));

  if (query) searchParams.set("q", query);

  return `${path}?${searchParams.toString()}`;
}
