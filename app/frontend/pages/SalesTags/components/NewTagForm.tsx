import { useForm } from "@inertiajs/react";
import { useCallback, type ChangeEvent, type FormEvent } from "react";

import FormError from "@/components/FormError";
import type { SalesTagColor } from "@/types/salesTag";
import routes from "@/utils/routes";

import { TagBadge } from "../../Sales/components/TagBadges";

type NewTagFormProps = {
  query: string;
  tagColors: SalesTagColor[];
};

const defaultColor: SalesTagColor = "green";

export default function NewTagForm({ query, tagColors }: NewTagFormProps) {
  const { changeName, form, selectColor, submit } = useNewTagForm(query);

  return (
    <form className="px-4 lg:px-8 pt-4 lg:pt-7 flex flex-col gap-2" onSubmit={submit}>
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center">
        <label className="sr-only" htmlFor="sales_tag_name">
          Tag name
        </label>
        <input
          aria-describedby={form.errors.name ? "sales_tag_name_error" : undefined}
          aria-invalid={!!form.errors.name}
          autoComplete="off"
          className="w-full lg:w-96"
          disabled={form.processing}
          id="sales_tag_name"
          name="name"
          onChange={changeName}
          placeholder="Tag name"
          value={form.data.name}
        />
        <fieldset className="mb-0">
          <legend className="sr-only">Color</legend>
          <div className="sales_tag_choices">
            {tagColors.map((color) => (
              <ColorChoice
                checked={form.data.color === color}
                color={color}
                disabled={form.processing}
                key={color}
                onSelect={selectColor}
              />
            ))}
          </div>
        </fieldset>
        <button className="btn_blue w-fit" disabled={form.processing} type="submit">
          Add tag
        </button>
      </div>
      <FormError id="sales_tag_name_error">{form.errors.name}</FormError>
      <FormError id="sales_tag_color_error">{form.errors.color}</FormError>
    </form>
  );
}

function useNewTagForm(query: string) {
  const form = useForm({ name: "", color: defaultColor });
  const createPath = routes.salesTags.create.path({ query: { q: query || undefined } });

  const changeName = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      form.clearErrors("name");
      form.setData((data) => ({ ...data, name: event.target.value }));
    },
    [form],
  );

  const selectColor = useCallback(
    (color: SalesTagColor) => {
      form.clearErrors("color");
      form.setData((data) => ({ ...data, color }));
    },
    [form],
  );

  const submit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      form.transform((data) => ({ sales_tag: data }));
      form.post(createPath, {
        preserveScroll: true,
        preserveState: true,
        onSuccess: () => {
          form.reset();
          form.clearErrors();
        },
      });
    },
    [createPath, form],
  );

  return { changeName, form, selectColor, submit };
}

type ColorChoiceProps = {
  checked: boolean;
  color: SalesTagColor;
  disabled: boolean;
  onSelect: (color: SalesTagColor) => void;
};

function ColorChoice({ checked, color, disabled, onSelect }: ColorChoiceProps) {
  const select = useCallback(() => onSelect(color), [color, onSelect]);

  return (
    <label className="sales_tag_choice">
      <input
        checked={checked}
        className="sr-only"
        disabled={disabled}
        name="color"
        onChange={select}
        type="radio"
        value={color}
      />
      <TagBadge color={color}>{color}</TagBadge>
    </label>
  );
}
