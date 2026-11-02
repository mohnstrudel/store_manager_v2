import { useId, useMemo } from "react";

import Modal from "@/components/Modal";
import ModalActions from "@/components/ModalActions";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import TagsForm from "./TagsForm";
import type { SaleTagsForm } from "./useSaleTagsForm";

type SaleTagsDialogProps = {
  colors: SalesTagColor[];
  form: SaleTagsForm;
  options: SalesTagRecord[];
  title: string;
};

export default function SaleTagsDialog({ colors, form, options, title }: SaleTagsDialogProps) {
  const formId = useId();
  const actions = useMemo(
    () => (
      <ModalActions
        formId={formId}
        onCancel={form.cancel}
        processing={form.processing}
        processingLabel="Saving…"
        submitLabel="Save"
      />
    ),
    [form.cancel, form.processing, formId],
  );

  return (
    <Modal footer={actions} isBusy={form.processing} onClose={form.cancel} title={title}>
      <TagsForm colors={colors} form={form} id={formId} options={options} />
    </Modal>
  );
}
