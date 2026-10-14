import { PhotoIcon } from "@heroicons/react/24/outline";

export default function ProductPreview({
  title,
  imageUrl,
}: {
  title: string | null;
  imageUrl: string | null;
}) {
  return (
    <div className="flex items-center gap-3">
      {imageUrl ? (
        <img
          alt={title || "Product"}
          className="h-14 w-14 shrink-0 rounded-md object-cover"
          loading="lazy"
          src={imageUrl}
        />
      ) : (
        <PhotoIcon className="h-14 w-14 shrink-0 text-gray-400" />
      )}
      <span>{title || "Product name not recorded"}</span>
    </div>
  );
}
