export const NOTIFICATION_KINDS = ["alert", "success", "notice"] as const;

export type NotificationKind = (typeof NOTIFICATION_KINDS)[number];

export type NotificationMessage =
  | string
  | { message: string; link?: { href: string; label: string } };

export type CableNotification = Exclude<NotificationMessage, string> & { kind: NotificationKind };

export function isCableNotification(value: unknown): value is CableNotification {
  return isRecord(value) && isNotificationKind(value.kind) && isNotificationMessage(value);
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null;
}

function isNotificationKind(value: unknown): value is NotificationKind {
  return NOTIFICATION_KINDS.some((kind) => kind === value);
}

export function isNotificationMessage(value: unknown): value is NotificationMessage {
  if (typeof value === "string") return value !== "";

  return isRecord(value) && typeof value.message === "string" && isOptionalLink(value.link);
}

function isOptionalLink(value: unknown) {
  if (value === undefined) return true;

  return isRecord(value) && typeof value.href === "string" && typeof value.label === "string";
}
