import { useCallback, useState, type ChangeEvent } from "react";

export function useWarehouseMoveSelection(initialSelectedIds: number[] = []) {
  const [selectedIds, setSelectedIds] = useState(initialSelectedIds);

  const clearSelectedIds = useCallback(() => {
    setSelectedIds([]);
  }, []);

  const toggleSelectedId = useCallback((selectedId: number) => {
    setSelectedIds((current) =>
      current.includes(selectedId)
        ? current.filter((currentSelectedId) => currentSelectedId !== selectedId)
        : [...current, selectedId],
    );
  }, []);

  const toggleSelectedIdFromDataAttribute = useCallback(
    (attributeName: string) => (event: ChangeEvent<HTMLInputElement>) => {
      const selectedId = Number(event.currentTarget.dataset[attributeName]);
      if (Number.isNaN(selectedId)) return;

      toggleSelectedId(selectedId);
    },
    [toggleSelectedId],
  );

  return {
    clearSelectedIds,
    selectedIds,
    toggleSelectedId,
    toggleSelectedIdFromDataAttribute,
  };
}
