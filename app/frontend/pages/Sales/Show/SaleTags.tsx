import Modal from "@/components/Modal";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import TagBadges from "../components/TagBadges";
import { useSaleTagsForm } from "../components/useSaleTagsForm";
import TagsForm from "./TagsForm";

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
          <button
            className="btn_rounded btn_xs text-gray-600 dark:text-gray-400"
            onClick={form.open}
            type="button"
          >
            {title}
          </button>
        ) : null}
      </div>

      {form.isOpen ? (
        <Modal isBusy={form.processing} onClose={form.cancel} title={title}>
          <TagsForm colors={colors} form={form} options={options} />
        </Modal>
      ) : null}
    </>
  );
}
