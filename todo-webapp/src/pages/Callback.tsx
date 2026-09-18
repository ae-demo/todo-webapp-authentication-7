import { useEffect, useRef, type JSX } from "react";
import { useNavigate } from "react-router-dom";
import { handleCallback } from "../authz/session";

/** OIDC redirect target. Processes the code exchange once, then lands on "/". */
export function CallbackPage(): JSX.Element {
  const navigate = useNavigate();
  const ran = useRef(false);

  useEffect(() => {
    if (ran.current) return;
    ran.current = true;
    void handleCallback()
      .catch(() => {})
      .finally(() => navigate("/", { replace: true }));
  }, [navigate]);

  return (
    <main>
      <p>Signing you in…</p>
    </main>
  );
}
