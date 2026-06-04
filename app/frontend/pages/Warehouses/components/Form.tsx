import { useCallback, useState, type ChangeEvent } from "react";
import Button from "@/components/Button";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import FormSectionHeading from "@/components/FormSectionHeading";
import ImageUploader from "@/components/ImageUploader";
import ResourceForm from "@/components/ResourceForm";
import { useDynamicSection } from "@/lib/useDynamicSection";
import { getFormString } from "@/lib/formSchema";
import { validateWarehouseForm } from "../lib/warehouseFormSchema";
import type { WarehouseFormOptions, WarehouseFormRecord, WarehouseOption } from "../types";

type WarehouseFormProps = {
  isNew: boolean;
  options: WarehouseFormOptions;
  submitLabel: string;
  warehouse: WarehouseFormRecord;
};

type WarehouseFormState = ReturnType<typeof useWarehouseFormState>;
type TransitionRow = {
  clientKey: string;
  toWarehouseId: number | null;
};

function validate(formData: FormData) {
  return validateWarehouseForm({ name: getFormString(formData, "warehouse[name]") });
}

export default function Form({ isNew, options, submitLabel, warehouse }: WarehouseFormProps) {
  const form = useWarehouseFormState(warehouse);

  return (
    <ResourceForm
      action={isNew ? "/warehouses" : warehouse.path}
      cancelHref={isNew ? "/warehouses" : warehouse.path}
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
      validate={validate}
    >
      {({ errors }) => (
        <>
          <WarehouseIdentityFields errors={errors} options={options} warehouse={warehouse} />
          <WarehouseExternalNamesFields errors={errors} warehouse={warehouse} />
          <WarehouseDescriptionFields errors={errors} warehouse={warehouse} />
          <WarehouseTrackingFields errors={errors} warehouse={warehouse} />
            <WarehouseImagesSection form={form} />
            <TransitionNotificationsSection
              destinations={options.transition_destinations}
              onAdd={form.transitionRows.add}
              onChange={form.transitionRows.update}
              onRemove={form.transitionRows.remove}
              rows={form.transitionRows.items}
            />
        </>
      )}
    </ResourceForm>
  );
}

function WarehouseIdentityFields({
  errors,
  options,
  warehouse,
}: {
  errors: Record<string, string>;
  options: WarehouseFormOptions;
  warehouse: WarehouseFormRecord;
}) {
  return (
    <FormRow>
      <FormInput
        className="lg:w-4/5"
        defaultValue={warehouse.name}
        error={errors.name}
        label="Name"
        name="warehouse[name]"
      />
      <FormInput
        className="lg:w-1/5"
        defaultValue={warehouse.cbm}
        error={errors.cbm}
        label="CBM"
        name="warehouse[cbm]"
      />
      <SelectField
        className="lg:w-1/5"
        defaultValue={warehouse.position}
        error={errors.position}
        label="Position"
        name="warehouse[position]"
        options={positionOptions(options.positions)}
      />
      <SelectField
        className="lg:w-1/5"
        defaultValue={warehouse.is_default ? "1" : "0"}
        error={errors.is_default}
        label="Default Warehouse"
        name="warehouse[is_default]"
        options={defaultWarehouseOptions()}
      />
    </FormRow>
  );
}

function WarehouseExternalNamesFields({
  errors,
  warehouse,
}: {
  errors: Record<string, string>;
  warehouse: WarehouseFormRecord;
}) {
  return (
    <FormRow>
      <FormInput
        defaultValue={warehouse.external_name_en}
        error={errors.external_name_en}
        label="External Name in English"
        name="warehouse[external_name_en]"
      />
      <FormInput
        defaultValue={warehouse.external_name_de}
        error={errors.external_name_de}
        label="External Name in German"
        name="warehouse[external_name_de]"
      />
    </FormRow>
  );
}

function WarehouseDescriptionFields({
  errors,
  warehouse,
}: {
  errors: Record<string, string>;
  warehouse: WarehouseFormRecord;
}) {
  return (
    <FormRow>
      <TextAreaField
        defaultValue={warehouse.desc_en}
        error={errors.desc_en}
        label="English Description"
        name="warehouse[desc_en]"
      />
      <TextAreaField
        defaultValue={warehouse.desc_de}
        error={errors.desc_de}
        label="German Description"
        name="warehouse[desc_de]"
      />
    </FormRow>
  );
}

function WarehouseTrackingFields({
  errors,
  warehouse,
}: {
  errors: Record<string, string>;
  warehouse: WarehouseFormRecord;
}) {
  return (
    <FormRow>
      <FormInput
        defaultValue={warehouse.container_tracking_number}
        error={errors.container_tracking_number}
        label="Container Tracking Number"
        name="warehouse[container_tracking_number]"
        className="lg:w-1/3"
      />
      <FormInput
        defaultValue={warehouse.courier_tracking_url}
        error={errors.courier_tracking_url}
        label="Courier Tracking URL"
        name="warehouse[courier_tracking_url]"
        type="url"
        className="lg:w-2/3"
      />
    </FormRow>
  );
}

function WarehouseImagesSection({ form }: { form: WarehouseFormState }) {
  return (
    <ImageUploader
      fieldNamePrefix="warehouse[media]"
      imageFieldName="image"
      media={form.media}
      onMediaChange={form.setMedia}
    />
  );
}

