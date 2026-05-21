import Link from "@/components/Link";

type PaginationMeta = {
  current_page: number;
  total_pages: number;
};

type PaginationProps = {
  className?: string;
  label?: string;
  pagination: PaginationMeta;
  params?: Record<string, string | number | null | undefined>;
  path: string;
};

export default function Pagination({
  className = "",
  label = "Pagination",
  pagination,
  params = {},
  path,
}: PaginationProps) {
  const { current_page, total_pages } = pagination;
  const pages = visiblePageItems(current_page, total_pages);

  if (total_pages <= 1) return null;

  return (
    <nav aria-label={label} className={["pagination", className].filter(Boolean).join(" ")}>
      {current_page > 1 && (
        <Link
          className="pagination-previous"
          href={hrefForPage(path, current_page - 1, params)}
          rel="prev"
        >
          Previous
        </Link>
      )}
      <div className="pagination-pages">
        {pages.map((page, index) =>
          page === "gap" ? (
            <span className="pagination-gap" key={`gap-${index}`}>
              …
            </span>
          ) : page === current_page ? (
            <span aria-current="page" className="pagination-link is-current" key={page}>
              {page}
            </span>
          ) : (
            <Link
              className="pagination-link"
              href={hrefForPage(path, page, params)}
              key={page}
            >
              {page}
            </Link>
          ),
        )}
      </div>
      {current_page < total_pages && (
        <Link
          className="pagination-next"
          href={hrefForPage(path, current_page + 1, params)}
          rel="next"
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

  return Array.from(pages)
    .sort((left, right) => left - right)
    .flatMap((page, index, sortedPages) => {
      if (index === 0 || page === sortedPages[index - 1] + 1) return [page];

      return ["gap" as const, page];
    });
}

function hrefForPage(
  path: string,
  page: number,
  params: Record<string, string | number | null | undefined>,
) {
  const searchParams = new URLSearchParams();

  searchParams.set("page", String(page));

  Object.entries(params).forEach(([key, value]) => {
    if (value === null || value === undefined || value === "") return;

    searchParams.set(key, String(value));
  });

  return `${path}?${searchParams.toString()}`;
}
