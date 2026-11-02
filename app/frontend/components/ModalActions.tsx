type ModalActionsProps = {
  formId: string;
  onCancel: () => void;
  processing: boolean;
  processingLabel: string;
  submitLabel: string;
};

export default function ModalActions({
  formId,
  onCancel,
  processing,
  processingLabel,
  submitLabel,
}: ModalActionsProps) {
  return (
    <>
      <button className="btn_blue" disabled={processing} form={formId} type="submit">
        {processing ? processingLabel : submitLabel}
      </button>
      <button className="btn_white" disabled={processing} onClick={onCancel} type="button">
        Cancel
      </button>
    </>
  );
}
