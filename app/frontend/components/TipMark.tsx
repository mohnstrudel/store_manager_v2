import {
  autoUpdate,
  flip,
  FloatingPortal,
  offset,
  safePolygon,
  shift,
  useFloating,
  useFocus,
  useHover,
  useInteractions,
  useRole,
} from "@floating-ui/react";
import { useMemo, useState, type CSSProperties, type ReactNode } from "react";

type TipMarkProps = {
  children: ReactNode;
  size?: "regular" | "large";
  starClassName?: string;
  tone?: "orange";
  // Overrides the "*" mark as the hover/focus target. When set, its own
  // text serves as the accessible name instead of "More information" —
  // the caller is supplying real, readable content, not a glyph.
  trigger?: ReactNode;
  triggerClassName?: string;
};

export default function TipMark({
  children,
  size = "regular",
  starClassName = "",
  tone,
  trigger,
  triggerClassName,
}: TipMarkProps) {
  const [isOpen, setIsOpen] = useState(false);
  const { context, floatingStyles, isPositioned, placement, refs } = useFloating({
    open: isOpen,
    onOpenChange: setIsOpen,
    placement: "right",
    strategy: "fixed",
    whileElementsMounted: autoUpdate,
    middleware: [
      offset(8),
      flip({ fallbackPlacements: ["left", "bottom", "top"], padding: 8 }),
      shift({ padding: 8 }),
    ],
  });
  const hover = useHover(context, { handleClose: safePolygon() });
  const focus = useFocus(context);
  const role = useRole(context, { role: "tooltip" });
  const { getFloatingProps, getReferenceProps } = useInteractions([hover, focus, role]);
  const tooltipStyle = useMemo<CSSProperties>(
    () => ({ ...floatingStyles, visibility: isPositioned ? "visible" : "hidden" }),
    [floatingStyles, isPositioned],
  );

  return (
    <>
      <span
        ref={refs.setReference}
        className={triggerClassName ?? `tip_mark__trigger ${starClassName}`.trim()}
        data-size={size}
        data-tone={tone}
        tabIndex={0}
        {...getReferenceProps(
          trigger === undefined ? { "aria-label": "More information" } : undefined,
        )}
      >
        {trigger ?? "*"}
      </span>
      {isOpen && (
        <FloatingPortal>
          <span
            ref={refs.setFloating}
            className="tip_mark__tooltip"
            data-placement={placement}
            style={tooltipStyle}
            {...getFloatingProps()}
          >
            {children}
          </span>
        </FloatingPortal>
      )}
    </>
  );
}
