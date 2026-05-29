import FormSmartSelect from "@/components/FormSmartSelect";
import TagSelect from "@/components/TagSelect";
import { type SelectOption, type StoreInfoFormData } from "../types";

type StoreOption = SelectOption<string>;

function toTagOptions(tagString: string): { value: string; label: string }[] {
  return tagString
    .split(",")
    .map((t) => t.trim())
    .filter(Boolean)
    .map((t) => ({ value: t, label: t }));
}

type StoreInfoFieldsProps = {
  errors?: Record<string, string | undefined>;
  index: number;
  onRemove: (index: number) => void;
  storeInfo: StoreInfoFormData;
  storeNames: string[];
};

export default function StoreInfoFields({
  errors = {},
  index,
  onRemove,
  storeInfo,
  storeNames,
}: StoreInfoFieldsProps) {
  const storeNameOptions: StoreOption[] = storeNames.map((n) => ({
    value: n,
    label: n.charAt(0).toUpperCase() + n.slice(1),
  }));

  const currentStoreOption = storeNameOptions.find((o) => o.value === storeInfo.store_name) ?? null;

  const tagOptions = toTagOptions(storeInfo.tag_list);
  const prefix = `store_infos.${index}`;
  const baseError = errors[`${prefix}.base`];
  const storeNameError = errors[`${prefix}.store_name`];
  const tagListError = errors[`${prefix}.tag_list`];

  return (
    <div className="store-info-fields border border-gray-200 dark:border-gray-800 rounded-xl p-4 pb-8 max-w-full lg:max-w-4/7">
      {baseError && <p className="text-error mb-4">{baseError}</p>}

      <div className="flex justify-between items-start flex-col lg:flex-row lg:items-center gap-2">
        {storeInfo.id ? (
          <>
            <h6 className="font-semibold">
              {storeInfo.store_name.charAt(0).toUpperCase() + storeInfo.store_name.slice(1)}
            </h6>
            <input name={`store_infos[${index}][_destroy]`} type="hidden" defaultValue="0" />
            <label className="m-0 flex items-center gap-2 text-sm cursor-pointer text-red-600 dark:text-red-900">
              <input
                className="m-0 w-4 h-4 text-red-600 rounded focus:ring-red-500"
                defaultChecked={storeInfo._destroy}
                name={`store_infos[${index}][_destroy]`}
                type="checkbox"
                value="1"
              />
              <span>Destroy connection?</span>
            </label>
          </>
        ) : (
          <>
            <h6 className="font-semibold">New Store Info</h6>
            <button className="btn-rounded btn-red" onClick={() => onRemove(index)} type="button">
              Remove
            </button>
          </>
        )}
      </div>

      <input name={`store_infos[${index}][id]`} type="hidden" defaultValue={storeInfo.id ?? ""} />

      <div className="flex justify-between gap-4 flex-col mt-4">
        <FormSmartSelect
          className="w-full lg:w-1/3"
          defaultValue={currentStoreOption}
          error={storeNameError}
          inputId={`store-info-${index}-store-name`}
          isClearable
          isDisabled={!!storeInfo.id}
          label="Store"
          name={`store_infos[${index}][store_name]`}
          options={storeNameOptions}
        />
        <div className="w-full h-fit">
          <label>Tags</label>
          <TagSelect
            delimiter=", "
            isMulti
            inputId={`store-info-${index}-tag-list`}
            name={`store_infos[${index}][tag_list]`}
            placeholder="Add tags..."
            defaultValue={tagOptions}
          />
          {tagListError && <p className="text-error mt-2">{tagListError}</p>}
        </div>
      </div>
    </div>
  );
}
