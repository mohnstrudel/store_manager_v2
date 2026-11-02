import { PhotoIcon } from "@heroicons/react/24/outline";

type ImageUnavailableProps = {
  alt: string;
  className: string;
};

export default function ImageUnavailable({ alt, className }: ImageUnavailableProps) {
  return (
    <div
      aria-label={`Image unavailable for ${alt}`}
      className={`flex flex-col items-center justify-center gap-1 rounded-md border border-gray-200/80 bg-gray-50/80 px-2 text-center text-xs font-medium leading-tight text-gray-400/80 dark:border-gray-800 dark:bg-gray-800/50 dark:text-gray-500 ${className}`}
      // oxlint-disable-next-line jsx-a11y/prefer-tag-over-role -- failure placeholder
      role="img"
    >
      <PhotoIcon className="h-5 w-5 shrink-0" />
      <span>Image unavailable</span>
    </div>
  );
}
