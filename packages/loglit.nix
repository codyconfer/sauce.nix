{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule (finalAttrs: {
  pname = "loglit";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "madmaxieee";
    repo = "loglit";
    tag = "v${finalAttrs.version}";
    hash = "sha256-MPYvBqiwDee3xDQHn4YOnZ7kSGSIsYvTo7dFdXP2sbk=";
  };

  vendorHash = "sha256-ixhruUAIHuG6vmLQ1TImgcgN/xVFiKMgHucD/8MJP/0=";
  subPackages = [ "." ];

  meta = {
    description = "Syntax-highlight log output in the terminal";
    homepage = "https://github.com/madmaxieee/loglit";
    license = lib.licenses.mit;
    mainProgram = "loglit";
    platforms = lib.platforms.unix;
  };
})
