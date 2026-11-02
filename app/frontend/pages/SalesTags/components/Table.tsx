import { PlusCircleIcon } from "@heroicons/react/20/solid";
import { Link } from "@inertiajs/react";
import { useCallback, useState, type ChangeEvent } from "react";

import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";

import { TagBadge } from "../../Sales/components/TagBadges";
import type { SalesTagCatalogRecord } from "../types";
import { keepPageVisit } from "./modalVisits";

type TableProps = {
  salesTags: SalesTagCatalogRecord[];
};

export default function Table({ salesTags }: TableProps) {
  const [filter, setFilter] = useState("");
  const changeFilter = useCallback((event: ChangeEvent<HTMLInputElement>) => {
    setFilter(event.target.value);
  }, []);

  if (salesTags.length === 0) {
    return (
      <div className="table_card">
        <h3>Sales Tags</h3>
        <div className="table_empty">
          <p>
            Sales tags are shared labels you can put on any sale. Add them here, then assign them
            from the sales list or a sale page.
          </p>
          <Link className="btn_blue" href={routes.salesTags.new.path()} {...keepPageVisit} prefetch>
            <PlusCircleIcon height={20} width={20} />
            Add your first sales tag
          </Link>
        </div>
      </div>
    );
  }

  const needle = filter.trim().toLowerCase();
  const visibleTags = salesTags.filter((tag) => tag.name.toLowerCase().includes(needle));

  return (
    <div className="table_card">
      <div className="page_search">
        <input
          aria-label="Filter tags"
          onChange={changeFilter}
          placeholder="Filter tags…"
          type="search"
          value={filter}
        />
      </div>
      {visibleTags.length > 0 ? (
        <table>
          <thead>
            <tr>
              <th>Tag</th>
              <th className="text-right">Sales</th>
              <th className="text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {visibleTags.map((tag) => (
              <SalesTagRow key={tag.id} tag={tag} />
            ))}
          </tbody>
        </table>
      ) : (
        <p className="px-4 pb-6 text-gray-500 lg:px-8 dark:text-gray-400">
          No tags match “{filter.trim()}”.
        </p>
      )}
    </div>
  );
}

function SalesTagRow({ tag }: { tag: SalesTagCatalogRecord }) {
  const showPath = routes.salesTags.show.path({ id: tag.id });
  const editPath = routes.salesTags.edit.path({ id: tag.id });

  return (
    <tr className="hoverable" {...rowNavigationProps(showPath, keepPageVisit)}>
      <td>
        <TagBadge color={tag.color}>{tag.name}</TagBadge>
      </td>
      <td className="text-right font-mono">{tag.usage_count}</td>
      {/* oxlint-disable-next-line jsx-a11y/control-has-associated-label -- nested labeled action */}
      <td className="table_actions">
        <div className="flex justify-end gap-2">
          <Link
            aria-label={`Edit ${tag.name}`}
            href={editPath}
            onClick={stopRowNavigation}
            {...keepPageVisit}
            prefetch
          >
            <i className="icn">✏</i>
            Edit
          </Link>
        </div>
      </td>
    </tr>
  );
}
