import { router, useForm, usePage } from "@inertiajs/react";
import { useCallback, useState } from "react";

import type { SalesTagRecord } from "@/types/salesTag";
import routes from "@/utils/routes";

const STALE_TAGS_ERROR = "Tags changed since you opened this editor. Reload tags and try again.";
const MISSING_TAG_ERROR = "A selected tag is no longer available. Reload tags and try again.";

type SaleTagsFormConfig = {
  saleId: number;
  tags: SalesTagRecord[];
  reloadProps: string[];
};

export type SaleTagsForm = {
  isOpen: boolean;
  processing: boolean;
  selectedIds: number[];
  error: string | undefined;
  needsReload: boolean;
  open: () => void;
  cancel: () => void;
  select: (ids: number[]) => void;
  save: () => void;
  reload: () => void;
};

export function useSaleTagsForm({ saleId, tags, reloadProps }: SaleTagsFormConfig): SaleTagsForm {
  const page = usePage();
  const savedIds = tags.map((tag) => tag.id);
  const [isOpen, setIsOpen] = useState(false);
  const form = useForm({ ids: savedIds, original_ids: savedIds });
  const { clearErrors, setData } = form;
  const errors: Record<string, string> = form.errors;
  const error = errors.tags;

  const discardDraft = useCallback(() => {
    clearErrors();
    setIsOpen(false);
  }, [clearErrors]);

  const open = () => {
    clearErrors();
    setData({ ids: savedIds, original_ids: savedIds });
    setIsOpen(true);
  };

  const select = (ids: number[]) => {
    clearErrors();
    setData((data) => ({ ...data, ids }));
  };

  const save = () => {
    form.transform((data) => ({
      sale: {
        tagging: {
          submitted: "1",
          ids: data.ids,
          original_ids: data.original_ids,
        },
      },
      return_to: page.url,
    }));
    form.patch(routes.salesTaggings.update.path({ sale_id: saleId }), {
      only: reloadProps,
      preserveScroll: true,
      preserveState: true,
      onSuccess: discardDraft,
    });
  };

  const reload = () => {
    router.reload({ only: reloadProps, onSuccess: discardDraft });
  };

  return {
    isOpen,
    processing: form.processing,
    selectedIds: form.data.ids,
    error,
    needsReload: error === STALE_TAGS_ERROR || error === MISSING_TAG_ERROR,
    open,
    cancel: discardDraft,
    select,
    save,
    reload,
  };
}
