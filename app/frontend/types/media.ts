import type { Media } from "@/types/serializers";

export type MediaFormData = Omit<Media, "id"> & {
  id: number | null;
  _destroy: boolean;
  image_blob_id?: string;
};
