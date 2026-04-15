function App() {
  return (
    <div className="min-h-screen bg-navy-800 flex items-center justify-center">
      <div className="text-center space-y-8">
        {/* Logo / Brand */}
        <div className="space-y-4">
          <div className="flex items-center justify-center gap-3">
            <div className="w-12 h-12 bg-gradient-to-br from-sky-400 to-accent rounded-xl flex items-center justify-center shadow-lg shadow-sky-400/20">
              <svg
                className="w-7 h-7 text-white"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
                strokeWidth={2}
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                />
              </svg>
            </div>
            <h1 className="text-4xl font-extrabold text-white tracking-tight">
              Test<span className="text-sky-400">Pilot</span>
            </h1>
          </div>
          <p className="text-sky-200/70 text-lg font-medium">
            AI QA Assistant
          </p>
        </div>

        {/* Status Card */}
        <div className="bg-navy-700/50 backdrop-blur border border-navy-600/50 rounded-2xl p-8 max-w-md mx-auto shadow-xl">
          <div className="flex items-center justify-center gap-2 mb-4">
            <div className="w-3 h-3 bg-emerald-400 rounded-full animate-pulse" />
            <span className="text-emerald-400 font-semibold text-sm uppercase tracking-wider">
              Online
            </span>
          </div>
          <p className="text-white text-xl font-bold mb-2">
            Phase 0 setup successful
          </p>
          <p className="text-navy-300 text-sm">
            From idea to test cases, in minutes.
          </p>
        </div>

        {/* Tech Stack Badges */}
        <div className="flex flex-wrap items-center justify-center gap-2">
          {["React", "TypeScript", "Tailwind", "FastAPI", "Docker"].map(
            (tech) => (
              <span
                key={tech}
                className="px-3 py-1 text-xs font-medium text-sky-300 bg-navy-700/60 border border-navy-600/40 rounded-full"
              >
                {tech}
              </span>
            )
          )}
        </div>

        {/* Version */}
        <p className="text-navy-500 text-xs">v0.1.0</p>
      </div>
    </div>
  );
}

export default App;
