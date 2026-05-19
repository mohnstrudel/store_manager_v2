import { usePage } from "@inertiajs/react";
import { PageProps } from "@/types/inertia";

export function useFlash() {
  return usePage<PageProps>().props.flash;
}
