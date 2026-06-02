import { usePage } from "@inertiajs/react";
import { PageProps } from "@/types/inertia";

const EMPTY_FLASH = { notice: null, alert: null };

export function useFlash() {
  return usePage<PageProps>().props.flash ?? EMPTY_FLASH;
}
