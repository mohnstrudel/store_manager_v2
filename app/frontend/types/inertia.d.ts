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
    notice: string | null;
    alert: string | null;
  };
  csrf_token: string;
}
