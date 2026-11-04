import { TagIcon } from "lucide-react";

import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import SaleTagsDialog from "../components/SaleTagsDialog";
import TagBadges from "../components/TagBadges";
import { useSaleTagsForm } from "../components/useSaleTagsForm";

const TAG_SAVE_PROPS = ["sale", "tag_options", "tag_colors", "can_tag_sales"];

type SaleTagsProps = {
  saleId: number;
  tags: SalesTagRecord[];
  options: SalesTagRecord[];
  colors: SalesTagColor[];
  canTagSales: boolean;
};

export default function SaleTags({ saleId, tags, options, colors, canTagSales }: SaleTagsProps) {
  const form = useSaleTagsForm({ saleId, tags, reloadProps: TAG_SAVE_PROPS });

  if (!canTagSales && tags.length === 0) return null;

  const title = tags.length > 0 ? "Edit tags" : "Add tags";

  return (
    <>
      <div className="-mt-2 lg:-mt-3 mb-2 flex flex-wrap items-center gap-2">
        <TagBadges tags={tags} />
        {canTagSales ? (
          <button className="btn_xs" onClick={form.open} type="button">
            <TagIcon />
            {title}
          </button>
        ) : null}
      </div>

      {form.isOpen ? (
        <SaleTagsDialog colors={colors} form={form} options={options} title={title} />
      ) : null}
    </>
  );
}
