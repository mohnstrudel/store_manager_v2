import { TagIcon, XIcon } from "lucide-react";
import { useCallback, useMemo, useState } from "react";

import SaleTagsDialog from "@/pages/Sales/components/SaleTagsDialog";
import type { TagPickerForm } from "@/pages/Sales/components/useSaleTagsForm";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

type TagFilterProps = {
  colors: SalesTagColor[];
  onApply: (tagId: number | null) => void;
  options: SalesTagRecord[];
  selectedId: number | null;
};

export default function TagFilter({ colors, onApply, options, selectedId }: TagFilterProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [draftId, setDraftId] = useState<number | null>(null);
  const selectedTag = options.find((tag) => tag.id === selectedId);

  const open = useCallback(() => {
    setDraftId(selectedId);
    setIsOpen(true);
  }, [selectedId]);

  const clear = useCallback(() => onApply(null), [onApply]);

  const picker = useMemo<TagPickerForm>(
    () => ({
      cancel: () => setIsOpen(false),
      processing: false,
      save: () => {
        setIsOpen(false);
        onApply(draftId);
      },
      select: (ids) => setDraftId(ids[ids.length - 1] ?? null),
      selectedIds: draftId === null ? [] : [draftId],
    }),
    [draftId, onApply],
  );

  return (
    <fieldset aria-label="Tag filter" className="flex flex-wrap items-center gap-2 mb-0">
      {selectedTag ? (
        <button
          aria-label={`Remove ${selectedTag.name} from the tag filter`}
          className="sales_tag inline-flex items-center gap-1 border-0 hover:brightness-95"
          data-color={selectedTag.color}
          onClick={clear}
          type="button"
        >
          {selectedTag.name}
          <XIcon aria-hidden className="size-3" />
        </button>
      ) : null}
      <button className="btn_xs" onClick={open} type="button">
        <TagIcon />
        Filter by tag
      </button>
      {isOpen ? (
        <SaleTagsDialog
          colors={colors}
          form={picker}
          options={options}
          submitLabel="Apply filter"
          title="Filter by tag"
        />
      ) : null}
    </fieldset>
  );
}
