import { router } from "@inertiajs/react";
import { useCallback, type ChangeEvent } from "react";

import ResourceIndexPage from "@/components/ResourceIndexPage";
import { stopRowNavigation } from "@/utils/rowNavigation";

import IndexTable, { type WarehouseRecord } from "./Index/Table";

type IndexProps = {
  warehouses: WarehouseRecord[];
};

export default function Index({ warehouses }: IndexProps) {
  const onPositionChange = useWarehousePositionChange();

  return (
    <ResourceIndexPage newPath="/warehouses/new" title="Warehouses">
      <IndexTable onPositionChange={onPositionChange} warehouses={warehouses} />
    </ResourceIndexPage>
  );
}

function useWarehousePositionChange() {
  return useCallback((event: ChangeEvent<HTMLSelectElement>) => {
    stopRowNavigation(event);
    const positionPath = event.currentTarget.dataset.positionPath;
    if (!positionPath) return;

    router.patch(positionPath, { position: event.currentTarget.value });
  }, []);
}
