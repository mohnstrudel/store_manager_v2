import {
  forwardRef,
  useCallback,
  useImperativeHandle,
  type FormEvent,
  type KeyboardEvent,
  type MouseEvent,
  type ReactNode,
} from "react";

import FormError from "@/components/FormError";

export function InlineCellTd({
  children,
  className = "",
  isSaved = false,
  onOpen,
}: {
  children: ReactNode;
  className?: string;
  isSaved?: boolean;
  onOpen?: () => void;
}) {
  const handleClick = useCallback(
    (event: MouseEvent<HTMLTableCellElement>) => {
      event.stopPropagation();
      onOpen?.();
    },
    [onOpen],
  );

  const tdClassName = [
    "inline_editable",
    className,
    isSaved ? "bg-lime-100/80 dark:bg-lime-900/30" : "",
  ]
    .filter(Boolean)
    .join(" ");

  return (
    <td className={tdClassName} onAuxClick={stopRowEvents} onClick={handleClick}>
      {children}
    </td>
  );
}

export function InlineCellTrigger({
  ariaLabel,
  children,
  onOpen,
}: {
  ariaLabel: string;
  children: ReactNode;
  onOpen: () => void;
}) {
  return (
    <>
      <div aria-label={ariaLabel} className="inline_cell_display">
        {children}
      </div>
      <button
        className="btn_rounded btn_xs mt-2"
        onClick={onOpen}
        onKeyDown={stopRowEvents}
        type="button"
      >
        Edit
      </button>
    </>
  );
}

export function InlineCellForm({
  children,
  onCancel,
  onSave,
}: {
  children: ReactNode;
  onCancel: () => void;
  onSave: () => void;
}) {
  const submit = useCallback(
    (event: FormEvent<HTMLFormElement>) => {
      event.preventDefault();
      onSave();
    },
    [onSave],
  );

  const handleKeyDown = useCallback(
    (event: KeyboardEvent<HTMLFormElement>) => {
      event.stopPropagation();
      if (event.key === "Escape") onCancel();
    },
    [onCancel],
  );

  return (
    // oxlint-disable-next-line jsx-a11y/no-noninteractive-element-interactions -- click barrier only
    <form
      className="flex flex-col gap-2 justify-self-center"
      onAuxClick={stopRowEvents}
      onClick={stopRowEvents}
      onKeyDown={handleKeyDown}
      onSubmit={submit}
    >
      {children}
      <div className="flex gap-1 justify-center">
        <button className="btn_rounded btn_xs btn_green" type="submit">
          Save
        </button>
        <button className="btn_red btn_xs btn_rounded" onClick={onCancel} type="button">
          Exit
        </button>
      </div>
    </form>
  );
}

function stopRowEvents(event: { stopPropagation(): void }) {
  event.stopPropagation();
}

export type InlineCellEditorHandle = { open(): void; close(): void; getValue(): string };

type InlineCellControl = {
  isOpen: boolean;
  isSaved: boolean;
  value: string;
  open: () => void;
  close: () => void;
  openSilently: () => void;
};

type InlineCellEditorProps = {
  form: InlineCellControl;
  children: ReactNode;
  tdClassName?: string;
  ariaLabel: string;
  fieldLabel: string;
  fieldId: string;
  error?: string;
  onSave: () => void;
  onCancel?: () => void;
  displayValue: string;
  displayClassName?: string;
};

const InlineCellEditor = forwardRef<InlineCellEditorHandle, InlineCellEditorProps>(
  function InlineCellEditor(
    {
      form,
      children,
      tdClassName,
      ariaLabel,
      fieldLabel,
      fieldId,
      error,
      onSave,
      onCancel,
      displayValue,
      displayClassName,
    },
    ref,
  ) {
    useImperativeHandle(ref, () => ({
      open: form.openSilently,
      close: form.close,
      getValue: () => form.value,
    }));

    return (
      <InlineCellTd
        className={tdClassName}
        isSaved={form.isSaved}
        onOpen={form.isOpen ? undefined : form.open}
      >
        {form.isOpen ? (
          <InlineCellForm onCancel={onCancel ?? form.close} onSave={onSave}>
            <label className="sr-only" htmlFor={fieldId}>
              {fieldLabel}
            </label>
            {children}
            <FormError>{error}</FormError>
          </InlineCellForm>
        ) : (
          <InlineCellTrigger ariaLabel={ariaLabel} onOpen={form.open}>
            {displayValue ? <span className={displayClassName}>{displayValue}</span> : null}
          </InlineCellTrigger>
        )}
      </InlineCellTd>
    );
  },
);

export default InlineCellEditor;
