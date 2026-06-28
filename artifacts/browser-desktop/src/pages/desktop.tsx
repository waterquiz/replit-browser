import { useState, useRef, useEffect } from "react";

type ConnectionState = "idle" | "connecting" | "connected" | "error";

export default function DesktopPage() {
  const [state, setState] = useState<ConnectionState>("connected");
  const [fullscreen, setFullscreen] = useState(false);
  const iframeRef = useRef<HTMLIFrameElement>(null);
  const containerRef = useRef<HTMLDivElement>(null);

  const noVncUrl = "/novnc/vnc.html?path=novnc/&autoconnect=true&resize=scale&show_dot=true";

  function connect() {
    setState("connecting");
    setTimeout(() => setState("connected"), 1200);
  }

  function disconnect() {
    setState("idle");
    setFullscreen(false);
  }

  function toggleFullscreen() {
    if (!fullscreen) {
      containerRef.current?.requestFullscreen().catch(() => {});
      setFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setFullscreen(false);
    }
  }

  useEffect(() => {
    function onFullscreenChange() {
      if (!document.fullscreenElement) setFullscreen(false);
    }
    document.addEventListener("fullscreenchange", onFullscreenChange);
    return () => document.removeEventListener("fullscreenchange", onFullscreenChange);
  }, []);

  return (
    <div className="min-h-screen bg-[#0d1117] text-white flex flex-col" ref={containerRef}>
      {/* Top bar */}
      <header className="flex items-center justify-between px-6 py-3 border-b border-[#1c2a3a] bg-[#0d1117]/90 backdrop-blur-sm z-10 shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-7 h-7 rounded bg-[#1a8cff] flex items-center justify-center">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-4 h-4">
              <rect x="2" y="3" width="20" height="14" rx="2" />
              <path d="M8 21h8M12 17v4" />
            </svg>
          </div>
          <span className="font-semibold text-sm tracking-wide">Browser Desktop</span>
          {state === "connected" && (
            <span className="flex items-center gap-1.5 text-xs text-emerald-400 font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              Live
            </span>
          )}
        </div>

        <div className="flex items-center gap-2">
          {state === "connected" && (
            <>
              <button
                onClick={toggleFullscreen}
                className="px-3 py-1.5 text-xs font-medium rounded bg-[#1c2a3a] hover:bg-[#243447] border border-[#2a3d54] transition-colors"
                title={fullscreen ? "Exit fullscreen" : "Fullscreen"}
              >
                {fullscreen ? (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-3.5 h-3.5">
                    <path d="M8 3v3a2 2 0 0 1-2 2H3M21 8h-3a2 2 0 0 1-2-2V3M3 16h3a2 2 0 0 1 2 2v3M16 21v-3a2 2 0 0 1 2-2h3" />
                  </svg>
                ) : (
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="w-3.5 h-3.5">
                    <path d="M3 8V5a2 2 0 0 1 2-2h3M16 3h3a2 2 0 0 1 2 2v3M21 16v3a2 2 0 0 1-2 2h-3M8 21H5a2 2 0 0 1-2-2v-3" />
                  </svg>
                )}
              </button>
              <button
                onClick={disconnect}
                className="px-3 py-1.5 text-xs font-medium rounded bg-red-500/10 hover:bg-red-500/20 border border-red-500/30 text-red-400 transition-colors"
              >
                Disconnect
              </button>
            </>
          )}
        </div>
      </header>

      {/* Main content */}
      <main className="flex-1 flex flex-col">
        {state === "idle" && (
          <div className="flex-1 flex flex-col items-center justify-center px-6 gap-10">
            {/* Hero */}
            <div className="text-center max-w-lg">
              <div className="mb-6 flex justify-center">
                <div className="w-20 h-20 rounded-2xl bg-gradient-to-br from-[#1a8cff] to-[#0055cc] flex items-center justify-center shadow-2xl shadow-blue-500/20">
                  <svg viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="1.5" className="w-10 h-10">
                    <circle cx="12" cy="12" r="10" />
                    <path d="M2 12h20M12 2a15.3 15.3 0 0 1 4 10 15.3 15.3 0 0 1-4 10 15.3 15.3 0 0 1-4-10 15.3 15.3 0 0 1 4-10z" />
                  </svg>
                </div>
              </div>
              <h1 className="text-3xl font-bold tracking-tight mb-3">Browser Desktop</h1>
              <p className="text-[#7a8fa6] text-base leading-relaxed">
                A full Chromium browser running in a virtual display, accessible right in your browser tab. No setup required.
              </p>
            </div>

            {/* Connect button */}
            <button
              onClick={connect}
              className="px-8 py-4 text-base font-semibold rounded-xl bg-[#1a8cff] hover:bg-[#0077ee] transition-all duration-150 shadow-lg shadow-blue-500/20 active:scale-[0.98]"
            >
              Connect to Desktop
            </button>

            {/* Info grid */}
            <div className="grid grid-cols-3 gap-4 max-w-lg w-full">
              {[
                { icon: "🖥", label: "Chromium Browser", desc: "Full-featured, sandboxed" },
                { icon: "🔒", label: "Isolated Session", desc: "Each session is fresh" },
                { icon: "⚡", label: "Low Latency", desc: "VNC over WebSocket" },
              ].map((item) => (
                <div key={item.label} className="rounded-xl bg-[#111923] border border-[#1c2a3a] p-4 text-center">
                  <div className="text-2xl mb-2">{item.icon}</div>
                  <div className="text-xs font-semibold text-white mb-1">{item.label}</div>
                  <div className="text-xs text-[#4a6070]">{item.desc}</div>
                </div>
              ))}
            </div>
          </div>
        )}

        {state === "connecting" && (
          <div className="flex-1 flex flex-col items-center justify-center gap-6">
            <div className="w-12 h-12 rounded-full border-2 border-[#1a8cff] border-t-transparent animate-spin" />
            <div className="text-center">
              <p className="text-base font-medium">Starting desktop session&hellip;</p>
              <p className="text-sm text-[#4a6070] mt-1">Launching virtual display, window manager, and browser</p>
            </div>
          </div>
        )}

        {state === "connected" && (
          <div className="flex-1 relative bg-black">
            <iframe
              ref={iframeRef}
              src={noVncUrl}
              className="absolute inset-0 w-full h-full border-0"
              title="Browser Desktop (noVNC)"
              allow="fullscreen"
            />
          </div>
        )}
      </main>
    </div>
  );
}
