import { DragDropProvider } from "@dnd-kit/react";
import { isSortable, useSortable } from "@dnd-kit/react/sortable";
import { ArrowsRightLeftIcon, XMarkIcon } from "@heroicons/react/24/outline";
import {
  useCallback,
  useMemo,
  useRef,
  useState,
  type ChangeEvent,
  type ComponentProps,
  type Ref,
} from "react";
import FormSectionHeading from "@/components/FormSectionHeading";
import { type MediaFormData } from "../types";

const UPLOAD_URL = "/media/uploads";

function csrfToken(): string {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta instanceof HTMLMetaElement ? meta.content : "";
}

function uploadFile(file: File, onProgress: (pct: number) => void): Promise<string> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();
    formData.append("file", file);

    xhr.upload.addEventListener("progress", (e) => {
      if (e.lengthComputable) onProgress(Math.round((e.loaded / e.total) * 100));
    });

    xhr.addEventListener("load", () => {
      if (xhr.status >= 200 && xhr.status < 300) {
        const payload: { signed_id?: string } = JSON.parse(xhr.responseText);
        if (typeof payload.signed_id === "string") {
          resolve(payload.signed_id);
          return;
        }

        reject(new Error("Upload failed: missing signed_id"));
      } else {
        reject(new Error(`Upload failed: ${xhr.status}`));
      }
    });

    xhr.addEventListener("error", () => reject(new Error("Upload failed")));

    xhr.open("POST", UPLOAD_URL);
    xhr.setRequestHeader("X-CSRF-Token", csrfToken());
    xhr.send(formData);
  });
}

type UploadingFile = {
  name: string;
  progress: number;
};

type ImageCardProps = {
  cardId: number | string;
  index: number;
  item: MediaFormData;
  onUpdate: (cardId: number | string, changes: Partial<MediaFormData>) => void;
};

function ImageCard({ cardId, index, item, onUpdate }: ImageCardProps) {
  const { ref, handleRef, isDragging } = useSortable({ id: cardId, index });
  const cardStyle = useMemo(
    () => ({ opacity: isDragging ? 0.4 : 1, transition: "opacity 200ms" }),
    [isDragging],
  );
  const handleRemove = useCallback(() => onUpdate(cardId, { _destroy: true }), [cardId, onUpdate]);

  return (
    <div ref={ref} style={cardStyle}>
      <div className="relative">
        <button
          ref={handleRef as Ref<HTMLButtonElement>}
          aria-label="Drag to reorder"
          className="backdrop-blur-xs peer/drag absolute top-1 left-1 z-10 p-0.5 rounded hover:bg-blue-600/80 bg-black/30 text-white cursor-grab active:cursor-grabbing touch-none"
          type="button"
        >
          <ArrowsRightLeftIcon className="w-8 h-8" />
        </button>
        <button
          aria-label="Remove image"
          className="backdrop-blur-xs absolute top-1 right-1 z-10 p-0.5 rounded bg-black/30 text-white hover:bg-red-600/80 transition-colors"
          data-testid="image-remove-btn"
          onClick={handleRemove}
          type="button"
        >
          <XMarkIcon className="w-8 h-8" />
        </button>
        <div className="overflow-hidden rounded bg-gray-400 dark:bg-gray-600 border border-gray-200 dark:border-gray-700 peer-hover/drag:shadow-xl peer-hover/drag:shadow-gray-300 dark:peer-hover/drag:shadow-gray-800 transition-shadow">
          <img alt={item.alt} src={item.preview_url} />
        </div>
      </div>
    </div>
  );
}

type ImageUploaderProps = {
  fieldNamePrefix?: string;
  imageFieldName?: string;
  media: MediaFormData[];
  onMediaChange: (media: MediaFormData[]) => void;
};

type DragEndEvent = Parameters<
  NonNullable<ComponentProps<typeof DragDropProvider>["onDragEnd"]>
>[0];

