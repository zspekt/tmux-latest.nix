{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  bison,
  libevent,
  ncurses,
  pkg-config,
  runCommand,
  withSystemd ? lib.meta.availableOn stdenv.hostPlatform systemd,
  systemd,
  withUtf8proc ? true,
  utf8proc, # gets Unicode updates faster than glibc
  withUtempter ? stdenv.isLinux && !stdenv.hostPlatform.isMusl,
  libutempter,
  withSixel ? true,
}:

let

  bashCompletion = fetchFromGitHub {
    owner = "imomaliev";
    repo = "tmux-bash-completion";
    rev = "8da7f797245970659b259b85e5409f197b8afddd";
    sha256 = "0sq2g3w0h3mkfa6qwqdw93chb5f1hgkz5vdl8yw8mxwdqwhsdprr";
  };

in

stdenv.mkDerivation (finalAttrs: {
  pname = "tmux";
  version = "latest";

  outputs = [
    "out"
    "man"
  ];

  src = fetchFromGitHub {
    owner = "tmux";
    repo = "tmux";
    rev = "64f1076d97ac865ab5e3e153a32c26533917ecd6";
    hash = "sha256-B31akrNgEi4F90b65nlJ6MH+I/W4EtpgsfnXT05noSw=";
  };

  # patches = [(fetchpatch {
  #   url = "https://github.com/tmux/tmux/commit/2d1afa0e62a24aa7c53ce4fb6f1e35e29d01a904.diff";
  #   hash = "sha256-mDt5wy570qrUc0clGa3GhZFTKgL0sfnQcWJEJBKAbKs=";
  # })];
  #
  nativeBuildInputs = [
    pkg-config
    autoreconfHook
    bison
  ];

  buildInputs =
    [
      ncurses
      libevent
    ]
    ++ lib.optionals withSystemd [ systemd ]
    ++ lib.optionals withUtf8proc [ utf8proc ]
    ++ lib.optionals withUtempter [ libutempter ];

  configureFlags =
    [
      "--sysconfdir=/etc"
      "--localstatedir=/var"
    ]
    ++ lib.optionals withSystemd [ "--enable-systemd" ]
    ++ lib.optionals withSixel [ "--enable-sixel" ]
    ++ lib.optionals withUtempter [ "--enable-utempter" ]
    ++ lib.optionals withUtf8proc [ "--enable-utf8proc" ];

  enableParallelBuilding = true;

  postInstall =
    ''
      mkdir -p $out/share/bash-completion/completions
      cp -v ${bashCompletion}/completions/tmux $out/share/bash-completion/completions/tmux
    ''
    + lib.optionalString stdenv.isDarwin ''
      mkdir $out/nix-support
      echo "${finalAttrs.passthru.terminfo}" >> $out/nix-support/propagated-user-env-packages
    '';

  passthru = {
    terminfo = runCommand "tmux-terminfo" { nativeBuildInputs = [ ncurses ]; } (
      if stdenv.isDarwin then
        ''
          mkdir -p $out/share/terminfo/74
          cp -v ${ncurses}/share/terminfo/74/tmux $out/share/terminfo/74
          # macOS ships an old version (5.7) of ncurses which does not include tmux-256color so we need to provide it from our ncurses.
          # However, due to a bug in ncurses 5.7, we need to first patch the terminfo before we can use it with macOS.
          # https://gpanders.com/blog/the-definitive-guide-to-using-tmux-256color-on-macos/
          tic -o $out/share/terminfo -x <(TERMINFO_DIRS=${ncurses}/share/terminfo infocmp -x tmux-256color | sed 's|pairs#0x10000|pairs#32767|')
        ''
      else
        ''
          mkdir -p $out/share/terminfo/t
          ln -sv ${ncurses}/share/terminfo/t/{tmux,tmux-256color,tmux-direct} $out/share/terminfo/t
        ''
    );
  };

  meta = {
    homepage = "https://tmux.github.io/";
    description = "Terminal multiplexer";
    license = lib.licenses.bsd3;
    platforms = lib.platforms.unix;
    mainProgram = "tmux";
  };
})
