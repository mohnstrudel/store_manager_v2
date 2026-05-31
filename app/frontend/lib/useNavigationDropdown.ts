import { useCallback, useEffect, useRef, useState } from "react";
import { useCloseOnEscape } from "@/lib/useCloseOnEscape";

export function useNavigationDropdown() {
  const [isOpen, setIsOpen] = useState(false);
  const dropdownRef = useRef<HTMLLIElement>(null);

  const closeDropdown = useCallback(() => {
    setIsOpen(false);
  }, []);

  const toggleDropdown = useCallback(() => {
    setIsOpen((current) => !current);
  }, []);

  useCloseOnEscape(isOpen, closeDropdown);

  useEffect(() => {
    if (!isOpen) return undefined;

    function handlePointerDown(event: PointerEvent) {
      const target = event.target;
      if (!(target instanceof Node)) return;
      if (dropdownRef.current?.contains(target)) return;
      closeDropdown();
    }

    document.addEventListener("pointerdown", handlePointerDown);

    return () => {
      document.removeEventListener("pointerdown", handlePointerDown);
    };
  }, [closeDropdown, isOpen]);

  return {
    closeDropdown,
    dropdownRef,
    isOpen,
    toggleDropdown,
  };
}
