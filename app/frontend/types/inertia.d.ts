export interface PageProps {
  [key: string]: unknown;
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
