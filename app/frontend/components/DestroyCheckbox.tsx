import { useCallback, type ChangeEvent } from "react";

type DestroyCheckboxProps = {
  defaultChecked: boolean;
  name: string;
  onChange?: (checked: boolean) => void;
};

export default function DestroyCheckbox({ defaultChecked, name, onChange }: DestroyCheckboxProps) {
  const handleChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => onChange?.(event.target.checked),
    [onChange],
  );

  return (
    <>
      <input defaultValue="0" name={name} type="hidden" />
      <label className="whitespace-nowrap text-sm m-0 cursor-pointer text-red-700 dark:text-red-300">
        <input
          className="m-0 mr-2 align-middle red focus:ring-red-500"
          defaultChecked={defaultChecked}
          name={name}
          type="checkbox"
          value="1"
          onChange={handleChange}
        />
        <span>Mark for deletion</span>
      </label>
    </>
  );
}
