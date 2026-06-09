export interface PageProps {
  [key: string]: unknown;
  breadcrumb: string | null;
  auth: {
    user: {
      id: number;
      email_address: string;
      role: string;
    } | null;
  };
  flash: {
    notice: FlashMessage | null;
    alert: FlashMessage | null;
  };
  csrf_token: string;
}

export type FlashMessage =
  | string
  | {
      message: string;
      link?: {
        label: string;
        href: string;
        suffix?: string;
      };
    };
