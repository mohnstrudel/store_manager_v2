import { useId, useRef, useState } from "react";

export type SectionRow<T> = T & { clientKey: string };

export function useDynamicSection<T extends object>(
  initial: T[],
  factory: () => T,
  options?: { keyForInitial?: (item: T, index: number) => string },
) {
  const uid = useId();
  const seq = useRef(0);

  const [items, setItems] = useState<SectionRow<T>[]>(() =>
    initial.map((item, index) => ({
      ...item,
      clientKey: options?.keyForInitial?.(item, index) ?? `${uid}-${index}`,
    })),
  );

  function add() {
    const clientKey = `${uid}-new-${seq.current++}`;
    setItems((current) => [...current, { ...factory(), clientKey }]);
  }

  function remove(clientKey: string) {
    setItems((current) => current.filter((item) => item.clientKey !== clientKey));
  }

  function removeAt(index: number) {
    setItems((current) => current.filter((_, currentIndex) => currentIndex !== index));
  }

  function update(clientKey: string, changes: Partial<T>) {
    setItems((current) =>
      current.map((item) => (item.clientKey === clientKey ? { ...item, ...changes } : item)),
    );
  }

  return { add, items, remove, removeAt, update };
}
