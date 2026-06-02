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
import FormSectionHeading from "./FormSectionHeading";
import routes from "@/lib/routes";

const DEFAULT_UPLOAD_URL = routes.mediaUploads.create.path();

export type ImageUploaderMedia = {
  id: number | null;
  alt: string;
  position: number;
  preview_url: string;
  thumb_url: string;
  _destroy: boolean;
  image_blob_id?: string;
};

type UploadingFile = {
  name: string;
  progress: number;
};

type UploadedImage = {
  previewUrl: string;
  signedId: string;
};

type ImageUploaderProps = {
  fieldNamePrefix?: string;
  imageFieldName?: string;
  media: ImageUploaderMedia[];
  onMediaChange: (media: ImageUploaderMedia[]) => void;
  subtitle?: string;
  title?: string;
  uploadUrl?: string;
};

type DragEndEvent = Parameters<
  NonNullable<ComponentProps<typeof DragDropProvider>["onDragEnd"]>
>[0];

export default function ImageUploader({
  fieldNamePrefix = "media",
  imageFieldName = "image_blob_id",
  media,
  onMediaChange,
  subtitle = "Drag images to reorder",
  title = "Images",
  uploadUrl = DEFAULT_UPLOAD_URL,
}: ImageUploaderProps) {
  const uploader = useImageUploader(media, onMediaChange, uploadUrl);

  return (
    <fieldset>
      <FormSectionHeading subtitle={subtitle} title={title} />
      <ImageHiddenFields
        fieldNamePrefix={fieldNamePrefix}
        imageFieldName={imageFieldName}
        media={media}
      />
      <SortableImageGrid
        media={uploader.activeMedia}
        onDragEnd={uploader.reorderImages}
        onUpdate={uploader.updateImage}
      />
      <UploadProgressList uploading={uploader.uploading} />
      <ImageFileInput fileInputRef={uploader.fileInputRef} onFileChange={uploader.uploadImages} />
    </fieldset>
  );
}

function ImageHiddenFields({
  fieldNamePrefix,
  imageFieldName,
  media,
}: {
  fieldNamePrefix: string;
  imageFieldName: string;
  media: ImageUploaderMedia[];
}) {
  return (
    <div aria-hidden="true" className="hidden">
      {media.map((image, index) => (
        <div key={imageKey(image)}>
          {image.id != null && (
            <input name={`${fieldNamePrefix}[${index}][id]`} type="hidden" value={image.id} />
          )}
          <input name={`${fieldNamePrefix}[${index}][alt]`} type="hidden" value={image.alt} />
          <input
            name={`${fieldNamePrefix}[${index}][position]`}
            type="hidden"
            value={image.position}
          />
          <input
            name={`${fieldNamePrefix}[${index}][${imageFieldName}]`}
            type="hidden"
            value={image.image_blob_id ?? ""}
          />
          <input
            name={`${fieldNamePrefix}[${index}][_destroy]`}
            type="hidden"
            value={image._destroy ? "1" : "0"}
          />
        </div>
      ))}
    </div>
  );
}

function SortableImageGrid({
  media,
  onDragEnd,
  onUpdate,
}: {
  media: ImageUploaderMedia[];
  onDragEnd: (event: DragEndEvent) => void;
  onUpdate: (cardId: number | string, changes: Partial<ImageUploaderMedia>) => void;
}) {
  if (media.length === 0) return null;

  return (
    <DragDropProvider onDragEnd={onDragEnd}>
      <div className="grid grid-cols-2 gap-x-4 gap-y-6 mb-8 lg:grid-cols-6">
        {media.map((image, index) => (
          <SortableImageCard
            cardId={imageKey(image)}
            image={image}
            index={index}
            key={imageKey(image)}
            onUpdate={onUpdate}
          />
        ))}
      </div>
    </DragDropProvider>
  );
}

