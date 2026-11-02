import { router, useForm } from "@inertiajs/react";
import { useCallback, useId, useMemo, type ChangeEvent, type SubmitEvent } from "react";

import FormError from "@/components/FormError";
import Modal from "@/components/Modal";
import ModalActions from "@/components/ModalActions";
import type { SalesTagColor } from "@/types/salesTag";
import routes from "@/utils/routes";

import TagChoice from "../../Sales/components/TagChoice";
import type { SalesTagDraft, SalesTagFormRecord } from "../types";
import { leaveModalVisit } from "./modalVisits";

type TagFormModalProps = {
  colors: SalesTagColor[];
  salesTag: SalesTagFormRecord;
};

export default function TagFormModal({ colors, salesTag }: TagFormModalProps) {
  const formId = useId();
  const nameId = `${formId}_name`;
  const form = useForm<SalesTagDraft>({ name: salesTag.name, color: salesTag.color });
  const { clearErrors, setData } = form;

  const close = useCallback(() => router.visit(routes.salesTags.index.path(), leaveModalVisit), []);

  const changeName = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      clearErrors("name");
      setData((data) => ({ ...data, name: event.target.value }));
    },
    [clearErrors, setData],
  );

  const selectColor = useCallback(
    (color: SalesTagColor) => {
      clearErrors("color");
      setData((data) => ({ ...data, color }));
    },
    [clearErrors, setData],
  );

  const submit = useCallback(
    (event: SubmitEvent<HTMLFormElement>) => {
      event.preventDefault();
      form.transform((data) => ({ sales_tag: data }));
      if (salesTag.id === null) {
        form.post(routes.salesTags.create.path(), leaveModalVisit);
      } else {
        form.patch(routes.salesTags.update.path({ id: salesTag.id }), leaveModalVisit);
      }
    },
    [form, salesTag.id],
  );

  const isNew = salesTag.id === null;
  const actions = useMemo(
    () => (
      <ModalActions
        formId={formId}
        onCancel={close}
        processing={form.processing}
        processingLabel={isNew ? "Creating…" : "Updating…"}
        submitLabel={isNew ? "Create" : "Update"}
      />
    ),
    [close, form.processing, formId, isNew],
  );

  return (
    <Modal
      footer={actions}
      isBusy={form.processing}
      onClose={close}
      title={isNew ? "New tag" : "Edit tag"}
    >
      <form className="flex flex-col gap-4" id={formId} onSubmit={submit}>
        <div>
          <label htmlFor={nameId}>Name</label>
          <input
            aria-describedby={form.errors.name ? `${nameId}_error` : undefined}
            aria-invalid={!!form.errors.name}
            autoComplete="off"
            autoFocus // oxlint-disable-line jsx-a11y/no-autofocus -- the form mounts inside a modal the user just opened
            disabled={form.processing}
            id={nameId}
            onChange={changeName}
            value={form.data.name}
          />
          <FormError id={`${nameId}_error`}>{form.errors.name}</FormError>
        </div>
        <fieldset className="mb-0 pb-1.5">
          <legend>Color</legend>
          <div className="sales_tag_choices gap-2.5">
            {colors.map((color) => (
              <TagChoice
                checked={form.data.color === color}
                color={color}
                disabled={form.processing}
                key={color}
                name="color"
                onChange={selectColor}
                type="radio"
                value={color}
              >
                <span className="capitalize">{color}</span>
              </TagChoice>
            ))}
          </div>
          <FormError>{form.errors.color}</FormError>
        </fieldset>
      </form>
    </Modal>
  );
}
