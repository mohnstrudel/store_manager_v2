import { useId, useRef, useState } from "react";

export type SectionRow<T> = T & { clientKey: string };

export function useDynamicSection<T extends object>(initial: T[], factory: () => T) {
  const uid = useId();
  const seq = useRef(0);

  const [items, setItems] = useState<SectionRow<T>[]>(() =>
    initial.map((item, index) => ({ ...item, clientKey: `${uid}-${index}` })),
  );

  function add() {
    const clientKey = `${uid}-new-${seq.current++}`;
    setItems((current) => [...current, { ...factory(), clientKey }]);
  }

  function remove(clientKey: string) {
    setItems((current) => current.filter((i) => i.clientKey !== clientKey));
  }

  return { items, add, remove };
}
