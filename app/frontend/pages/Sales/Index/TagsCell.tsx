import { InlineCellTd, InlineCellTrigger } from "@/components/inline-cell-editing/InlineCellEditor";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import SaleTagsDialog from "../components/SaleTagsDialog";
import TagBadges from "../components/TagBadges";
import { useSaleTagsForm } from "../components/useSaleTagsForm";
import { TAG_SAVE_PROPS } from "./salesListing";

type TagsCellProps = {
  saleId: number;
  tags: SalesTagRecord[];
  options: SalesTagRecord[];
  colors: SalesTagColor[];
};

export default function TagsCell({ saleId, tags, options, colors }: TagsCellProps) {
  const form = useSaleTagsForm({ saleId, tags, reloadProps: TAG_SAVE_PROPS });
  const title = tags.length > 0 ? "Edit tags" : "Add tags";

  return (
    <InlineCellTd className="sales_tags_cell" onOpen={form.isOpen ? undefined : form.open}>
      <InlineCellTrigger ariaLabel="Tags" onOpen={form.open}>
        <TagBadges tags={tags} />
      </InlineCellTrigger>
      {form.isOpen ? (
        <SaleTagsDialog colors={colors} form={form} options={options} title={title} />
      ) : null}
    </InlineCellTd>
  );
}