function SortableImageCard({
  cardId,
  image,
  index,
  onUpdate,
}: {
  cardId: number | string;
  image: ImageUploaderMedia;
  index: number;
  onUpdate: (cardId: number | string, changes: Partial<ImageUploaderMedia>) => void;
}) {
  const { ref, handleRef, isDragging } = useSortable({ id: cardId, index });
  const cardStyle = useMemo(
    () => ({ opacity: isDragging ? 0.4 : 1, transition: "opacity 200ms" }),
    [isDragging],
  );
  const removeImage = useCallback(() => onUpdate(cardId, { _destroy: true }), [cardId, onUpdate]);

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
          onClick={removeImage}
          type="button"
        >
          <XMarkIcon className="w-8 h-8" />
        </button>
        {isPendingImage(image) && (
          <span
            className="absolute bottom-1 left-1 z-10 rounded bg-blue-600/90 px-2 py-1 text-xs font-medium text-white"
            data-testid="image-pending-badge"
          >
            Pending
          </span>
        )}
        <div className="overflow-hidden rounded bg-gray-400 dark:bg-gray-600 border border-gray-200 dark:border-gray-700 peer-hover/drag:shadow-xl peer-hover/drag:shadow-gray-300 dark:peer-hover/drag:shadow-gray-800 transition-shadow">
          <img alt={image.alt} src={image.preview_url} />
        </div>
      </div>
    </div>
  );
}

function UploadProgressList({ uploading }: { uploading: UploadingFile[] }) {
  if (uploading.length === 0) return null;

  return (
    <div className="mb-4 space-y-2">
      {uploading.map((file) => (
        <div key={file.name}>
          <p className="text-xs text-gray-500">
            {file.name} — {file.progress}%
          </p>
          <div className="w-full bg-gray-200 rounded-full h-1.5">
            <UploadProgress progress={file.progress} />
          </div>
        </div>
      ))}
    </div>
  );
}

function ImageFileInput({
  fileInputRef,
  onFileChange,
}: {
  fileInputRef: React.RefObject<HTMLInputElement | null>;
  onFileChange: (event: ChangeEvent<HTMLInputElement>) => void;
}) {
  return (
    <div>
      <input
        accept="image/*"
        className="file_input"
        data-testid="new-images-input"
        multiple
        onChange={onFileChange}
        ref={fileInputRef}
        type="file"
      />
      <p className="text-xs text-gray-500 mt-2">Select multiple images to upload at once</p>
    </div>
  );
}

function useImageUploader(
  media: ImageUploaderMedia[],
  onMediaChange: (media: ImageUploaderMedia[]) => void,
  uploadUrl: string,
) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState<UploadingFile[]>([]);
  const activeMedia = useMemo(() => media.filter((image) => !image._destroy), [media]);

  const updateImage = useCallback(
    (cardId: number | string, changes: Partial<ImageUploaderMedia>) => {
      onMediaChange(
        media.map((image) => (imageKey(image) === cardId ? { ...image, ...changes } : image)),
      );
    },
    [media, onMediaChange],
  );

  const uploadImages = useCallback(
    (event: ChangeEvent<HTMLInputElement>) => {
      const fileInput = event.currentTarget;
      const files = fileInput.files;
      if (!files || files.length === 0) return;

      const imagesToUpload = Array.from(files);
      setUploading(imagesToUpload.map((file) => ({ name: file.name, progress: 0 })));

      const uploadPromises = imagesToUpload.map((file, index) =>
        uploadFile(uploadUrl, file, (progress) =>
          setUploading((current) => updateUploadProgress(current, index, progress)),
        ).then((signedId) => ({ previewUrl: URL.createObjectURL(file), signedId })),
      );

      void Promise.allSettled(uploadPromises).then((results) => {
        const uploadedImages = successfulUploads(results);
        const newImages = uploadedImages.map((image, index) =>
          newUploadedImage(image, activeMedia.length + index),
        );

        onMediaChange([...media, ...newImages]);
        setUploading([]);
        fileInput.value = "";
      });
    },
    [activeMedia.length, media, onMediaChange, uploadUrl],
  );

  const reorderImages = useCallback(
    (event: DragEndEvent) => {
      if (event.canceled) return;

      const source = sortableDragSource(event);
      if (!source) return;

      const { initialIndex, index } = source;
      if (initialIndex === index) return;

      const reorderedMedia = moveImage(activeMedia, initialIndex, index);

      onMediaChange([...repositionImages(reorderedMedia), ...deletedMedia(media)]);
    },
    [activeMedia, media, onMediaChange],
  );

  return {
    activeMedia,
    fileInputRef,
    reorderImages,
    updateImage,
    uploadImages,
    uploading,
  };
}

