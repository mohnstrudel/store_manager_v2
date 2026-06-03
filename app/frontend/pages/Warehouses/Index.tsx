import { router } from "@inertiajs/react";
import { useCallback, type ChangeEvent } from "react";
import ResourceIndexPage from "@/components/ResourceIndexPage";
import { stopRowNavigation } from "@/lib/rowNavigation";
import IndexTable, { type WarehouseRecord } from "./Index/Table";

type IndexProps = {
  warehouses: WarehouseRecord[];
};

export default function Index({ warehouses }: IndexProps) {
  const handlePositionChange = useCallback((event: ChangeEvent<HTMLSelectElement>) => {
    stopRowNavigation(event);
    const positionPath = event.currentTarget.dataset.positionPath;
    if (!positionPath) return;

    router.patch(positionPath, { position: event.currentTarget.value });
  }, []);

  return (
    <ResourceIndexPage newPath="/warehouses/new" title="Warehouses">
      <IndexTable onPositionChange={handlePositionChange} warehouses={warehouses} />
    </ResourceIndexPage>
  );
}
