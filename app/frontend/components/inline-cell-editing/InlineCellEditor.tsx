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

/**
 * The <td> container shared by both the display and edit states. Keeping one
 * stable element prevents style flickering when toggling between states.
 *
 * Pass `onOpen` only when in the closed state — it wires the whole-cell click
 * to open the editor and stops the click from triggering row navigation.
 */
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

/**
 * Closed state content: displays the current value and exposes keyboard
 * activation to open the editor. Render this inside InlineCellTd.
 */
export function InlineCellTrigger({
  ariaLabel,
  children,
  onOpen,
}: {
  ariaLabel: string;
  children: ReactNode;
  onOpen: () => void;
}) {
  const openFromKeyboard = useCallback(
    (event: KeyboardEvent<HTMLDivElement>) => {
      event.stopPropagation();
      if (event.key === "Enter" || event.key === " ") {
        event.preventDefault();
        onOpen();
      }
    },
    [onOpen],
  );

  return (
    <>
      <div
        aria-label={ariaLabel}
        className="inline_cell_display"
        onKeyDown={openFromKeyboard}
        role="button"
        tabIndex={0}
      >
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

/**
 * Open state content: wraps the field(s) in a form with Save and Exit actions,
 * and keeps interactions from bubbling to the table row. Render inside InlineCellTd.
 */
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

/** The open/closed state from `useInlineCellForm` that the editor shell needs. */
type InlineCellControl = {
  isOpen: boolean;
  isSaved: boolean;
  value: string;
  open: () => void;
  close: () => void;
  openSilently: () => void;
};

type InlineCellEditorProps = {
  /** The `useInlineCellForm` result driving open state and persistence. */
  form: InlineCellControl;
  /** The editable control (input/select) shown while open. Wire its id to `fieldId`. */
  children: ReactNode;
  /** Extra classes for the cell, e.g. width/alignment. */
  tdClassName?: string;
  /** Accessible name for the closed-state Edit trigger. */
  ariaLabel: string;
  /** Visually-hidden label tied to the field. */
  fieldLabel: string;
  fieldId: string;
  error?: string;
  /** Invoked on submit. Pass `onBulkSave ?? form.save` to support sibling bulk saves. */
  onSave: () => void;
  /** Invoked on cancel/Escape. Defaults to `form.close`. */
  onCancel?: () => void;
  /** Closed-state text, e.g. the formatted current value. Empty shows nothing. */
  displayValue: string;
  displayClassName?: string;
};

/**
 * One editable table cell: shows `displayValue` until opened, then a form wrapping
 * the field (`children`). Owns the cell shell, the open/closed branch, and the
 * `{ open, close, getValue }` imperative handle that sibling editors use to
 * cascade. The field's value/onChange come from the same `useInlineCellForm` the
 * caller passes as `form`.
 */
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
