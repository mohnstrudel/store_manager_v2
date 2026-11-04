import type { SharedProps } from "@/types/serializers";

export interface PageProps extends SharedProps {
  [key: string]: unknown;
}

export type FlashMessage = NonNullable<SharedProps["flash"]["notice"]>;
