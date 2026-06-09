export type MediaRecord = {
  id: number;
  alt: string;
  position: number;
  preview_url: string;
  thumb_url: string;
};

export type MediaFormData = {
  id: number | null;
  alt: string;
  position: number;
  preview_url: string;
  thumb_url: string;
  _destroy: boolean;
  image_blob_id?: string;
};
