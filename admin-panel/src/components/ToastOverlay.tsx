export interface Toast {
  id: number;
  message: string;
  type: 'success' | 'warning';
}

interface ToastOverlayProps {
  toasts: Toast[];
}

export default function ToastOverlay({ toasts }: ToastOverlayProps) {
  return (
    <div className="toast-overlay">
      {toasts.map((toast) => (
        <div key={toast.id} className={`toast ${toast.type}`}>
          <span className="badge-dot"></span>
          <span>{toast.message}</span>
        </div>
      ))}
    </div>
  );
}
