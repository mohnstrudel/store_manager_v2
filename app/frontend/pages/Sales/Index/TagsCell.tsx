import { InlineCellTd, InlineCellTrigger } from "@/components/inline-cell-editing/InlineCellEditor";
import type { SalesTagRecord } from "@/types/salesTag";

import SaleTagsEditor from "../components/SaleTagsEditor";
import TagBadges from "../components/TagBadges";
import { useSaleTagsForm } from "../components/useSaleTagsForm";
import { TAG_SAVE_PROPS } from "./salesListing";

type TagsCellProps = {
  saleId: number;
  tags: SalesTagRecord[];
  options: SalesTagRecord[];
};

export default function TagsCell({ saleId, tags, options }: TagsCellProps) {
  const form = useSaleTagsForm({ saleId, tags, reloadProps: TAG_SAVE_PROPS });

  return (
    <InlineCellTd className="sales_tags_cell" onOpen={form.isOpen ? undefined : form.open}>
      {form.isOpen ? (
        <SaleTagsEditor form={form} idPrefix={`sale-${saleId}-tags`} options={options} />
      ) : (
        <InlineCellTrigger ariaLabel="Tags" onOpen={form.open}>
          <TagBadges tags={tags} />
        </InlineCellTrigger>
      )}
    </InlineCellTd>
  );
}
