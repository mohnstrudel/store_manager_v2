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

export default function Pagination({
  className = "",
  label = "Pagination",
  pagination,
  query,
  path,
}: PaginationProps) {
  const { current_page, total_pages } = pagination;
  const pages = visiblePageItems(current_page, total_pages);

  if (total_pages <= 1) return null;

  return (
    <nav aria-label={label} className={`pagination ${className}`}>
      {current_page > 1 && (
        <Link
          className="pagination_previous"
          href={hrefForPage(path, current_page - 1, query)}
          rel="prev"
          prefetch
        >
          Previous
        </Link>
      )}
      <div className="pagination_pages">
        {pages.map((item) => {
          if (item.type === "gap") {
            return (
              <span className="pagination_gap" key={item.key}>
                …
              </span>
            );
          }

          if (item.page === current_page) {
            return (
              <span aria-current="page" className="pagination_link is_current" key={item.page}>
                {item.page}
              </span>
            );
          }

          return (
            <Link
              className="pagination_link"
              href={hrefForPage(path, item.page, query)}
              key={item.page}
              prefetch
            >
              {item.page}
            </Link>
          );
        })}
      </div>
      {current_page < total_pages && (
        <Link
          className="pagination_next"
          href={hrefForPage(path, current_page + 1, query)}
          rel="next"
          prefetch
        >
          Next
        </Link>
      )}
    </nav>
  );
}

function visiblePageItems(currentPage: number, totalPages: number) {
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

  const visiblePages: Array<{ type: "page"; page: number } | { type: "gap"; key: string }> = [];

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

function hrefForPage(path: string, page: number, query?: string) {
  const searchParams = new URLSearchParams();

  searchParams.set("page", String(page));

  if (query) searchParams.set("q", query);

  return `${path}?${searchParams.toString()}`;
}
