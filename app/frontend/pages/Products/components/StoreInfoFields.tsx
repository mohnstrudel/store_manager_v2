import { useCallback, useMemo, useState } from "react";
import DestroyCheckbox from "@/components/DestroyCheckbox";
import FormControl from "@/components/FormControl";
import NestedFormContainer from "@/components/NestedFormContainer";
import FormSmartSelect from "@/components/FormSmartSelect";
import TagSelect from "@/components/TagSelect";
import { type SelectOption, type StoreInfoFormData } from "../types";

type StoreOption = SelectOption<string>;
const EMPTY_ERRORS: Record<string, string | undefined> = {};

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
  errors?: Record<string, string | undefined>;
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
  const [isMarkedForDeletion, setIsMarkedForDeletion] = useState(storeInfo._destroy);
  const storeNameOptions = useMemo<StoreOption[]>(
    () => storeNames.map((n) => ({ value: n, label: capitalize(n) })),
    [storeNames],
  );

  const currentStoreOption = storeNameOptions.find((o) => o.value === storeInfo.store_name) ?? null;

  const tagOptions = useMemo(() => toTagOptions(storeInfo.tag_list), [storeInfo.tag_list]);
  const prefix = `store_infos.${index}`;
  const baseError = errors[`${prefix}.base`];
  const storeNameError = errors[`${prefix}.store_name`];
  const tagListError = errors[`${prefix}.tag_list`];
  const handleRemove = useCallback(() => onRemove(index), [index, onRemove]);

  const title = storeInfo.id ? capitalize(storeInfo.store_name) : "New Store Info";
  const actions = useMemo(
    () =>
      storeInfo.id ? (
        <DestroyCheckbox
          defaultChecked={storeInfo._destroy}
          name={`store_infos[${index}][_destroy]`}
          onChange={setIsMarkedForDeletion}
        />
      ) : (
        <button className="btn_rounded btn_red" onClick={handleRemove} type="button">
          Cancel
        </button>
      ),
    [handleRemove, index, storeInfo._destroy, storeInfo.id],
  );

  return (
    <NestedFormContainer
      actions={actions}
      className={`store_info_fields ${isMarkedForDeletion ? "opacity-50" : ""}`}
      error={baseError}
      title={title}
    >
      <input name={`store_infos[${index}][id]`} type="hidden" defaultValue={storeInfo.id ?? ""} />

      <FormSmartSelect
        className="w-full lg:w-2/3"
        defaultValue={currentStoreOption}
        error={storeNameError}
        inputId={`store-info-${index}-store-name`}
        isClearable
        isDisabled={!!storeInfo.id}
        label="Store"
        name={`store_infos[${index}][store_name]`}
        options={storeNameOptions}
      />
      <FormControl className="w-full h-fit" error={tagListError} label="Tags">
        <TagSelect
          delimiter=", "
          isMulti
          inputId={`store-info-${index}-tag-list`}
          name={`store_infos[${index}][tag_list]`}
          placeholder="Add tags..."
          defaultValue={tagOptions}
        />
      </FormControl>
    </NestedFormContainer>
  );
}
