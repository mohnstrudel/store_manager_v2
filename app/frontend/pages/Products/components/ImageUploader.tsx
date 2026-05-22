import { useRef, useState } from "react";
import { DragDropProvider } from "@dnd-kit/react";
import { useSortable, isSortable } from "@dnd-kit/react/sortable";
import { ArrowsRightLeftIcon, XMarkIcon } from "@heroicons/react/24/outline";
import { type MediaFormData } from "../types";

const UPLOAD_URL = "/media/uploads";

function csrfToken(): string {
  return (document.querySelector('meta[name="csrf-token"]') as HTMLMetaElement)?.content ?? "";
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
        const { signed_id } = JSON.parse(xhr.responseText) as { signed_id: string };
        resolve(signed_id);
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
  index: number;
  item: MediaFormData;
  onUpdate: (changes: Partial<MediaFormData>) => void;
};

function ImageCard({ index, item, onUpdate }: ImageCardProps) {
  const cardId = item.id ?? item.preview_url;
  const { ref, handleRef, isDragging } = useSortable({ id: cardId, index });

  return (
    <div ref={ref} style={{ opacity: isDragging ? 0.4 : 1, transition: "opacity 200ms" }}>
      <div className="relative">
        <button
          ref={handleRef as React.Ref<HTMLButtonElement>}
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
          onClick={() => onUpdate({ _destroy: true })}
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
  media: MediaFormData[];
  onMediaChange: (media: MediaFormData[]) => void;
};

export default function ImageUploader({ media, onMediaChange }: ImageUploaderProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState<UploadingFile[]>([]);

  const activeMedia = media.filter((m) => !m._destroy);

  function updateMedia(cardId: number | string, changes: Partial<MediaFormData>) {
    onMediaChange(
      media.map((m) => ((m.id ?? m.preview_url) === cardId ? { ...m, ...changes } : m)),
    );
  }

  function handleNewFiles(files: FileList | null) {
    if (!files || files.length === 0) return;

    const fileArray = Array.from(files);
    setUploading(fileArray.map((f) => ({ name: f.name, progress: 0 })));

    const uploadPromises = fileArray.map((file, index) =>
      uploadFile(file, (progress) =>
        setUploading((prev) => prev.map((u, i) => (i === index ? { ...u, progress } : u))),
      ).then((signedId) => ({ signedId, previewUrl: URL.createObjectURL(file) })),
    );

    Promise.allSettled(uploadPromises).then((results) => {
      const newItems: MediaFormData[] = results
        .filter(
          (r): r is PromiseFulfilledResult<{ signedId: string; previewUrl: string }> =>
            r.status === "fulfilled",
        )
        .map(({ value: { signedId, previewUrl } }, i) => ({
          id: null,
          alt: "",
          position: activeMedia.length + i,
          preview_url: previewUrl,
          thumb_url: previewUrl,
          _destroy: false,
          image_blob_id: signedId,
        }));

      onMediaChange([...media, ...newItems]);
      setUploading([]);
      if (fileInputRef.current) fileInputRef.current.value = "";
    });
  }

  return (
    <fieldset className="mt-6">
      <h2 className="label mb-1">Images</h2>
      <p className="text-gray-600 dark:text-gray-500 mb-4 text">Drag images to reorder</p>

      {/* Hidden inputs — unified for both existing and new images */}
      <div aria-hidden="true" className="hidden">
        {media.map((item, index) => (
          <div key={item.id ?? item.preview_url}>
            {item.id != null && (
              <input name={`media[${index}][id]`} type="hidden" value={item.id} />
            )}
            <input name={`media[${index}][alt]`} type="hidden" value={item.alt} />
            <input name={`media[${index}][position]`} type="hidden" value={item.position} />
            <input
              name={`media[${index}][image_blob_id]`}
              type="hidden"
              value={item.image_blob_id ?? ""}
            />
            <input
              name={`media[${index}][_destroy]`}
              type="hidden"
              value={item._destroy ? "1" : "0"}
            />
          </div>
        ))}
      </div>

      {activeMedia.length > 0 && (
        <DragDropProvider
          onDragEnd={(event) => {
            if (event.canceled) return;
            const { source } = event.operation;
            if (!isSortable(source)) return;
            const { initialIndex, index } = source;
            if (initialIndex === index) return;
            const reordered = [...activeMedia];
            const [removed] = reordered.splice(initialIndex, 1);
            reordered.splice(index, 0, removed);
            onMediaChange([
              ...reordered.map((m, i) => ({ ...m, position: i })),
              ...media.filter((m) => m._destroy),
            ]);
          }}
        >
          <div className="grid grid-cols-2 gap-x-4 gap-y-6 mb-8 lg:grid-cols-6">
            {activeMedia.map((m, index) => (
              <ImageCard
                index={index}
                item={m}
                key={m.id ?? m.preview_url}
                onUpdate={(changes) => updateMedia(m.id ?? m.preview_url, changes)}
              />
            ))}
          </div>
        </DragDropProvider>
      )}

      <h3 className="font-medium mb-2 mt-4">Add images</h3>

      {uploading.length > 0 && (
        <div className="mb-4 space-y-2">
          {uploading.map((u) => (
            <div key={u.name}>
              <p className="text-xs text-gray-500">
                {u.name} — {u.progress}%
              </p>
              <div className="w-full bg-gray-200 rounded-full h-1.5">
                <div
                  className="bg-blue-500 h-1.5 rounded-full transition-all"
                  style={{ width: `${u.progress}%` }}
                />
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="mb-4">
        <input
          accept="image/*"
          className="file-input"
          data-testid="new-images-input"
          multiple
          onChange={(e) => handleNewFiles(e.target.files)}
          ref={fileInputRef}
          type="file"
        />
        <p className="text-xs text-gray-500 mt-2">Select multiple images to upload at once</p>
      </div>
    </fieldset>
  );
}
