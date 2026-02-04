use std::path::PathBuf;

/// Resolve the built-in synthdefs directory.
///
/// Fallback chain:
/// 1. `ILEX_SYNTHDEFS_DIR` env var (runtime override)
/// 2. `CARGO_MANIFEST_DIR/synthdefs` (compile-time, resolves to ilex/)
/// 3. `./synthdefs` relative to CWD (backward compat)
pub fn synthdefs_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("ILEX_SYNTHDEFS_DIR") {
        return PathBuf::from(dir);
    }

    let compile_time = PathBuf::from(concat!(env!("CARGO_MANIFEST_DIR"), "/synthdefs"));
    if compile_time.exists() {
        return compile_time;
    }

    PathBuf::from("synthdefs")
}

/// Path to the main `compile.scd` script.
pub fn compile_scd_path() -> PathBuf {
    synthdefs_dir().join("compile.scd")
}

/// Path to the VST `compile_vst.scd` script.
pub fn compile_vst_scd_path() -> PathBuf {
    synthdefs_dir().join("compile_vst.scd")
}

/// User-local directory for custom synthdefs (`~/.config/ilex/synthdefs/`).
pub fn custom_synthdefs_dir() -> PathBuf {
    if let Some(home) = std::env::var_os("HOME") {
        PathBuf::from(home)
            .join(".config")
            .join("ilex")
            .join("synthdefs")
    } else {
        PathBuf::from("synthdefs")
    }
}
