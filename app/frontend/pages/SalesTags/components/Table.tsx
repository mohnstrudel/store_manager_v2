import { Link } from "@inertiajs/react";
import { CirclePlusIcon, PencilIcon, Trash2Icon } from "lucide-react";
import { useCallback, useState, type ChangeEvent, type MouseEvent } from "react";

import Button from "@/components/Button";
import routes from "@/utils/routes";
import { rowNavigationProps, stopRowNavigation } from "@/utils/rowNavigation";
import { useConfirmAction } from "@/utils/useConfirmAction";

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
            <CirclePlusIcon />
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
  const confirmDelete = useConfirmAction("delete", routes.salesTags.destroy.path({ id: tag.id }), {
    message: deleteQuestion(tag),
  });
  const deleteTag = useCallback(
    (event: MouseEvent<HTMLButtonElement>) => {
      stopRowNavigation(event);
      confirmDelete();
    },
    [confirmDelete],
  );

  return (
    <tr className="hoverable" {...rowNavigationProps(showPath, keepPageVisit)}>
      <td>
        <TagBadge color={tag.color}>{tag.name}</TagBadge>
      </td>
      <td className="text-right font-mono">{tag.usage_count}</td>
      {/* oxlint-disable-next-line jsx-a11y/control-has-associated-label -- nested labeled action */}
      <td className="table_actions">
        <div className="flex justify-end gap-2">
          <Button
            aria-label={`Delete ${tag.name}`}
            onClick={deleteTag}
            onKeyDown={stopRowNavigation}
            variant="danger"
          >
            <Trash2Icon />
            Delete
          </Button>
          <Link
            aria-label={`Edit ${tag.name}`}
            href={editPath}
            onClick={stopRowNavigation}
            {...keepPageVisit}
            prefetch
          >
            <PencilIcon />
            Edit
          </Link>
        </div>
      </td>
    </tr>
  );
}

function deleteQuestion(tag: SalesTagCatalogRecord) {
  if (tag.usage_count === 0) return `Delete "${tag.name}"?`;

  const sales = tag.usage_count === 1 ? "sale" : "sales";
  return `Delete "${tag.name}" from ${tag.usage_count} ${sales}? Sales will be kept.`;
}
