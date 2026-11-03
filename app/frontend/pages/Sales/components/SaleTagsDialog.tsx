import { useId, useMemo } from "react";

import Modal from "@/components/Modal";
import ModalActions from "@/components/ModalActions";
import type { SalesTagColor, SalesTagRecord } from "@/types/salesTag";

import TagsForm from "./TagsForm";
import type { TagPickerForm } from "./useSaleTagsForm";

type SaleTagsDialogProps = {
  colors: SalesTagColor[];
  form: TagPickerForm;
  options: SalesTagRecord[];
  submitLabel?: string;
  title: string;
};

export default function SaleTagsDialog({
  colors,
  form,
  options,
  submitLabel = "Save",
  title,
}: SaleTagsDialogProps) {
  const formId = useId();
  const actions = useMemo(
    () => (
      <ModalActions
        formId={formId}
        onCancel={form.cancel}
        processing={form.processing}
        processingLabel="Saving…"
        submitLabel={submitLabel}
      />
    ),
    [form.cancel, form.processing, formId, submitLabel],
  );

  return (
    <Modal footer={actions} isBusy={form.processing} onClose={form.cancel} title={title}>
      <TagsForm colors={colors} form={form} id={formId} options={options} />
    </Modal>
  );
}
