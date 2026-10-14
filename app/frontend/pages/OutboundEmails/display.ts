export type EmailState = "pending" | "accepted" | "simulated";

export const stateDetails: Record<EmailState, { label: string; description: string }> = {
  pending: { label: "Waiting to send", description: "Not sent yet. It is waiting its turn." },
  accepted: {
    label: "Handed to email service",
    description: "Our email service took the message. We do not know if it reached the inbox.",
  },
  simulated: {
    label: "Test mode — not sent",
    description: "This was a test. No email was sent.",
  },
};

export function formatTimestamp(value: string | null) {
  return value ? `${value.slice(0, 16).replace("T", " ")} UTC` : "—";
}
