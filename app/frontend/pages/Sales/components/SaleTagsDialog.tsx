import { useId, useMemo } from "react";

import Modal from "@/components/Modal";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import TagsForm, { TagsFormActions } from "./TagsForm";
import type { SaleTagsForm } from "./useSaleTagsForm";

type SaleTagsDialogProps = {
  colors: SalesTagColor[];
  form: SaleTagsForm;
  options: SalesTagRecord[];
  title: string;
};

export default function SaleTagsDialog({ colors, form, options, title }: SaleTagsDialogProps) {
  const formId = useId();
  const actions = useMemo(() => <TagsFormActions form={form} formId={formId} />, [form, formId]);

  return (
    <Modal footer={actions} isBusy={form.processing} onClose={form.cancel} title={title}>
      <TagsForm colors={colors} form={form} id={formId} options={options} />
    </Modal>
  );
}
