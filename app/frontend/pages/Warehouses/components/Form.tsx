import { useRef, useState } from "react";
import { usePage } from "@inertiajs/react";
import Button from "@/components/Button";
import FormControl from "@/components/FormControl";
import FormInput from "@/components/FormInput";
import FormRow from "@/components/FormRow";
import WarehouseFormSectionHeading from "@/components/FormSectionHeading";
import ImageUploader from "@/pages/Products/components/ImageUploader";
import ResourceForm from "@/components/ResourceForm";
import type { WarehouseFormOptions, WarehouseFormRecord, WarehouseOption } from "../types";

type WarehouseFormProps = {
  isNew: boolean;
  options: WarehouseFormOptions;
  submitLabel: string;
  warehouse: WarehouseFormRecord;
};

type PageErrors = Record<string, string | undefined>;
type TransitionRow = {
  clientKey: string;
  toWarehouseId: number | null;
};

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

function TransitionRows({
  destinations,
  rows,
  onAdd,
  onChange,
  onRemove,
}: {
  destinations: WarehouseOption[];
  rows: TransitionRow[];
  onAdd: () => void;
  onChange: (clientKey: string, toWarehouseId: number | null) => void;
  onRemove: (clientKey: string) => void;
}) {
  return (
    <section>
      <WarehouseFormSectionHeading
        subtitle="We will send a notification when a product is moved from this warehouse to one of the
        warehouses listed below"
        title="Transition notifications"
      />

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
              <tr key={row.clientKey}>
                <td className="w-full">
                  <select
                    aria-label={`Destination Warehouse ${index + 1}`}
                    name="warehouse[to_warehouse_ids][]"
                    onChange={(event) =>
                      onChange(
                        row.clientKey,
                        event.target.value ? Number(event.target.value) : null,
                      )
                    }
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
                  <Button onClick={() => onRemove(row.clientKey)} type="button" variant="danger">
                    Remove
                  </Button>
                </td>
              </tr>
            ))}
            <tr className="cursor-default hover:bg-transparent">
              <td>
                <Button className="btn_rounded" onClick={onAdd} type="button">
                  Add Transition
                </Button>
              </td>
              <td />
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  );
}

export default function Form({ isNew, options, submitLabel, warehouse }: WarehouseFormProps) {
  const { errors = {} } = usePage().props as { errors?: PageErrors };
  const rowSequence = useRef(0);
  const [media, setMedia] = useState(() => warehouse.media);
  const [transitionRows, setTransitionRows] = useState<TransitionRow[]>(() =>
    warehouse.transition_ids.map((toWarehouseId, index) => ({
      clientKey: `transition-${toWarehouseId}-${index}`,
      toWarehouseId,
    })),
  );

  const action = isNew ? "/warehouses" : warehouse.path;
  const cancelHref = isNew ? "/warehouses" : warehouse.path;

  function addTransitionRow() {
    const clientKey = `new-transition-${rowSequence.current++}`;
    setTransitionRows((current) => [...current, { clientKey, toWarehouseId: null }]);
  }

  function updateTransitionRow(clientKey: string, toWarehouseId: number | null) {
    setTransitionRows((current) =>
      current.map((row) => (row.clientKey === clientKey ? { ...row, toWarehouseId } : row)),
    );
  }

  function removeTransitionRow(clientKey: string) {
    setTransitionRows((current) => current.filter((row) => row.clientKey !== clientKey));
  }

  return (
    <ResourceForm
      action={action}
      cancelHref={cancelHref}
      method={isNew ? "post" : "patch"}
      submitLabel={submitLabel}
    >
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
          options={options.positions.map((position) => ({
            label: String(position),
            value: position,
          }))}
        />
        <SelectField
          className="lg:w-1/5"
          defaultValue={warehouse.is_default ? "1" : "0"}
          error={errors.is_default}
          label="Default Warehouse"
          name="warehouse[is_default]"
          options={[
            { label: "No", value: "0" },
            { label: "Yes", value: "1" },
          ]}
        />
      </FormRow>

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

      <ImageUploader
        fieldNamePrefix="warehouse[media]"
        imageFieldName="image"
        media={media}
        onMediaChange={setMedia}
      />

      <TransitionRows
        destinations={options.transition_destinations}
        onAdd={addTransitionRow}
        onChange={updateTransitionRow}
        onRemove={removeTransitionRow}
        rows={transitionRows}
      />
    </ResourceForm>
  );
}