function SelectField({
  defaultValue,
  error,
  label,
  name,
  options,
  className,
}: {
  defaultValue: string | number;
  error?: string;
  label: string;
  name: string;
  options: Array<{ label: string; value: string | number }>;
  className?: string;
}) {
  const id = name.replace(/\[|\]/g, "_").replace(/_+$/g, "");
  const classNames = ["w-full", className].filter(Boolean).join(" ");

  return (
    <FormControl className={classNames} error={error} htmlFor={id} label={label}>
      <select
        aria-describedby={error ? `${id}_error` : undefined}
        aria-invalid={!!error}
        defaultValue={defaultValue}
        id={id}
        name={name}
      >
        {options.map((option) => (
          <option key={option.value} value={option.value}>
            {option.label}
          </option>
        ))}
      </select>
    </FormControl>
  );
}

function TextAreaField({
  defaultValue,
  error,
  label,
  name,
}: {
  defaultValue: string;
  error?: string;
  label: string;
  name: string;
}) {
  const id = name.replace(/\[|\]/g, "_").replace(/_+$/g, "");

  return (
    <FormControl className="w-full" error={error} htmlFor={id} label={label}>
      <textarea
        aria-describedby={error ? `${id}_error` : undefined}
        aria-invalid={!!error}
        defaultValue={defaultValue}
        id={id}
        name={name}
        rows={5}
      />
    </FormControl>
  );
}

function TransitionNotificationsSection({
  destinations,
  rows,
  onAdd,
  onChange,
  onRemove,
}: {
  destinations: WarehouseOption[];
  rows: TransitionRow[];
  onAdd: () => void;
  onChange: (clientKey: string, changes: Partial<TransitionRow>) => void;
  onRemove: (clientKey: string) => void;
}) {
  return (
    <section>
      <FormSectionHeading
        subtitle="We will send a notification when a product is moved from this warehouse to one of the
        warehouses listed below"
        title="Transition notifications"
      />

      <TransitionTable
        destinations={destinations}
        onAdd={onAdd}
        onChange={onChange}
        onRemove={onRemove}
        rows={rows}
      />
    </section>
  );
}

function TransitionTable({
  destinations,
  rows,
  onAdd,
  onChange,
  onRemove,
}: {
  destinations: WarehouseOption[];
  rows: TransitionRow[];
  onAdd: () => void;
  onChange: (clientKey: string, changes: Partial<TransitionRow>) => void;
  onRemove: (clientKey: string) => void;
}) {
  return (
    <div className="section_border_base">
      <table>
        <thead>
          <tr>
            <th>Destination Warehouse</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {rows.map((row, index) => (
            <TransitionDestinationRow
              destinations={destinations}
              index={index}
              key={row.clientKey}
              onChange={onChange}
              onRemove={onRemove}
              row={row}
            />
          ))}
          <AddTransitionRow onAdd={onAdd} />
        </tbody>
      </table>
    </div>
  );
}

function TransitionDestinationRow({
  destinations,
  index,
  onChange,
  onRemove,
  row,
}: {
  destinations: WarehouseOption[];
  index: number;
  onChange: (clientKey: string, changes: Partial<TransitionRow>) => void;
  onRemove: (clientKey: string) => void;
  row: TransitionRow;
}) {
  const selectDestination = useCallback(
    (event: ChangeEvent<HTMLSelectElement>) => {
      onChange(row.clientKey, {
        toWarehouseId: event.target.value ? Number(event.target.value) : null,
      });
    },
    [onChange, row.clientKey],
  );

  const handleRemove = useCallback(() => {
    onRemove(row.clientKey);
  }, [onRemove, row.clientKey]);

  return (
    <tr>
      <td className="w-full">
        <select
          aria-label={`Destination Warehouse ${index + 1}`}
          name="warehouse[to_warehouse_ids][]"
          onChange={selectDestination}
          value={row.toWarehouseId ?? ""}
        >
          <option value="">Select a destination</option>
          {destinations.map((destination) => (
            <option key={destination.id} value={destination.id}>
              {destination.name}
            </option>
          ))}
        </select>
      </td>
      <td>
        <Button onClick={handleRemove} type="button" variant="danger">
          Remove
        </Button>
      </td>
    </tr>
  );
}

function AddTransitionRow({ onAdd }: { onAdd: () => void }) {
  return (
    <tr className="cursor-default hover:bg-transparent">
      <td>
        <Button className="btn_rounded" onClick={onAdd} type="button">
          Add Transition
        </Button>
      </td>
      <td />
    </tr>
  );
}

function useWarehouseFormState(warehouse: WarehouseFormRecord) {
  const [media, setMedia] = useState(() => warehouse.media);
  const transitionRows = useDynamicSection(
    transitionRowsFromWarehouse(warehouse),
    newTransitionRow,
    {
      keyForInitial: (row) => row.clientKey,
    },
  );

  return { media, setMedia, transitionRows };
}

function transitionRowsFromWarehouse(warehouse: WarehouseFormRecord): TransitionRow[] {
  return warehouse.transition_ids.map((toWarehouseId, index) => ({
    clientKey: `transition-${toWarehouseId}-${index}`,
    toWarehouseId,
  }));
}

function newTransitionRow(): TransitionRow {
  return {
    clientKey: crypto.randomUUID(),
    toWarehouseId: null,
  };
}

function positionOptions(positions: number[]) {
  return positions.map((position) => ({
    label: String(position),
    value: position,
  }));
}

function defaultWarehouseOptions() {
  return [
    { label: "No", value: "0" },
    { label: "Yes", value: "1" },
  ];
}