function UploadProgress({ progress }: { progress: number }) {
  const progressStyle = useMemo(() => ({ width: `${progress}%` }), [progress]);

  return <div className="bg-blue-500 h-1.5 rounded-full transition-all" style={progressStyle} />;
}

function uploadFile(
  uploadUrl: string,
  file: File,
  onProgress: (pct: number) => void,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const xhr = new XMLHttpRequest();
    const formData = new FormData();
    formData.append("file", file);

    xhr.upload.addEventListener("progress", (event) => {
      if (event.lengthComputable) onProgress(Math.round((event.loaded / event.total) * 100));
    });

    xhr.addEventListener("load", () => {
      if (!uploadSucceeded(xhr)) {
        reject(new Error(`Upload failed: ${xhr.status}`));
        return;
      }

      const payload: { signed_id?: string } = JSON.parse(xhr.responseText);
      if (typeof payload.signed_id === "string") {
        resolve(payload.signed_id);
        return;
      }

      reject(new Error("Upload failed: missing signed_id"));
    });

    xhr.addEventListener("error", () => reject(new Error("Upload failed")));

    xhr.open("POST", uploadUrl);
    xhr.setRequestHeader("X-CSRF-Token", csrfToken());
    xhr.send(formData);
  });
}

function csrfToken(): string {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta instanceof HTMLMetaElement ? meta.content : "";
}

function uploadSucceeded(xhr: XMLHttpRequest) {
  return xhr.status >= 200 && xhr.status < 300;
}

function imageKey(image: ImageUploaderMedia) {
  return image.id ?? image.preview_url;
}

function isPendingImage(image: ImageUploaderMedia) {
  return image.id == null && !!image.image_blob_id;
}

function updateUploadProgress(uploading: UploadingFile[], index: number, progress: number) {
  return uploading.map((file, currentIndex) =>
    currentIndex === index ? { ...file, progress } : file,
  );
}

function successfulUploads(results: PromiseSettledResult<UploadedImage>[]) {
  return results
    .filter(
      (result): result is PromiseFulfilledResult<UploadedImage> => result.status === "fulfilled",
    )
    .map(({ value }) => value);
}

function newUploadedImage(
  { previewUrl, signedId }: UploadedImage,
  position: number,
): ImageUploaderMedia {
  return {
    alt: "",
    id: null,
    image_blob_id: signedId,
    position,
    preview_url: previewUrl,
    thumb_url: previewUrl,
    _destroy: false,
  };
}

function sortableDragSource(event: DragEndEvent) {
  const { source } = event.operation;

  return isSortable(source) ? source : null;
}

function moveImage(images: ImageUploaderMedia[], fromIndex: number, toIndex: number) {
  const reordered = [...images];
  const [image] = reordered.splice(fromIndex, 1);
  reordered.splice(toIndex, 0, image);

  return reordered;
}

function repositionImages(images: ImageUploaderMedia[]) {
  return images.map((image, position) => ({ ...image, position }));
}

function deletedMedia(media: ImageUploaderMedia[]) {
  return media.filter((image) => image._destroy);
}
