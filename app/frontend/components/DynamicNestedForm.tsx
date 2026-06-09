import FormSectionHeading from "./FormSectionHeading";

type DynamicNestedFormProps = {
  canAdd?: boolean;
  children: React.ReactNode;
  name: string;
  onAdd: () => void;
  title?: string;
};

export default function DynamicNestedForm({
  canAdd = true,
  children,
  name,
  onAdd,
  title,
}: DynamicNestedFormProps) {
  return (
    <section>
      <FormSectionHeading
        subtitle="Existing items marked for deletion will be removed after you submit the form"
        title={title ?? name}
      />
      <div className="grid grid-cols-1 gap-x-4 gap-y-6 lg:grid-cols-2">{children}</div>
      {canAdd && (
        <button className="btn_rounded mt-4" onClick={onAdd} type="button">
          Add {name}
        </button>
      )}
    </section>
  );
}
