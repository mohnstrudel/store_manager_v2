import { ChevronLeftIcon } from "lucide-react";

export default function DetailsChevron() {
  return (
    <span className="text-xs w-5 h-5 p-0 rounded-full btn_lightblue flex items-center justify-center transition-transform origin-center group-open:-rotate-90">
      <ChevronLeftIcon className="h-4 w-4" />
    </span>
  );
}
