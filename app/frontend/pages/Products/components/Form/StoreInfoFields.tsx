import { lazy, Suspense, useCallback, useMemo, useState } from "react";
import DestroyCheckbox from "@/components/DestroyCheckbox";
import FormControl from "@/components/FormControl";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect, { SelectSkeleton } from "@/components/FormSmartSelect";

const TagSelect = lazy(() => import("@/components/TagSelect"));
const SELECT_FALLBACK = <SelectSkeleton />;
import { type SelectOption, type StoreInfoFormData } from "../../types";

type StoreOption = SelectOption<string>;
const EMPTY_ERRORS: Record<string, string> = {};

function toTagOptions(tagString: string): { value: string; label: string }[] {
  return tagString
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean)
    .map((t) => ({ value: t, label: t }));
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

type StoreInfoFieldsProps = {
  errors?: Record<string, string>;
  index: number;
  onRemove: (index: number) => void;
  storeInfo: StoreInfoFormData;
  storeNames: string[];
};

export default function StoreInfoFields({
  errors = EMPTY_ERRORS,
  index,
  onRemove,
  storeInfo,
  storeNames,
}: StoreInfoFieldsProps) {
  const storeInfoFields = useStoreInfoFieldState(storeInfo, storeNames);
  const prefix = `store_infos.${index}`;
  const baseError = errors[`${prefix}.base`];
  const storeNameError = errors[`${prefix}.store_name`];
  const tagListError = errors[`${prefix}.tag_list`];
  const handleRemove = useCallback(() => onRemove(index), [index, onRemove]);

  const actions = useMemo(
    () => (
      <StoreInfoActions
        index={index}
        onMarkedForDeletionChange={storeInfoFields.setIsMarkedForDeletion}
        onRemove={handleRemove}
        storeInfo={storeInfo}
      />
    ),
    [handleRemove, index, storeInfo, storeInfoFields.setIsMarkedForDeletion],
  );

  return (
    <NestedFormContainer
      actions={actions}
      className={`store_info_fields ${storeInfoFields.isMarkedForDeletion ? "opacity-50" : ""}`}
      error={baseError}
      title={storeInfoFields.title}
    >
      <input name={`store_infos[${index}][id]`} type="hidden" defaultValue={storeInfo.id ?? ""} />

      <FormSmartSelect
        className="w-full lg:w-2/3"
        defaultValue={storeInfoFields.currentStoreOption}
        error={storeNameError}
        inputId={`store-info-${index}-store-name`}
        isClearable
        isDisabled={!!storeInfo.id}
        label="Store"
        name={`store_infos[${index}][store_name]`}
        options={storeInfoFields.storeNameOptions}
      />
      <FormControl className="w-full h-fit" error={tagListError} label="Tags">
        <Suspense fallback={SELECT_FALLBACK}>
          <TagSelect
            delimiter=", "
            isMulti
            inputId={`store-info-${index}-tag-list`}
            name={`store_infos[${index}][tag_list]`}
            placeholder="Add tags..."
            defaultValue={storeInfoFields.tagOptions}
          />
        </Suspense>
      </FormControl>
    </NestedFormContainer>
  );
}

function StoreInfoActions({
  index,
  onMarkedForDeletionChange,
  onRemove,
  storeInfo,
}: {
  index: number;
  onMarkedForDeletionChange: (checked: boolean) => void;
  onRemove: () => void;
  storeInfo: StoreInfoFormData;
}) {
  if (!storeInfo.id) {
    return (
      <button className="btn_rounded btn_red text-sm" onClick={onRemove} type="button">
        Cancel
      </button>
    );
  }

  return (
    <DestroyCheckbox
      defaultChecked={storeInfo._destroy}
      name={`store_infos[${index}][_destroy]`}
      onChange={onMarkedForDeletionChange}
    />
  );
}

function useStoreInfoFieldState(storeInfo: StoreInfoFormData, storeNames: string[]) {
  const [isMarkedForDeletion, setIsMarkedForDeletion] = useState(storeInfo._destroy);
  const storeNameOptions = useMemo<StoreOption[]>(
    () => storeNames.map((name) => ({ value: name, label: capitalize(name) })),
    [storeNames],
  );
  const currentStoreOption =
    storeNameOptions.find((option) => option.value === storeInfo.store_name) ?? null;
  const tagOptions = useMemo(() => toTagOptions(storeInfo.tag_list), [storeInfo.tag_list]);
  const title = storeInfo.id ? capitalize(storeInfo.store_name) : "New Store Info";

  return {
    currentStoreOption,
    isMarkedForDeletion,
    setIsMarkedForDeletion,
    storeNameOptions,
    tagOptions,
    title,
  };
}

