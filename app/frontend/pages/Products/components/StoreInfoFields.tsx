import SmartSelect from "@/components/SmartSelect";
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
        <div className="block w-full lg:w-1/3">
          <label className="block">Store</label>
          {storeInfo.id ? (
            <>
              <div className="h-10 rounded border border-gray-300 dark:border-gray-600 px-3 py-2 bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-300">
                {currentStoreOption?.label ?? storeInfo.store_name}
              </div>
              <input
                name={`store_infos[${index}][store_name]`}
                type="hidden"
                defaultValue={storeInfo.store_name}
              />
            </>
          ) : (
            <SmartSelect
              isClearable
              inputId={`store-info-${index}-store-name`}
              name={`store_infos[${index}][store_name]`}
              options={storeNameOptions}
              defaultValue={currentStoreOption}
            />
          )}
          {storeNameError && <p className="text-error mt-2">{storeNameError}</p>}
        </div>
        <div className="block w-full h-fit">
          <label className="block">Tags</label>
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