export default function ImageUploader({
  fieldNamePrefix = "media",
  imageFieldName = "image_blob_id",
  media,
  onMediaChange,
}: ImageUploaderProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState<UploadingFile[]>([]);

  const activeMedia = media.filter((m) => !m._destroy);

  const updateMedia = useCallback(
    (cardId: number | string, changes: Partial<MediaFormData>) => {
      onMediaChange(
        media.map((m) => ((m.id ?? m.preview_url) === cardId ? { ...m, ...changes } : m)),
      );
    },
    [media, onMediaChange],
  );

  const handleNewFiles = useCallback(
    (files: FileList | null) => {
      if (!files || files.length === 0) return;

      const fileArray = Array.from(files);
      setUploading(fileArray.map((f) => ({ name: f.name, progress: 0 })));

      const uploadPromises = fileArray.map((file, index) =>
        uploadFile(file, (progress) =>
          setUploading((prev) => prev.map((u, i) => (i === index ? { ...u, progress } : u))),
        ).then((signedId) => ({ signedId, previewUrl: URL.createObjectURL(file) })),
      );

      void Promise.allSettled(uploadPromises).then((results) => {
        const newItems: MediaFormData[] = results
          .filter(
            (r): r is PromiseFulfilledResult<{ signedId: string; previewUrl: string }> =>
              r.status === "fulfilled",
          )
          .map(({ value: { signedId, previewUrl } }, index) => ({
            id: null,
            alt: "",
            position: activeMedia.length + index,
            preview_url: previewUrl,
            thumb_url: previewUrl,
            _destroy: false,
            image_blob_id: signedId,
          }));

        onMediaChange([...media, ...newItems]);
        setUploading([]);
        if (fileInputRef.current) fileInputRef.current.value = "";
      });
    },
    [activeMedia.length, media, onMediaChange],
  );

  const handleFileChange = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      handleNewFiles(event.currentTarget.files);
    },
    [handleNewFiles],
  );

  const handleDragEnd = useCallback(
    (event: DragEndEvent) => {
      if (event.canceled) return;
      const { source } = event.operation;
      if (!isSortable(source)) return;
      const { initialIndex, index } = source;
      if (initialIndex === index) return;

      const reordered = [...activeMedia];
      const [removed] = reordered.splice(initialIndex, 1);
      reordered.splice(index, 0, removed);

      onMediaChange([
        ...reordered.map((m, i) => Object.assign({}, m, { position: i })),
        ...media.filter((m) => m._destroy),
      ]);
    },
    [activeMedia, media, onMediaChange],
  );

  return (
    <fieldset>
      <FormSectionHeading subtitle="Drag images to reorder" title="Images" />

      <div aria-hidden="true" className="hidden">
        {media.map((item, index) => (
          <div key={item.id ?? item.preview_url}>
            {item.id != null && (
              <input name={`${fieldNamePrefix}[${index}][id]`} type="hidden" value={item.id} />
            )}
            <input name={`${fieldNamePrefix}[${index}][alt]`} type="hidden" value={item.alt} />
            <input
              name={`${fieldNamePrefix}[${index}][position]`}
              type="hidden"
              value={item.position}
            />
            <input
              name={`${fieldNamePrefix}[${index}][${imageFieldName}]`}
              type="hidden"
              value={item.image_blob_id ?? ""}
            />
            <input
              name={`${fieldNamePrefix}[${index}][_destroy]`}
              type="hidden"
              value={item._destroy ? "1" : "0"}
            />
          </div>
        ))}
      </div>

      {activeMedia.length > 0 && (
        <DragDropProvider onDragEnd={handleDragEnd}>
          <div className="grid grid-cols-2 gap-x-4 gap-y-6 mb-8 lg:grid-cols-6">
            {activeMedia.map((m, index) => (
              <ImageCard
                cardId={m.id ?? m.preview_url}
                index={index}
                item={m}
                key={m.id ?? m.preview_url}
                onUpdate={updateMedia}
              />
            ))}
          </div>
        </DragDropProvider>
      )}

      {uploading.length > 0 && (
        <div className="mb-4 space-y-2">
          {uploading.map((u) => (
            <div key={u.name}>
              <p className="text-xs text-gray-500">
                {u.name} — {u.progress}%
              </p>
              <div className="w-full bg-gray-200 rounded-full h-1.5">
                <UploadProgress progress={u.progress} />
              </div>
            </div>
          ))}
        </div>
      )}

      <div>
        <input
          accept="image/*"
          className="file_input"
          data-testid="new-images-input"
          multiple
          onChange={handleFileChange}
          ref={fileInputRef}
          type="file"
        />
        <p className="text-xs text-gray-500 mt-2">Select multiple images to upload at once</p>
      </div>
    </fieldset>
  );
}

type UploadProgressProps = {
  progress: number;
};

function UploadProgress({ progress }: UploadProgressProps) {
  const progressStyle = useMemo(() => ({ width: `${progress}%` }), [progress]);

  return <div className="bg-blue-500 h-1.5 rounded-full transition-all" style={progressStyle} />;
}
