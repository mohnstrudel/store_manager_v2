import {
  useCallback,
  type FormEvent,
  type KeyboardEvent,
  type MouseEvent,
  type ReactNode,
} from "react";

/**
 * Closed state of an editable table cell: shows the current value and opens the
 * editor on click or keyboard activation, without triggering row navigation.
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
  const openFromClick = useCallback(
    (event: MouseEvent<HTMLDivElement>) => {
      event.stopPropagation();
      onOpen();
    },
    [onOpen],
  );

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
    <div
      aria-label={ariaLabel}
      className="inline_cell_display"
      onAuxClick={stopRowEvents}
      onClick={openFromClick}
      onKeyDown={openFromKeyboard}
      role="button"
      tabIndex={0}
    >
      {children}
    </div>
  );
}

/**
 * Open state of an editable table cell: wraps the field(s) in a form with Save
 * and Exit actions, and keeps interactions from bubbling to the table row.
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

  return (
    <form
      className="flex flex-col w-full gap-2"
      onAuxClick={stopRowEvents}
      onClick={stopRowEvents}
      onKeyDown={stopRowEvents}
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
